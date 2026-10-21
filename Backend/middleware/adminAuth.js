// middleware/adminAuth.js
// Checks that the authenticated user has admin access.
// Must be used AFTER the regular `auth` middleware.
// Admin is identified by email containing 'admin' OR by isAdmin flag on the user.

const { User } = require('../models/user');

module.exports = async function adminAuth(req, res, next) {
  try {
    const user = await User.findById(req.user._id).select('email isAdmin');
    if (!user) return res.status(404).send('User not found');

    // Allow if email contains 'admin' OR if isAdmin flag is true
    const isAdmin = user.isAdmin === true || user.email.toLowerCase().includes('admin');
    if (!isAdmin) {
      return res.status(403).send('Access denied. Admin privileges required.');
    }

    next();
  } catch (ex) {
    res.status(500).send('Admin auth error');
  }
};