const express      = require('express');
const router       = express.Router();
const { User, validateUser, validateUserProfile } = require('../models/user');
const auth         = require('../middleware/auth');
const bcrypt       = require('bcrypt');
const Joi          = require('joi');
const _            = require('lodash');
const multer       = require('multer');
const path         = require('path');
const fs           = require('fs');
const crypto       = require('crypto');
const nodemailer   = require('nodemailer');
require('dotenv').config();

// ── Email transporter ─────────────────────────────────────────────────────────
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

async function sendVerificationEmail(user, token) {
  const verifyUrl = `${process.env.BASE_URL || 'http://localhost:5000'}/api/users/verify-email/${token}`;
  await transporter.sendMail({
    from: `"AidLink" <${process.env.EMAIL_USER}>`,
    to: user.email,
    subject: 'Verify your AidLink email address',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:32px;border-radius:10px;border:1px solid #e0e0e0;">
        <div style="text-align:center;margin-bottom:24px;">
          <h2 style="color:#164EB0;margin:0;">AidLink</h2>
          <p style="color:#666;font-size:13px;margin:4px 0 0;">Smart Disability Assistance Matching</p>
        </div>
        <h3 style="color:#222;">Hello, ${user.firstName}!</h3>
        <p style="color:#444;line-height:1.6;">
          Thank you for creating an AidLink account. Please verify your email address to unlock all features.
        </p>
        <div style="text-align:center;margin:32px 0;">
          <a href="${verifyUrl}"
             style="background-color:#164EB0;color:white;padding:14px 32px;border-radius:8px;text-decoration:none;font-weight:bold;font-size:15px;">
            Verify My Email
          </a>
        </div>
        <p style="color:#888;font-size:12px;text-align:center;">
          This link expires in 24 hours. If you did not create an AidLink account, you can safely ignore this email.
        </p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
        <p style="color:#aaa;font-size:11px;text-align:center;">
          AidLink — Connecting persons with disabilities to government support programs in Kenya.
        </p>
      </div>
    `,
  });
}

// ── Forgot Password Email ─────────────────────────────────────────────────────
async function sendPasswordResetEmail(user, token) {
  const resetUrl = `${process.env.BASE_URL || 'http://localhost:5000'}/api/users/reset-password/${token}`;
  await transporter.sendMail({
    from: `"AidLink" <${process.env.EMAIL_USER}>`,
    to: user.email,
    subject: 'Reset your AidLink password',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:32px;border-radius:10px;border:1px solid #e0e0e0;">
        <div style="text-align:center;margin-bottom:24px;">
          <h2 style="color:#164EB0;margin:0;">AidLink</h2>
          <p style="color:#666;font-size:13px;margin:4px 0 0;">Smart Disability Assistance Matching</p>
        </div>
        <h3 style="color:#222;">Hello, ${user.firstName}!</h3>
        <p style="color:#444;line-height:1.6;">
          We received a request to reset your AidLink password. Click the button below to set a new password.
        </p>
        <div style="text-align:center;margin:32px 0;">
          <a href="${resetUrl}"
             style="background-color:#164EB0;color:white;padding:14px 32px;border-radius:8px;text-decoration:none;font-weight:bold;font-size:15px;">
            Reset My Password
          </a>
        </div>
        <p style="color:#888;font-size:12px;text-align:center;">
          This link expires in 1 hour. If you did not request a password reset, you can safely ignore this email.
        </p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
        <p style="color:#aaa;font-size:11px;text-align:center;">
          AidLink — Connecting persons with disabilities to government support programs in Kenya.
        </p>
      </div>
    `,
  });
}

