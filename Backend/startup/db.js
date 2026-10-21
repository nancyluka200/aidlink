const mongoose = require('mongoose');
require('dotenv').config();

/**
 * Establishes a connection to MongoDB.
 * This function should be called before starting the server.
 */
module.exports = async function connectToDb() {
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    throw new Error(' FATAL ERROR: MONGO_URI is not defined in the .env file!');
  }

  try {
    await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 10000, // 10 seconds timeout
    });

    console.log(' MongoDB connection established successfully');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
    process.exit(1); // Stop the app if the DB connection fails
  }
};
