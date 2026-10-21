const express = require('express');
const router = express.Router();
const { Program, validateProgram } = require('../models/program');
const { User } = require('../models/user');
const auth = require('../middleware/auth');

// Get all programs (public)
router.get('/', async (req, res) => {
  try {
    const programs = await Program.find({ isActive: true })
      .sort({ popularity: -1, createdAt: -1 });
    
    res.send(programs);
  } catch (ex) {
    console.error('Error fetching programs:', ex);
    res.status(500).send('Something went wrong while fetching programs.');
  }
});

//Get program by ID
router.get('/:id', async (req, res) => {
  try {
    const program = await Program.findById(req.params.id);
    if (!program) return res.status(404).send('Program not found');
    
    res.send(program);
  } catch (ex) {
    console.error('Error fetching program:', ex);
    res.status(500).send('Something went wrong while fetching program.');
  }
});

//The matched programs for users who are logged in
router.get('/user/matches', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).send('User not found');

    // Check if user has completed profile
    if (!user.age || !user.income) {
      return res.status(400).send('Please complete your profile first to get matches');
    }

    const allPrograms = await Program.find({ isActive: true });
    const matchedPrograms = [];

    for (let program of allPrograms) {
      const score = calculateMatchScore(user, program);
      
      if (score >= 60) { // Only return programs with at least 60% match
        matchedPrograms.push({
          program: program,
          matchScore: score,
          reasons: getMatchReasons(user, program)
        });
      }
    }

    // This Sorts by match score with the highest being first
    matchedPrograms.sort((a, b) => b.matchScore - a.matchScore);

    // Update user's matched programs
    user.matchedPrograms = matchedPrograms.map(match => ({
      programId: match.program._id,
      eligibilityScore: match.matchScore
    }));
    await user.save();

    res.send(matchedPrograms);
  } catch (ex) {
    console.error('Error matching programs:', ex);
    res.status(500).send('Something went wrong while finding matches.');
  }
});

// Matching Algorithm
function calculateMatchScore(user, program) {
  let score = 0;
  let totalCriteria = 0;
  const eligibility = program.eligibility;

  // Age matching (20% weight)
  if (eligibility.minAge || eligibility.maxAge) {
    totalCriteria += 20;
    if ((!eligibility.minAge || user.age >= eligibility.minAge) && 
        (!eligibility.maxAge || user.age <= eligibility.maxAge)) {
      score += 20;
    }
  }

  // Income matching (20% weight)
  if (eligibility.maxIncome) {
    totalCriteria += 20;
    if (user.income <= eligibility.maxIncome) {
      score += 20;
    }
  }

  // Location matching (15% weight)
  if (eligibility.locations && eligibility.locations.length > 0) {
    totalCriteria += 15;
    if (eligibility.locations.includes(user.location)) {
      score += 15;
    }
  }

  // Household size matching (15% weight)
  if (eligibility.minHouseholdSize || eligibility.maxHouseholdSize) {
    totalCriteria += 15;
    if ((!eligibility.minHouseholdSize || user.householdSize >= eligibility.minHouseholdSize) && 
        (!eligibility.maxHouseholdSize || user.householdSize <= eligibility.maxHouseholdSize)) {
      score += 15;
    }
  }

  // Disability matching (15% weight)
  if (eligibility.requiredDisabilities && eligibility.requiredDisabilities.length > 0) {
    totalCriteria += 15;
    const hasRequiredDisability = eligibility.requiredDisabilities.some(disability => 
      user.disabilities.includes(disability)
    );
    if (hasRequiredDisability) score += 15;
  }

  // Student status matching (15% weight)
  if (eligibility.studentOnly) {
    totalCriteria += 15;
    if (user.isStudent === true) {
      score += 15;
    }
  }

  // Calculate percentage score
  return totalCriteria > 0 ? Math.round((score / totalCriteria) * 100) : 0;
}

function getMatchReasons(user, program) {
  const reasons = [];
  const eligibility = program.eligibility;

  if (eligibility.minAge && user.age >= eligibility.minAge) {
    reasons.push(`Meets minimum age requirement (${eligibility.minAge}+)`);
  }
  if (eligibility.maxIncome && user.income <= eligibility.maxIncome) {
    reasons.push(`Income within eligible range (up to ${eligibility.maxIncome})`);
  }
  if (eligibility.locations && eligibility.locations.includes(user.location)) {
    reasons.push(`Located in eligible area (${user.location})`);
  }

  return reasons;
}

//Create new program 
router.post('/', async (req, res) => {
  try {
    const { error } = validateProgram(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    const program = new Program(req.body);
    await program.save();

    res.send(program);
  } catch (ex) {
    console.error('Error creating program:', ex);
    res.status(500).send('Something went wrong while creating program.');
  }
});

module.exports = router;