// ── Multer: PWD card image upload ─────────────────────────────────────────────
const uploadDir = path.join(__dirname, '../uploads/pwd-cards');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `pwd_${req.user._id}_${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = ['.jpg', '.jpeg', '.png', '.heic', '.webp'];
    if (allowed.includes(path.extname(file.originalname).toLowerCase())) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed (jpg, png, heic, webp)'));
    }
  },
});

// ── Create Account ────────────────────────────────────────────────────────────
router.post('/create-account', async (req, res) => {
  try {
    // ── Input validation ───────────────────────────────────────────────────
    const { firstName, lastName, email, password } = req.body;

    if (!firstName || firstName.trim().length === 0) {
      return res.status(400).send('First name is required');
    }
    if (!lastName || lastName.trim().length === 0) {
      return res.status(400).send('Last name is required');
    }
    if (firstName.trim().length < 2) {
      return res.status(400).send('First name must be at least 2 characters');
    }
    if (lastName.trim().length < 2) {
      return res.status(400).send('Last name must be at least 2 characters');
    }
    if (!password || password.length < 8) {
      return res.status(400).send('Password must be at least 8 characters');
    }

    const { error } = validateUser(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    let user = await User.findOne({ email: req.body.email });
    if (user) return res.status(400).send('A user with this email already exists');

    user = new User(_.pick(req.body, ['firstName', 'lastName', 'email', 'password']));
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(user.password, salt);

    const verificationToken = crypto.randomBytes(32).toString('hex');
    user.emailVerificationToken  = verificationToken;
    user.emailVerificationExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000);
    user.emailVerified           = false;

    const token = user.generateAuthToken();
    await user.save();

    sendVerificationEmail(user, verificationToken).catch(err =>
      console.error('Failed to send verification email:', err)
    );

    res.header('x-auth-token', token).send({ message: 'Account created successfully' });
  } catch (ex) {
    console.error('Error creating account:', ex);
    res.status(500).send('Something went wrong while creating account.');
  }
});

// ── Verify Email ──────────────────────────────────────────────────────────────
router.get('/verify-email/:token', async (req, res) => {
  try {
    const user = await User.findOne({
      emailVerificationToken:  req.params.token,
      emailVerificationExpiry: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).send(`
        <div style="font-family:Arial,sans-serif;text-align:center;padding:60px;">
          <h2 style="color:#e53935;">Link Expired or Invalid</h2>
          <p>This verification link has expired or is invalid.<br>Please request a new one from the AidLink app.</p>
        </div>
      `);
    }

    user.emailVerified           = true;
    user.emailVerificationToken  = undefined;
    user.emailVerificationExpiry = undefined;
    await user.save();

    res.send(`
      <div style="font-family:Arial,sans-serif;text-align:center;padding:60px;max-width:480px;margin:auto;">
        <h2 style="color:#164EB0;">&#10003; Email Verified!</h2>
        <p style="color:#444;">Your AidLink account has been verified successfully.</p>
        <p style="color:#666;font-size:13px;">You can now close this tab and return to the app.</p>
      </div>
    `);
  } catch (ex) {
    console.error('Error verifying email:', ex);
    res.status(500).send('Something went wrong during verification.');
  }
});

// ── Resend Verification Email ─────────────────────────────────────────────────
router.post('/resend-verification', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).send('User not found');
    if (user.emailVerified) return res.status(400).send('Email is already verified');

    const verificationToken = crypto.randomBytes(32).toString('hex');
    user.emailVerificationToken  = verificationToken;
    user.emailVerificationExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await user.save();

    await sendVerificationEmail(user, verificationToken);
    res.send({ message: 'Verification email sent' });
  } catch (ex) {
    console.error('Error resending verification email:', ex);
    res.status(500).send('Could not send verification email');
  }
});

// ── Forgot Password — Request Reset ──────────────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).send('Email is required');

    const user = await User.findOne({ email: email.toLowerCase().trim() });

    // Always respond with success to prevent email enumeration
    if (!user) {
      return res.send({ message: 'If that email exists, a reset link has been sent.' });
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    user.passwordResetToken  = resetToken;
    user.passwordResetExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
    await user.save();

    await sendPasswordResetEmail(user, resetToken);
    res.send({ message: 'If that email exists, a reset link has been sent.' });
  } catch (ex) {
    console.error('Error sending reset email:', ex);
    res.status(500).send('Something went wrong. Please try again.');
  }
});

// ── Reset Password — Handle Link Click (browser opens this) ──────────────────
router.get('/reset-password/:token', async (req, res) => {
  try {
    const user = await User.findOne({
      passwordResetToken:  req.params.token,
      passwordResetExpiry: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).send(`
        <div style="font-family:Arial,sans-serif;text-align:center;padding:60px;">
          <h2 style="color:#e53935;">Link Expired or Invalid</h2>
          <p>This password reset link has expired or is invalid.<br>Please request a new one from the AidLink app.</p>
        </div>
      `);
    }

    // Show a simple HTML form to enter new password
    res.send(`
      <div style="font-family:Arial,sans-serif;max-width:420px;margin:60px auto;padding:32px;border-radius:12px;border:1px solid #e0e0e0;">
        <h2 style="color:#164EB0;text-align:center;">Reset Your Password</h2>
        <p style="color:#666;text-align:center;font-size:13px;">Enter your new password below.</p>
        <form method="POST" action="/api/users/reset-password/${req.params.token}" style="margin-top:24px;">
          <div style="margin-bottom:16px;">
            <label style="display:block;font-size:13px;font-weight:600;margin-bottom:6px;">New Password</label>
            <input type="password" name="password" required minlength="8"
              style="width:100%;padding:10px 12px;border:1px solid #ccc;border-radius:8px;font-size:14px;box-sizing:border-box;"
              placeholder="At least 8 characters" />
          </div>
          <div style="margin-bottom:24px;">
            <label style="display:block;font-size:13px;font-weight:600;margin-bottom:6px;">Confirm Password</label>
            <input type="password" name="confirmPassword" required minlength="8"
              style="width:100%;padding:10px 12px;border:1px solid #ccc;border-radius:8px;font-size:14px;box-sizing:border-box;"
              placeholder="Repeat your new password" />
          </div>
          <button type="submit"
            style="width:100%;background:#164EB0;color:white;padding:12px;border:none;border-radius:8px;font-size:15px;font-weight:bold;cursor:pointer;">
            Reset Password
          </button>
        </form>
      </div>
    `);
  } catch (ex) {
    console.error('Error showing reset form:', ex);
    res.status(500).send('Something went wrong.');
  }
});

// ── Reset Password — Form Submit ──────────────────────────────────────────────
router.post('/reset-password/:token', async (req, res) => {
  try {
    const { password, confirmPassword } = req.body;

    if (!password || password.length < 8) {
      return res.status(400).send(`
        <div style="font-family:Arial,sans-serif;text-align:center;padding:60px;">
          <h2 style="color:#e53935;">Invalid Password</h2>
          <p>Password must be at least 8 characters. <a href="javascript:history.back()">Go back</a></p>
        </div>
      `);
    }

    if (password !== confirmPassword) {
      return res.status(400).send(`
        <div style="font-family:Arial,sans-serif;text-align:center;padding:60px;">
          <h2 style="color:#e53935;">Passwords Don't Match</h2>
          <p>Please make sure both passwords are the same. <a href="javascript:history.back()">Go back</a></p>
        </div>
      `);
    }

    const user = await User.findOne({
      passwordResetToken:  req.params.token,
      passwordResetExpiry: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).send(`
        <div style="font-family:Arial,sans-serif;text-align:center;padding:60px;">
          <h2 style="color:#e53935;">Link Expired</h2>
          <p>This reset link has expired. Please request a new one from the AidLink app.</p>
        </div>
      `);
    }

    const salt = await bcrypt.genSalt(10);
    user.password            = await bcrypt.hash(password, salt);
    user.passwordResetToken  = undefined;
    user.passwordResetExpiry = undefined;
    await user.save();

    res.send(`
      <div style="font-family:Arial,sans-serif;text-align:center;padding:60px;max-width:480px;margin:auto;">
        <h2 style="color:#164EB0;">&#10003; Password Reset!</h2>
        <p style="color:#444;">Your password has been updated successfully.</p>
        <p style="color:#666;font-size:13px;">You can now close this tab and sign in with your new password.</p>
      </div>
    `);
  } catch (ex) {
    console.error('Error resetting password:', ex);
    res.status(500).send('Something went wrong. Please try again.');
  }
});

// ── Sign In ───────────────────────────────────────────────────────────────────
function validateSignIn(credentials) {
  const schema = Joi.object({
    email:    Joi.string().email().required(),
    password: Joi.string().required(),
  });
  return schema.validate(credentials);
}

router.post('/sign-in', async (req, res) => {
  try {
    const { error } = validateSignIn(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    const user = await User.findOne({ email: req.body.email });
    if (!user) return res.status(400).send('Invalid email or password');

    const validPassword = await bcrypt.compare(req.body.password, user.password);
    if (!validPassword) return res.status(400).send('Invalid email or password');

    const token = user.generateAuthToken();
    res.header('x-auth-token', token).send({
      email:                     user.email,
      isAdmin:                   user.isAdmin,
      emailVerified:             user.emailVerified,
      pwdCardVerificationStatus: user.pwdCardVerificationStatus,
      pwdCardRejectionReason:    user.pwdCardRejectionReason,
      profileCompleted:          user.profileCompleted,
      message:                   'Sign-in successful',
    });
  } catch (ex) {
    console.error('Error during sign-in:', ex);
    res.status(500).send('Something went wrong during sign-in.');
  }
});

// ── Complete Profile ──────────────────────────────────────────────────────────
router.put('/complete-profile', auth, async (req, res) => {
  try {
    const { error } = validateUserProfile(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    if (req.body.applicantType === 'Caretaker') {
      const nid = (req.body.caretakerNationalId || '').toString().trim();
      if (!/^\d{8}$/.test(nid)) {
        return res.status(400).send('National ID must be exactly 8 digits');
      }
      if (nid.startsWith('0') || parseInt(nid[0]) > 3) {
        return res.status(400).send('Enter a valid Kenyan National ID');
      }
    }

    const pwdCardStatus = req.body.pwdCardStatus || false;
    const pwdUpdateFields = pwdCardStatus
      ? { pwdCardVerificationStatus: 'pending', pwdCardRejectionReason: '' }
      : {};

    await User.findByIdAndUpdate(
      req.user._id,
      {
        $set: {
          applicantType:         req.body.applicantType,
          caretakerName:         req.body.caretakerName         || '',
          caretakerRelationship: req.body.caretakerRelationship || '',
          caretakerPhone:        req.body.caretakerPhone        || '',
          caretakerNationalId:   req.body.caretakerNationalId   || '',
          age:               req.body.age,
          location:          req.body.location,
          citizenshipStatus: req.body.citizenshipStatus,
          householdSize:     req.body.householdSize,
          income:            req.body.income,
          employmentStatus:  req.body.employmentStatus,
          educationLevel:    req.body.educationLevel,
          isStudent:         req.body.isStudent || false,
          disabilityType:    req.body.disabilityType,
          disabilityStatus:  req.body.disabilityStatus || false,
          pwdCardStatus,
          pwdCardNumber:     req.body.pwdCardNumber    || '',
          pwdCardImageUrl:   req.body.pwdCardImageUrl  || '',
          disabilities:      req.body.disabilities     || [],
          profileCompleted:  true,
          ...pwdUpdateFields,
        },
      },
      { new: true }
    );

    res.send({ message: 'Profile completed successfully', profileCompleted: true });
  } catch (ex) {
    console.error('Error completing profile:', ex);
    res.status(500).send('Something went wrong while updating profile.');
  }
});

// ── Get Profile ───────────────────────────────────────────────────────────────
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    if (!user) return res.status(404).send('User not found');
    res.send(user);
  } catch (ex) {
    console.error('Error fetching profile:', ex);
    res.status(500).send('Something went wrong while fetching profile.');
  }
});

// ── Upload PWD Card Image ─────────────────────────────────────────────────────
router.post('/upload-pwd-card', auth, upload.single('pwdCard'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).send('No image file provided');
    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/pwd-cards/${req.file.filename}`;
    await User.findByIdAndUpdate(req.user._id, { $set: { pwdCardImageUrl: imageUrl } });
    res.send({ url: imageUrl });
  } catch (ex) {
    console.error('Error uploading PWD card image:', ex);
    res.status(500).send('Something went wrong while uploading the image.');
  }
});

