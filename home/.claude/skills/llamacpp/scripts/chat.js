#!/usr/bin/env node
const { chatCompletions } = require('./llamacpp.js');

function parseArgs() {
  const args = process.argv.slice(2);
  const out = { model: '', prompt: '', tools: null };
  for (let i = 0; i < args.length; i++) {
    if ((args[i] === '-m' || args[i] === '--model') && args[i + 1]) out.model = args[++i];
    else if ((args[i] === '-p' || args[i] === '--prompt') && args[i + 1]) out.prompt = args[++i];
    else if (args[i] === '--tools' && args[i + 1]) out.tools = JSON.parse(args[++i]);
  }
  return out;
}

async function main() {
  const { model, prompt, tools } = parseArgs();
  if (!model || !prompt) {
    console.error('Usage: chat.js -m MODEL -p PROMPT [--tools JSON]');
    process.exit(1);
  }

  const body = tools
    ? { model, messages: [{ role: 'user', content: prompt }], tools, tool_choice: 'auto', stream: false, max_tokens: 512 }
    : { model, messages: [{ role: 'user', content: prompt }], stream: false, max_tokens: 512 };

  const data = await chatCompletions(body);
  const msg = data.choices?.[0]?.message;
  if (msg?.content) console.log(msg.content);
  else if (msg?.tool_calls) console.log(JSON.stringify(msg.tool_calls));
  else if (data.error?.message) {
    console.error(data.error.message);
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
