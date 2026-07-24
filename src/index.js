const { saveState, loadState } = require('./state');
const { hashDirectory } = require('./engine');
const path = require('path');

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  const targetDir = args[1] ? path.resolve(args[1]) : process.cwd();

  if (!['init', 'check'].includes(command)) {
    console.error('Usage: lfim <init|check> [directory]');
    process.exit(1);
  }

  try {
    if (command === 'init') {
      console.log(`Initializing LFIM baseline for: ${targetDir}`);
      const hashes = await hashDirectory(targetDir);
      saveState(targetDir, hashes);
      console.log(`✅ Baseline saved. Tracked ${Object.keys(hashes).length} files.`);
    } else if (command === 'check') {
      console.log(`Checking LFIM integrity for: ${targetDir}`);
      const baseline = loadState(targetDir);
      if (!baseline) {
        console.error('❌ No state found. Run "lfim init" first.');
        process.exit(1);
      }

      const currentHashes = await hashDirectory(targetDir);
      let driftDetected = false;

      // Check for modified or deleted files
      for (const [file, baselineHash] of Object.entries(baseline)) {
        if (!currentHashes[file]) {
          console.error(`❌ DRIFT DETECTED: File deleted -> ${file}`);
          driftDetected = true;
        } else if (currentHashes[file] !== baselineHash) {
          console.error(`❌ DRIFT DETECTED: File modified -> ${file}`);
          driftDetected = true;
        }
      }

      // Check for new files
      for (const file of Object.keys(currentHashes)) {
        if (!baseline[file]) {
          console.error(`❌ DRIFT DETECTED: File added -> ${file}`);
          driftDetected = true;
        }
      }

      if (driftDetected) {
        console.error('❌ Integrity check failed. Drift detected.');
        process.exit(1);
      } else {
        console.log('✅ Integrity check passed. No drift detected.');
        process.exit(0);
      }
    }
  } catch (err) {
    console.error('❌ Error during execution:', err.message);
    process.exit(1);
  }
}

main();
