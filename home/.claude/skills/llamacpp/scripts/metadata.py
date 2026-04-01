#!/usr/bin/env python3
"""
Show GGUF model metadata.

USAGE:
    metadata.py <model.gguf>              # Show all metadata
    metadata.py --template-only <model>   # Show only chat template
    metadata.py <model> | grep template   # Filter for template
"""

import sys
import argparse
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description='Show GGUF model metadata')
    parser.add_argument('model', help='Model file path or name (without .gguf)')
    parser.add_argument('--template-only', action='store_true',
                       help='Show only chat template')
    return parser.parse_args()


def resolve_model_path(model_name):
    """Resolve model name to full path."""
    model_path = Path(model_name)
    
    # If it's just a name without path separators, look in models dir
    if '/' not in model_name and '\\' not in model_name:
        models_dir = Path.home() / 'Applications' / 'llamacpp' / 'models'
        model_path = models_dir / model_name
    
    # Add .gguf extension if missing (check name, not suffix which could be .5 etc)
    if not model_path.name.endswith('.gguf'):
        model_path = Path(str(model_path) + '.gguf')
    
    return model_path


def show_template_only(model_path):
    """Extract and show only chat template."""
    try:
        from gguf import GGUFReader
        reader = GGUFReader(str(model_path))
        
        found = False
        for field in reader.fields.values():
            if 'chat_template' in field.name:
                found = True
                print(f"{field.name}:")
                if hasattr(field, 'parts'):
                    for part in field.parts:
                        if hasattr(part, 'tolist'):
                            # Convert token IDs to string
                            text = ''.join(chr(c) for c in part.tolist() 
                                         if 32 <= c < 127 or c in [10, 13])
                            print(text)
                        else:
                            print(part)
                print()
        
        if not found:
            print("No chat_template found in metadata", file=sys.stderr)
            sys.exit(1)
            
    except ImportError:
        print("Install: pip install gguf", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def show_all_metadata(model_path):
    """Show all model metadata."""
    try:
        from gguf import GGUFReader
        reader = GGUFReader(str(model_path))
        
        # Basic info
        print(f"Model: {reader.metadata.get('general.name', 'Unknown')}")
        print(f"Architecture: {reader.metadata.get('general.architecture', 'Unknown')}")
        print(f"Parameters: {reader.metadata.get('general.size_label', 'Unknown')}")
        print(f"Quantization: {reader.metadata.get('general.quantized_by', 'Unknown')}")
        print(f"Context Length: {reader.metadata.get('*.context_length', 'Unknown')}")
        print(f"Embedding Length: {reader.metadata.get('*.embedding_length', 'Unknown')}")
        
        # Vocab size
        vocab = reader.metadata.get('tokenizer.ggml.tokens', [])
        if hasattr(vocab, '__len__'):
            print(f"Vocab Size: {len(vocab)}")
        else:
            print(f"Vocab Size: Unknown")
        
        print("\n=== Chat Template ===")
        found = False
        for field in reader.fields.values():
            if 'chat_template' in field.name:
                found = True
                print(f"{field.name}:")
                if hasattr(field, 'parts'):
                    for part in field.parts:
                        if hasattr(part, 'tolist'):
                            text = ''.join(chr(c) for c in part.tolist() 
                                         if 32 <= c < 127 or c in [10, 13])
                            print(text)
                        else:
                            print(part)
                print()
        
        if not found:
            print("(No chat_template found)")
            
    except ImportError:
        print("Install: pip install gguf", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    args = parse_args()
    
    model_path = resolve_model_path(args.model)
    
    if not model_path.exists():
        print(f"Model not found: {model_path}", file=sys.stderr)
        sys.exit(1)
    
    if args.template_only:
        show_template_only(model_path)
    else:
        show_all_metadata(model_path)


if __name__ == "__main__":
    main()
