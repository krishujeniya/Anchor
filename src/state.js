const fs = require('fs');
const path = require('path');

const STATE_FILENAME = '.lfim-state.json';

function getStatePath(dirPath) {
  return path.join(dirPath, STATE_FILENAME);
}

function saveState(dirPath, hashes) {
  const statePath = getStatePath(dirPath);
  fs.writeFileSync(statePath, JSON.stringify(hashes, null, 2), 'utf-8');
}

function loadState(dirPath) {
  const statePath = getStatePath(dirPath);
  if (!fs.existsSync(statePath)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(statePath, 'utf-8'));
}

module.exports = { saveState, loadState };
