const express = require('express');
const app = express();
const cors = require('cors');
const path = require('path');

app.use(cors({
  origin: '*',
  exposedHeaders: ['x-auth-token']
}));

app.use(express.json());

// ── Serve uploaded files (PWD card images etc.) ───────────────────────────────
// MUST be before routes and listen()
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

require('./startup/config')();
require('./startup/routes')(app);
require('./startup/db')();
require('./cron/statusUpdater');

const port = process.env.PORT || 5000;
app.listen(port, () => console.log('Listening on port ' + port));