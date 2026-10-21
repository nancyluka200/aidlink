require('dotenv').config();
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGO_URI).then(async () => {
  const { User } = require('./models/user');
  const u = await User.findOne({ email: 'nancyluka200@gmail.com' })
    .select('pwdCardImageUrl');
  console.log('Image URL:', u?.pwdCardImageUrl);
  process.exit();
});