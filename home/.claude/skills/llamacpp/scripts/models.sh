#!/bin/bash
# List all models (mimics 'ollama list')

curl -s http://127.0.0.1:58261/v1/models | python3 -c "
import sys, json
data = json.load(sys.stdin)
models = data['data']
if not models:
    print('No models available')
    sys.exit(0)
print(f'{\"NAME\":<40} {\"STATUS\":<12}')
print('-' * 52)
for m in sorted(models, key=lambda x: x['id']):
    name = m['id'][:38] + '..' if len(m['id']) > 40 else m['id']
    status = m['status']['value']
    print(f'{name:<40} {status:<12}')
"
