const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const deploymentsDir = path.join(__dirname, 'data', 'deployments');

// Middleware to check if deployments directory exists
app.use((req, res, next) => {
  if (fs.existsSync(deploymentsDir)) {
    next();
  } else {
    res.status(404).json({ error: 'Deployments directory not found' });
  }
});

// Serve JSON files from the deployments directory
app.get('/:filename', (req, res) => {
  const filePath = path.join(deploymentsDir, req.params.filename);

  // Check if the requested file exists and is a JSON file
  if (fs.existsSync(filePath) && filePath.endsWith('.json')) {
    res.sendFile(filePath);
  } else {
    res.status(404).json({ error: 'File not found or not a JSON file' });
  }
});

// Start the server on port 3001
const PORT = 3001;
app.listen(PORT, () => {
  console.log(`JSON file server running on port ${PORT}`);
});
