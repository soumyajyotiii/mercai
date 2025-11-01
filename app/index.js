const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    hostname: os.hostname(),
    version: VERSION
  });
});

app.get('/', (req, res) => {
  res.json({
    message: 'hello from ecs blue/green deployment',
    version: VERSION,
    hostname: os.hostname(),
    platform: os.platform(),
    uptime: process.uptime()
  });
});

app.listen(PORT, () => {
  console.log(`server running on port ${PORT}`);
  console.log(`version: ${VERSION}`);
});
