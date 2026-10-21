require('dotenv').config();

/**
 * Ensures critical environment variables are set before the app starts.
 * Throws an error if a required config key is missing.
 */
module.exports = function () {
  // Check for JWT secret key
  if (!process.env.JWT_PRIVATE_KEY) {
    throw new Error('FATAL ERROR: JWT_PRIVATE_KEY is not defined!');
  }

  // Optional: check for MongoDB connection string
  if (!process.env.MONGO_URI) {
    console.warn('Warning: MONGO_URI is not defined — make sure it is set before connecting to MongoDB.');
  }
};