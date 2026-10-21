require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const { User } = require('./models/user');
  const u = await User.findOne({ email: 'admin@aidlink.com' });
  console.log('Found user:', u ? 'yes' : 'no');
  console.log('isAdmin in DB:', u?.isAdmin);
  process.exit();
});