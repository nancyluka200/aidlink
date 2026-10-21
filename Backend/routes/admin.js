const express = require('express');
const router  = express.Router();
const { User }    = require('../models/user');
const { Program } = require('../models/program');
const auth    = require('../middleware/auth');
const isAdmin = require('../middleware/isAdmin');

// ── GET stats ─────────────────────────────────────────────────────────────────
router.get('/stats', [auth, isAdmin], async (req, res) => {
  try {
    const totalUsers          = await User.countDocuments();
    const profilesCompleted   = await User.countDocuments({ profileCompleted: true });
    const totalPrograms       = await Program.countDocuments({ isActive: true });
    const pwdVerified         = await User.countDocuments({ pwdCardVerificationStatus: 'verified' });
    const pwdPending          = await User.countDocuments({ pwdCardVerificationStatus: 'pending' });
    const pwdRejected         = await User.countDocuments({ pwdCardVerificationStatus: 'rejected' });
    const selfApplicants      = await User.countDocuments({ applicantType: 'Self',      profileCompleted: true });
    const caretakerApplicants = await User.countDocuments({ applicantType: 'Caretaker', profileCompleted: true });
    const ncpwdRegistered     = await User.countDocuments({ disabilityStatus: true });

    res.send({
      totalUsers, profilesCompleted, totalPrograms,
      pwdVerified, pwdPending, pwdRejected,
      selfApplicants, caretakerApplicants, ncpwdRegistered,
    });
  } catch (ex) {
    console.error('Error fetching stats:', ex);
    res.status(500).send('Error fetching stats');
  }
});

// ── GET all users ─────────────────────────────────────────────────────────────
router.get('/users', [auth, isAdmin], async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    res.send(users);
  } catch (ex) {
    console.error('Error fetching users:', ex);
    res.status(500).send('Error fetching users');
  }
});

// ── GET pending PWD cards ─────────────────────────────────────────────────────
router.get('/pwd-pending', [auth, isAdmin], async (req, res) => {
  try {
    const users = await User.find({ pwdCardVerificationStatus: 'pending' })
      .select('-password').sort({ updatedAt: -1 });
    res.send(users);
  } catch (ex) {
    console.error('Error fetching pending PWD cards:', ex);
    res.status(500).send('Error fetching pending PWD cards');
  }
});

// ── VERIFY PWD card ───────────────────────────────────────────────────────────
router.put('/verify-pwd/:userId', [auth, isAdmin], async (req, res) => {
  try {
    const admin = await User.findById(req.user._id);
    const user  = await User.findByIdAndUpdate(
      req.params.userId,
      { $set: { pwdCardVerificationStatus: 'verified', pwdCardRejectionReason: '' } },
      { new: true }
    );
    if (!user) return res.status(404).send('User not found');
    console.log(`PWD verified for ${user.email} by ${admin.email}`);
    res.send({ message: 'PWD card verified successfully' });
  } catch (ex) {
    console.error('Error verifying PWD card:', ex);
    res.status(500).send('Error verifying PWD card');
  }
});

// ── REJECT PWD card ───────────────────────────────────────────────────────────
router.put('/reject-pwd/:userId', [auth, isAdmin], async (req, res) => {
  try {
    const { reason } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      {
        $set: {
          pwdCardVerificationStatus: 'rejected',
          pwdCardRejectionReason: reason || 'Card number could not be verified',
        },
      },
      { new: true }
    );
    if (!user) return res.status(404).send('User not found');
    res.send({ message: 'PWD card rejected' });
  } catch (ex) {
    console.error('Error rejecting PWD card:', ex);
    res.status(500).send('Error rejecting PWD card');
  }
});

// ── GET all programs ──────────────────────────────────────────────────────────
router.get('/programs', [auth, isAdmin], async (req, res) => {
  try {
    const programs = await Program.find().sort({ createdAt: -1 });
    res.send(programs);
  } catch (ex) {
    console.error('Error fetching programs:', ex);
    res.status(500).send('Error fetching programs');
  }
});

// ── POST new program ──────────────────────────────────────────────────────────
router.post('/programs', [auth, isAdmin], async (req, res) => {
  try {
    const {
      name, organization, category, description,
      website, hasOnlineApplication, requiredDocuments,
      physicalLocations, howToApply, deadline, contact,
    } = req.body;

    if (!name || !organization || !category || !description) {
      return res.status(400).send('Name, organization, category and description are required');
    }

    // Map Flutter categories to model enum values
    const categoryMap = {
      'Cash Transfer':     'Disability',
      'Assistive Devices': 'Disability',
      'Education':         'Education',
      'Healthcare':        'Healthcare',
      'Employment':        'Employment',
      'Legal':             'Disability',
    };
    const mappedCategory = categoryMap[category] || 'Disability';

    // Build contact info from contact string
    const contactInfo = {};
    if (contact) {
      contactInfo.address = contact;
      const emailMatch = contact.match(/[\w.-]+@[\w.-]+\.\w+/);
      if (emailMatch) contactInfo.email = emailMatch[0];
      const phoneMatch = contact.match(/\+?\d[\d\s\-]{7,}/);
      if (phoneMatch) contactInfo.phone = phoneMatch[0].trim();
    }

    // Build full description including extra fields
    let fullDescription = description.trim();
    if (howToApply)      fullDescription += `\n\nHow to Apply:\n${howToApply}`;
    if (physicalLocations && physicalLocations.length > 0) {
      fullDescription += `\n\nPhysical Locations:\n${physicalLocations.join('\n')}`;
    }
    if (deadline)        fullDescription += `\n\nDeadline: ${deadline}`;
    if (hasOnlineApplication !== undefined) {
      fullDescription += `\n\nOnline Application: ${hasOnlineApplication ? 'Yes' : 'No'}`;
    }
    if (fullDescription.length > 1000) {
      fullDescription = fullDescription.substring(0, 997) + '...';
    }

    const program = new Program({
      name:             name.trim(),
      description:      fullDescription,
      category:         mappedCategory,
      provider:         'Government',
      eligibility:      {},
      applicationLink:  website || '',
      documentsRequired: requiredDocuments || [],
      contactInfo,
      isActive:         true,
    });

    await program.save();
    console.log(`Program "${program.name}" created by admin ${req.user._id}`);
    res.status(201).send({ message: 'Program created successfully', program });
  } catch (ex) {
    console.error('Error creating program:', ex);
    res.status(500).send('Error creating program: ' + ex.message);
  }
});

// ── DELETE program ────────────────────────────────────────────────────────────
router.delete('/programs/:id', [auth, isAdmin], async (req, res) => {
  try {
    const program = await Program.findByIdAndDelete(req.params.id);
    if (!program) return res.status(404).send('Program not found');
    res.send({ message: 'Program deleted successfully' });
  } catch (ex) {
    console.error('Error deleting program:', ex);
    res.status(500).send('Error deleting program');
  }
});

module.exports = router;