#!/usr/bin/env node
const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');
const { chatCompletions } = require('./llamacpp.js');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = { model: '', prompt: '', file: '', maxResolution: '' };
  for (let i = 0; i < args.length; i++) {
    if ((args[i] === '-m' || args[i] === '--model') && args[i + 1]) out.model = args[++i];
    else if ((args[i] === '-p' || args[i] === '--prompt') && args[i + 1]) out.prompt = args[++i];
    else if ((args[i] === '-f' || args[i] === '--file') && args[i + 1]) out.file = args[++i];
    else if ((args[i] === '--max-resolution') && args[i + 1]) out.maxResolution = args[++i];
  }
  return out;
}

function mime(filePath) {
  const ext = filePath.toLowerCase().split('.').pop();
  const map = { png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', webp: 'image/webp', gif: 'image/gif' };
  return map[ext] || 'image/jpeg';
}

function maybeResize(filePath, maxResolution) {
  if (!maxResolution) return filePath;
  const tmpPath = `/tmp/llamacpp-vision-${Date.now()}-${path.basename(filePath)}`;
  execSync(`magick "${filePath}" -resize "${maxResolution}" "${tmpPath}"`, { stdio: 'pipe' });
  return tmpPath;
}

async function main() {
  const { model, prompt, file, maxResolution } = parseArgs();
  if (!model || !prompt || !file) {
    console.error('Usage: chat-vision.js -m MODEL -p PROMPT -f IMAGE_PATH [--max-resolution WxH]');
    process.exit(1);
  }
  if (!fs.existsSync(file)) {
    console.error('File not found:', file);
    process.exit(1);
  }

  const resolvedFile = maybeResize(file, maxResolution);
  try {
    const b64 = fs.readFileSync(resolvedFile).toString('base64');
    const url = `data:${mime(resolvedFile)};base64,${b64}`;

    const body = {
      model,
      messages: [
        { role: 'user', content: [{ type: 'text', text: prompt }, { type: 'image_url', image_url: { url } }] },
      ],
      stream: false,
      max_tokens: 512,
    };

    const data = await chatCompletions(body);
    if (data.choices?.[0]?.message?.content) {
      console.log(data.choices[0].message.content);
    } else if (data.error?.message) {
      console.error(data.error.message);
      process.exit(1);
    }
  } finally {
    if (maxResolution && fs.existsSync(resolvedFile)) {
      fs.unlinkSync(resolvedFile);
    }
  }
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
