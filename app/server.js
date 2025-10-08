const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Health check endpoint - very important for monitoring
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
    hostname: require('os').hostname()
  });
});

// Main application endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'CI/CD deployment pipeline!',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0',
    project: 'DevOps Foundation'
  });
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${port}`);
  console.log(`📱 Health check: http://localhost:${port}/health`);
  console.log(`🌐 Main app: http://localhost:${port}`);
});
