#!/usr/bin/env python3
"""
Remove a model from llama.cpp models dir and preset file.

Mimics `ollama rm` but for llama.cpp router mode.

USAGE:
    remove-model.py <model_slug>

EXAMPLES:
    remove-model.py Qwen3.5-9B-UD-IQ3_XXS
    remove-model.py qwen2.5-coder-1.5b-iq3_xxs-imat
    remove-model.py MyCustomModel

Removes:
    - Model GGUF file from ~/Applications/llamacpp/models/
    - Model section from models.ini preset file
    - Associated .inp and .out test files (if any)

NOTES:
    - Safely handles missing GGUF files (just removes preset entry)
    - Model must be unloaded before removal (auto-unloads after 5min idle)
    - Server reloads presets automatically on next request (no restart needed)
"""

import os
import re
import sys
from pathlib import Path

# Configuration
OUT_DIR = Path(os.environ.get('LLAMACPP_MODELS', Path.home() / 'Applications' / 'llamacpp' / 'models'))
PRESET_FILE = OUT_DIR / 'models.ini'


def remove_model(model_slug: str) -> None:
    """Remove a model by slug."""
    model_file = OUT_DIR / f'{model_slug}.gguf'
    
    # Remove GGUF file if it exists
    if model_file.exists():
        model_file.unlink()
        print(f'Removed: {model_file}')
    else:
        print(f'Warning: GGUF file not found: {model_file}', file=sys.stderr)
    
    # Remove associated test files (.inp, .out)
    for ext in ['inp', 'out']:
        test_file = model_file.with_suffix(f'.gguf.{ext}')
        if test_file.exists():
            test_file.unlink()
            print(f'Removed: {test_file}')
    
    # Remove from preset file
    if PRESET_FILE.exists():
        content = PRESET_FILE.read_text()
        pattern = r'^\[' + re.escape(model_slug) + r'\].*?(?=^\[|\Z)'
        new_content = re.sub(pattern, '', content, flags=re.MULTILINE | re.DOTALL)
        new_content = re.sub(r'\n{3,}', '\n\n', new_content)
        PRESET_FILE.write_text(new_content)
        print(f'Removed preset entry for: {model_slug}')
    else:
        print(f'Warning: Preset file not found: {PRESET_FILE}', file=sys.stderr)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: remove-model.py <model_slug>', file=sys.stderr)
        print('Example: remove-model.py Qwen3.5-9B-UD-IQ3_XXS', file=sys.stderr)
        sys.exit(1)
    
    remove_model(sys.argv[1])
