// Run this once: node setAdmin.js
// This sets isAdmin:true for your admin account in MongoDB

const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/aidlinkdb')
  .then(async () => {
    const { User } = require('./models/user');

    // ── Change this to your actual admin email ────────────────────────────
  const ADMIN_EMAIL = 'admin@aidlink.com';

    const user = await User.findOneAndUpdate(
      { email: ADMIN_EMAIL },
      { $set: { isAdmin: true } },
      { new: true }
    );

    if (!user) {
      console.log('❌ User not found. Check the email address.');
    } else {
      console.log(`✅ Done! ${user.email} is now an admin (isAdmin: ${user.isAdmin})`);
    }

    process.exit();
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });