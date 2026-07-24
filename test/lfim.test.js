const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const TEST_DIR = path.join(__dirname, 'temp_test_dir');

// Setup
if (fs.existsSync(TEST_DIR)) {
  fs.rmSync(TEST_DIR, { recursive: true, force: true });
}
fs.mkdirSync(TEST_DIR);
fs.writeFileSync(path.join(TEST_DIR, 'file1.txt'), 'hello world');
fs.writeFileSync(path.join(TEST_DIR, 'file2.txt'), 'test data');

console.log('Running LFIM Test Suite...');

try {
  // Test 1: init should create state file
  console.log('Test 1: init');
  execSync(`node src/index.js init ${TEST_DIR}`, { stdio: 'pipe' });
  const stateFile = path.join(TEST_DIR, '.lfim-state.json');
  assert.ok(fs.existsSync(stateFile), 'State file should exist after init');

  // Test 2: check should pass with no changes
  console.log('Test 2: check (clean)');
  execSync(`node src/index.js check ${TEST_DIR}`, { stdio: 'pipe' });
  
  // Test 3: check should fail after modification
  console.log('Test 3: check (drift)');
  fs.writeFileSync(path.join(TEST_DIR, 'file1.txt'), 'hello modified world');
  try {
    execSync(`node src/index.js check ${TEST_DIR}`, { stdio: 'pipe' });
    assert.fail('Check should have exited with non-zero code upon drift');
  } catch (err) {
    assert.ok(err.status !== 0, 'Drift detected successfully');
  }

  console.log('✅ All tests passed!');
} catch (err) {
  console.error('❌ Test failed:', err.message);
  process.exit(1);
} finally {
  // Teardown
  if (fs.existsSync(TEST_DIR)) {
    fs.rmSync(TEST_DIR, { recursive: true, force: true });
  }
}
