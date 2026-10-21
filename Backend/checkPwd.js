require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const { User } = require('./models/user');
  const users = await User.find({ pwdCardStatus: true }).select('email pwdCardStatus pwdCardVerificationStatus pwdCardNumber');
  console.log(JSON.stringify(users, null, 2));
  process.exit();
});