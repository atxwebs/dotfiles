#!/usr/bin/env node
const { chatCompletions } = require('./llamacpp.js');

const TOOLS = [
  {
    type: 'function',
    function: {
      name: 'get_weather',
      description: 'Get the current weather',
      parameters: { type: 'object', properties: { location: { type: 'string' } }, required: ['location'] },
    },
  },
];

async function main() {
  const model = process.argv[2] || 'Qwen3.5-9B__UD-Q4_K_XL';
  const body = {
    model,
    messages: [{ role: 'user', content: 'What is the weather in Paris? Use the tool.' }],
    tools: TOOLS,
    tool_choice: 'auto',
    stream: false,
    parse_tool_calls: true,
    max_tokens: 512,
  };

  console.log('Request (model=%s)...', model);
  const data = await chatCompletions(body);
  const msg = data.choices?.[0]?.message || {};
  const content = msg.content || '';
  console.log(
    JSON.stringify(
      {
        content: msg.content,
        tool_calls: msg.tool_calls,
        reasoning: msg.reasoning_content,
        has_think_tags: /<think>|</think>/.test(content),
      },
      null,
      2
    )
  );
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
