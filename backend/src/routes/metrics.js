const express = require('express');
const router = express.Router();
const client = require('prom-client');

// Get metrics
router.get('/', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  const metrics = await client.register.metrics();
  res.send(metrics);
});

module.exports = router;

