#!/usr/bin/env node
const { execSync } = require('child_process');
const { health } = require('./llamacpp.js');

function run(cmd, opts = {}) {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: 'pipe', ...opts });
  } catch (e) {
    if (opts.ignoreError) return '';
    throw e;
  }
}

async function main() {
  console.log('Stopping llamacpp-server...');
  run('systemctl --user stop llamacpp-server.service', { ignoreError: true });

  console.log('Killing all llama-server processes...');
  run('pkill -9 -f "llama-server"', { ignoreError: true });
  await new Promise((r) => setTimeout(r, 2000));

  console.log('Starting llamacpp-server...');
  run('systemctl --user start llamacpp-server.service');
  await new Promise((r) => setTimeout(r, 4000));

  try {
    const ok = await health();
    console.log(ok ? 'OK' : 'FAILED');
  } catch (e) {
    console.log('FAILED', e.message);
  }
}

main();
