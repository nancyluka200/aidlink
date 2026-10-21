const express = require('express');
const cors = require('cors');
const users = require('../routes/users');
const programs = require('../routes/programs');
const admin = require('../routes/admin'); // ← ADD THIS

module.exports = function (app) {
  app.use(express.json());

  app.use(cors({
    origin: '*',
    exposedHeaders: ['x-auth-token'] // ← ADD THIS
  }));

  app.use('/api/users', users);
  app.use('/api/programs', programs);
  app.use('/api/admin', admin); // ← ADD THIS

  app.use((req, res) => {
    res.status(404).send({ message: 'Endpoint not found' });
  });
};