const mongoose = require('mongoose');
const jwt      = require('jsonwebtoken');
const Joi      = require('joi');

const userSchema = new mongoose.Schema({
  // ── Auth ──────────────────────────────────────────────────────────────────
  firstName: { type: String, required: true, minlength: 2, maxlength: 50 },
  lastName:  { type: String, required: true, minlength: 2, maxlength: 50 },
  email:     { type: String, required: true, unique: true, minlength: 5, maxlength: 255 },
  password:  { type: String, required: true, minlength: 5, maxlength: 1024 },
  isAdmin:   { type: Boolean, default: false },

  // ── Email Verification ────────────────────────────────────────────────────
  emailVerified:           { type: Boolean, default: false },
  emailVerificationToken:  { type: String },
  emailVerificationExpiry: { type: Date },

  // ── Password Reset ────────────────────────────────────────────────────────
  passwordResetToken:  { type: String },
  passwordResetExpiry: { type: Date },

  // ── Profile ───────────────────────────────────────────────────────────────
  profileCompleted: { type: Boolean, default: false },
  applicantType:    { type: String, enum: ['Self', 'Caretaker'], default: 'Self' },

  caretakerName:         { type: String, default: '' },
  caretakerRelationship: { type: String, default: '' },
  caretakerPhone:        { type: String, default: '' },
  caretakerNationalId:   { type: String, default: '' },

  age:               { type: Number, default: 0 },
  location:          { type: String, default: '' },
  citizenshipStatus: { type: String, default: '' },
  householdSize:     { type: Number, default: 0 },
  income:            { type: Number, default: 0 },

  employmentStatus: { type: String, default: '' },
  educationLevel:   { type: String, default: '' },
  isStudent:        { type: Boolean, default: false },

  disabilityType:   { type: String, default: '' },
  disabilityStatus: { type: Boolean, default: false },
  disabilities:     [{ type: String }],

  // ── PWD Card ──────────────────────────────────────────────────────────────
  pwdCardStatus:   { type: Boolean, default: false },
  pwdCardNumber:   { type: String, default: '' },
  pwdCardImageUrl: { type: String, default: '' },

  pwdCardVerificationStatus: {
    type: String,
    enum: ['unverified', 'pending', 'verified', 'rejected'],
    default: 'unverified',
  },
  pwdCardRejectionReason: { type: String, default: '' },

  // ── Saved Programs & Applications ─────────────────────────────────────────
  savedProgramIds: [{ type: String }],

  applications: [
    {
      programId:   { type: mongoose.Schema.Types.Mixed },
      programName: { type: String, default: '' },
      status: {
        type: String,
        enum: ['Pending', 'Under Review', 'Approved', 'Rejected', 'Completed'],
        default: 'Pending',
      },
      appliedAt: { type: Date, default: Date.now },
      updatedAt: { type: Date, default: Date.now },
    },
  ],
}, { timestamps: true });

// ── Generate JWT ──────────────────────────────────────────────────────────────
userSchema.methods.generateAuthToken = function () {
  return jwt.sign(
    { _id: this._id, email: this.email, isAdmin: this.isAdmin },
    process.env.JWT_PRIVATE_KEY,
    { expiresIn: '7d' }
  );
};

userSchema.virtual('fullName').get(function () {
  return `${this.firstName} ${this.lastName}`;
});

const User = mongoose.model('User', userSchema);

// ── Validate new user ─────────────────────────────────────────────────────────
function validateUser(user) {
  const schema = Joi.object({
    firstName: Joi.string().min(2).max(50).required(),
    lastName:  Joi.string().min(2).max(50).required(),
    email:     Joi.string().email().min(5).max(255).required(),
    password:  Joi.string().min(8).max(1024).required(), // min 8 chars
  });
  return schema.validate(user);
}

// ── Validate profile ──────────────────────────────────────────────────────────
function validateUserProfile(profile) {
  const schema = Joi.object({
    applicantType:         Joi.string().valid('Self', 'Caretaker').required(),
    caretakerName:         Joi.string().allow('').optional(),
    caretakerRelationship: Joi.string().allow('').optional(),
    caretakerPhone:        Joi.string().allow('').optional(),
    caretakerNationalId:   Joi.string().allow('').optional(),
    age:                   Joi.number().min(1).max(120).required(),
    location:              Joi.string().required(),
    citizenshipStatus:     Joi.string().required(),
    householdSize:         Joi.number().min(1).required(),
    income:                Joi.number().min(0).required(),
    employmentStatus:      Joi.string().required(),
    educationLevel:        Joi.string().required(),
    isStudent:             Joi.boolean().optional(),
    disabilityType:        Joi.string().required(),
    disabilityStatus:      Joi.boolean().optional(),
    pwdCardStatus:         Joi.boolean().optional(),
    pwdCardNumber:         Joi.string().allow('').optional(),
    pwdCardImageUrl:       Joi.string().allow('').optional(),
    disabilities:          Joi.array().items(Joi.string()).optional(),
  });
  return schema.validate(profile);
}

module.exports = { User, validateUser, validateUserProfile };