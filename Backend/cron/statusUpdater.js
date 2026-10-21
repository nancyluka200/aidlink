const cron = require('node-cron');
const User = require('../models/user');

// Runs every hour
cron.schedule('0 * * * *', async () => {
  console.log('[CRON] Running application status updater...');
  const now = new Date();

  try {
    const users = await User.find({ 'applications.0': { $exists: true } });

    for (const user of users) {
      let modified = false;

      for (const app of user.applications) {
        const ageInDays = (now - new Date(app.appliedAt)) / (1000 * 60 * 60 * 24);

        // Pending → Under Review after 2 days
        if (app.status === 'Pending' && ageInDays >= 2) {
          app.status = 'Under Review';
          app.updatedAt = now;
          modified = true;
        }

        // Under Review → Approved or Rejected after 5 days
        // Rule: approve if user has PWD card uploaded, else reject
        else if (app.status === 'Under Review' && ageInDays >= 5) {
          app.status = user.pwdCardImageUrl ? 'Approved' : 'Rejected';
          app.updatedAt = now;
          modified = true;
        }
      }

      if (modified) await user.save();
    }

    console.log('[CRON] Status update complete.');
  } catch (err) {
    console.error('[CRON] Error updating statuses:', err);
  }
});
