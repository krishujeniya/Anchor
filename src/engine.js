const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const IGNORE_LIST = ['.git', 'node_modules', '.lfim-state.json'];

function hashFile(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('sha256');
    const stream = fs.createReadStream(filePath);
    stream.on('data', data => hash.update(data));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', err => reject(err));
  });
}

async function hashDirectory(dirPath, baseDir = dirPath, hashes = {}) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });

  for (const entry of entries) {
    if (IGNORE_LIST.includes(entry.name)) continue;

    const fullPath = path.join(dirPath, entry.name);
    // Use forward slashes for cross-platform deterministic paths
    const relPath = path.relative(baseDir, fullPath).split(path.sep).join('/');

    if (entry.isDirectory()) {
      await hashDirectory(fullPath, baseDir, hashes);
    } else if (entry.isFile()) {
      hashes[relPath] = await hashFile(fullPath);
    }
  }
  return hashes;
}

module.exports = { hashDirectory };
