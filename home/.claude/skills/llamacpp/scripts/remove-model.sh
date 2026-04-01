#!/bin/bash
# Remove a model from llama.cpp models dir and preset file.
#
# USAGE:
#   remove-model.sh <model_slug>
#
# EXAMPLES:
#   remove-model.sh qwen2.5-coder-1.5b-iq3_xxs-imat
#   remove-model.sh Qwen3.5-9B-UD-IQ3_XXS
#
# Removes:
#   - Model GGUF file from ~/Applications/llamacpp/models/
#   - Model section from models.ini preset file
#   - Associated .inp and .out test files (if any)

set -e

model="${1:?Usage: remove-model.sh <model_slug>}"

OUT_DIR="${LLAMACPP_MODELS:-$HOME/Applications/llamacpp/models}"
PRESET_FILE="$OUT_DIR/models.ini"

# Find the model file
model_file="$OUT_DIR/${model}.gguf"

if [ ! -f "$model_file" ]; then
  echo "Model not found: $model" >&2
  exit 1
fi

# Remove GGUF file
rm -f "$model_file"

# Remove associated test files (.inp, .out)
for ext in inp out; do
  test_file="${model_file}.${ext}"
  [ -f "$test_file" ] && rm -f "$test_file"
done

# Remove from preset file
if [ -f "$PRESET_FILE" ]; then
  python3 << 'PYTHON_SCRIPT'
import re
with open('$PRESET_FILE', 'r') as f:
    content = f.read()
pattern = r'^\[' + re.escape('$model') + r'\].*?(?=^\[|\Z)'
new_content = re.sub(pattern, '', content, flags=re.MULTILINE | re.DOTALL)
new_content = re.sub(r'\n{3,}', '\n\n', new_content)
with open('$PRESET_FILE', 'w') as f:
    f.write(new_content)
PYTHON_SCRIPT
fi
