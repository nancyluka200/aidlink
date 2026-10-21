require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const { User } = require('./models/user');
  const result = await User.updateOne(
    { email:'user@example.com'},
    { $set: { pwdCardVerificationStatus: 'pending' } }
  );
  console.log('Updated:', result.modifiedCount, 'user(s)');
  process.exit();
});