const mongoose = require('mongoose');
const Joi = require('joi');

// Aid Program Model
const programSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    minlength: 5,
    maxlength: 100
  },
  description: {
    type: String,
    required: true,
    minlength: 10,
    maxlength: 1000
  },
  category: {
    type: String,
    required: true,
    enum: ['Education', 'Food Relief', 'Healthcare', 'Housing', 'Employment', 'Disability', 'Youth', 'Elderly']
  },
  provider: {
    type: String,
    required: true,
    enum: ['Government', 'NGO', 'CDF', 'Private', 'International Aid']
  },
  
  // Eligibility Criteria
  eligibility: {
    minAge: { type: Number, min: 0 },
    maxAge: { type: Number, min: 0 },
    maxIncome: { type: Number, min: 0 },
    locations: [{ type: String }],
    minHouseholdSize: { type: Number, min: 1 },
    maxHouseholdSize: { type: Number, min: 1 },
    requiredDisabilities: [{ type: String }],
    studentOnly: { type: Boolean, default: false },
    employmentStatus: [{ type: String }]
  },
  
  // Application Details
  applicationLink: String,
  applicationDeadline: Date,
  documentsRequired: [{ type: String }],
  contactInfo: {
    phone: String,
    email: String,
    address: String
  },
  
  // Metadata
  isActive: { type: Boolean, default: true },
  popularity: { type: Number, default: 0 }, // Track how many users match
  lastUpdated: { type: Date, default: Date.now }
}, {
  timestamps: true
});

const Program = mongoose.model('Program', programSchema);

// Validation for creating/updating programs
function validateProgram(program) {
  const schema = Joi.object({
    name: Joi.string().min(5).max(100).required(),
    description: Joi.string().min(10).max(1000).required(),
    category: Joi.string().valid('Education', 'Food Relief', 'Healthcare', 'Housing', 'Employment', 'Disability', 'Youth', 'Elderly').required(),
    provider: Joi.string().valid('Government', 'NGO', 'CDF', 'Private', 'International Aid').required(),
    eligibility: Joi.object({
      minAge: Joi.number().min(0),
      maxAge: Joi.number().min(0),
      maxIncome: Joi.number().min(0),
      locations: Joi.array().items(Joi.string()),
      minHouseholdSize: Joi.number().min(1),
      maxHouseholdSize: Joi.number().min(1),
      requiredDisabilities: Joi.array().items(Joi.string()),
      studentOnly: Joi.boolean(),
      employmentStatus: Joi.array().items(Joi.string())
    }).required(),
    applicationLink: Joi.string().uri(),
    applicationDeadline: Joi.date(),
    documentsRequired: Joi.array().items(Joi.string()),
    contactInfo: Joi.object({
      phone: Joi.string(),
      email: Joi.string().email(),
      address: Joi.string()
    })
  });
  return schema.validate(program);
}

module.exports = {
  Program,
  validateProgram
};