// ── Save a Program ────────────────────────────────────────────────────────────
router.post('/save-program/:programId', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).send('User not found');
    const programId = req.params.programId;
    if ((user.savedProgramIds || []).includes(programId)) {
      return res.status(400).send('Program already saved');
    }
    user.savedProgramIds = user.savedProgramIds || [];
    user.savedProgramIds.push(programId);
    await user.save();
    res.send({ message: 'Program saved successfully' });
  } catch (ex) {
    console.error('Error saving program:', ex);
    res.status(500).send('Something went wrong while saving program.');
  }
});

// ── Get Saved Programs + Applications ─────────────────────────────────────────
router.get('/saved-programs', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).send('User not found');
    const savedPrograms = (user.savedProgramIds || []).map(id => ({
      _id: id, name: id, description: '', category: '', provider: '', applicationLink: '',
    }));
    res.send({ savedPrograms, applications: user.applications || [] });
  } catch (ex) {
    console.error('Error fetching saved programs:', ex);
    res.status(500).send('Error fetching saved programs');
  }
});

// ── Remove Saved Program ──────────────────────────────────────────────────────
router.delete('/saved-program/:programId', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).send('User not found');
    user.savedProgramIds = (user.savedProgramIds || []).filter(
      id => id !== req.params.programId
    );
    await user.save();
    res.send({ message: 'Program removed from saved' });
  } catch (ex) {
    console.error('Error removing saved program:', ex);
    res.status(500).send('Error removing saved program');
  }
});

