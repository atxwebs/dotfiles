#!/bin/bash
# Show running models (mimics 'ollama ps')
# Filters out ggml-vocab-* tokenizer-only files

curl -s http://127.0.0.1:58261/v1/models | python3 -c "
import sys, json
data = json.load(sys.stdin)
# Filter out ggml-vocab-* files (tokenizer-only files)
loaded = [m for m in data['data'] if m['status']['value'] == 'loaded' and not m['id'].startswith('ggml-vocab-') and not m['id'].startswith('mmproj-')]
if not loaded:
    print('No models loaded')
    sys.exit(0)
print(f'{\"NAME\":<40} {\"SIZE\":<12} {\"VRAM\":<10}')
print('-' * 62)
for m in loaded:
    name = m['id'][:38] + '..' if len(m['id']) > 40 else m['id']
    print(f'{name:<40} {\"-\":<12} {\"-\":<10}')
"
