#!/usr/bin/env node
const fs = require('fs');
const os = require('os');
const path = require('path');

const logFile = path.join(os.homedir(), 'Applications/llamacpp/llamacpp-server.log');
const n = parseInt(process.argv[2], 10) || 80;

if (fs.existsSync(logFile)) {
  const lines = fs.readFileSync(logFile, 'utf8').split('\n');
  const tail = lines.slice(-n);
  console.log(tail.join('\n'));
} else {
  const { execSync } = require('child_process');
  try {
    const out = execSync(`journalctl --user -u llamacpp-server.service -n ${n} --no-pager`, {
      encoding: 'utf8',
      maxBuffer: 1024 * 1024,
    });
    console.log(out);
  } catch (e) {
    console.log('No log file at', logFile, 'and journalctl has no entries.');
  }
}