// ── Track Application ─────────────────────────────────────────────────────────
router.post('/apply/:programId', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).send('User not found');
    const programId   = req.params.programId;
    const programName = req.body.programName || '';
    const alreadyApplied = (user.applications || []).some(
      a => a.programId.toString() === programId
    );
    if (alreadyApplied) return res.status(400).send('Already tracking this application');
    user.applications = user.applications || [];
    user.applications.push({
      programId, programName, status: 'Pending',
      appliedAt: new Date(), updatedAt: new Date(),
    });
    await user.save();
    res.send({ message: 'Application tracked successfully' });
  } catch (ex) {
    console.error('Error tracking application:', ex);
    res.status(500).send('Error tracking application');
  }
});

// ── Update Application Status ─────────────────────────────────────────────────
router.put('/application-status/:programId', auth, async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['Pending', 'Under Review', 'Approved', 'Rejected', 'Completed'];
    if (!validStatuses.includes(status)) return res.status(400).send('Invalid status');
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).send('User not found');
    const application = (user.applications || []).find(
      a => a.programId.toString() === req.params.programId
    );
    if (!application) return res.status(404).send('Application not found');
    application.status    = status;
    application.updatedAt = new Date();
    await user.save();
    res.send({ message: 'Application status updated' });
  } catch (ex) {
    console.error('Error updating application status:', ex);
    res.status(500).send('Error updating application status');
  }
});

module.exports = router;