#!/usr/bin/env python3
"""
Download GGUF from HuggingFace to llama.cpp models dir.
Mimics hf_ollama from ~/.bash_functions but downloads directly to llama.cpp.

USAGE:
    hf.py <owner/project> [quant] [custom_name]

EXAMPLES:
    hf.py unsloth/Qwen3.5-9B-GGUF IQ3_XXS
    hf.py bartowski/Llama-3.2-3B-Instruct-GGUF Q8_0
    hf.py unsloth/Qwen3.5-9B-GGUF:Q4_K_XL
    hf.py unsloth/Qwen3.5-9B-GGUF IQ3_XXS MyCustomName:Tag

Supports:
    - Quantization tag as 2nd arg OR in repo path (owner/project:quant)
    - Optional custom name as 3rd arg (preserves multiple colons)
    - Auto-infers chat template from repo name
    - Downloads ONLY the GGUF file (no tokenizer/config needed)
    - Skips mmproj (multimodal projection) files
    - Auto-downloads mmproj for vision models
    - Cleans HF cache after download

NOTES:
    - GGUF files contain chat_template in metadata (auto-extracted by llama.cpp)
    - Only 1 file needed per model (unlike HF transformers format)
    - Downloads to ~/Applications/llamacpp/models/
"""

import os
import re
import sys
import shutil
from pathlib import Path

# Configuration
OUT_DIR = Path(os.environ.get('LLAMACPP_MODELS', Path.home() / 'Applications' / 'llamacpp' / 'models'))
PRESET_FILE = OUT_DIR / 'models.ini'


def parse_args():
    """Parse command line arguments, skipping ollama/run prefixes."""
    args = sys.argv[1:]
    
    # Skip "ollama" and "run" prefixes (like hf_ollama does)
    if args and args[0] == 'ollama':
        args = args[1:]
    if args and args[0] == 'run':
        args = args[1:]
    
    if len(args) < 1:
        print("Usage: hf.py <owner/project> [quant] [custom_name]")
        print("Example: hf.py unsloth/Qwen3.5-9B-GGUF IQ3_XXS")
        sys.exit(1)
    
    repo = args[0]
    quant = args[1] if len(args) > 1 else None
    custom_name = args[2] if len(args) > 2 else None
    
    # Strip hf.co/ prefix if present
    repo = repo.removeprefix('hf.co/')
    
    # Handle quantization in repo path (e.g., owner/project:quant)
    if ':' in repo and not quant:
        repo, quant = repo.split(':', 1)
    
    if not quant:
        print("Error: quantization tag required")
        print("Usage: hf.py <owner/project> <quant> [custom_name]")
        print("Example: hf.py unsloth/Qwen3.5-9B-GGUF IQ3_XXS")
        sys.exit(1)
    
    return repo, quant, custom_name


def list_repo_files(repo):
    """List files in HF repo."""
    try:
        from huggingface_hub import list_repo_files
        return list_repo_files(repo)
    except Exception:
        import urllib.request
        import json
        r = urllib.request.urlopen(f'https://huggingface.co/api/models/{repo}/tree/main')
        files = [f['path'] for f in json.loads(r.read().decode()) if f.get('type') == 'file']
        return files


def find_gguf(repo, quant):
    """Find GGUF filename matching quant (case-insensitive)."""
    files = list_repo_files(repo)
    quant_upper = quant.upper()
    
    for f in files:
        if f.endswith('.gguf') and quant_upper in f.upper() and 'mmproj' not in f.lower():
            return f
    
    return None


def download_gguf(repo, filename, dest):
    """Download GGUF from HF."""
    if dest.exists():
        print(f"Already exists: {dest}")
        return
    
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {filename} from {repo}...")
    
    try:
        from huggingface_hub import hf_hub_download
        path = hf_hub_download(repo_id=repo, filename=filename)
        shutil.copy(path, dest)
    except Exception as e:
        print(f"Error: {e}")
        print("Install: pip install huggingface_hub")
        sys.exit(1)


def download_mmproj(repo, model_name):
    """Find and download mmproj if available (for vision models)."""
    try:
        files = list_repo_files(repo)
    except Exception:
        return None
    
    # Find mmproj files, prefer smaller quantizations
    mmproj_files = [f for f in files if 'mmproj' in f.lower() and f.endswith('.gguf')]
    if not mmproj_files:
        return None
    
    # Priority order: prefer smaller quantizations
    priority = ['q4_k_s', 'q4_k_m', 'q4_0', 'f16', 'bf16', 'f32']
    mmproj_files.sort(key=lambda x: next((i for i, p in enumerate(priority) if p in x.lower()), 999))
    
    mmproj = mmproj_files[0]
    print(f"Downloading mmproj: {mmproj}")
    
    dest = OUT_DIR / Path(mmproj).name
    if dest.exists():
        print(f"Already exists: {dest}")
        return str(dest)
    
    try:
        from huggingface_hub import hf_hub_download
        path = hf_hub_download(repo_id=repo, filename=mmproj)
        shutil.copy(path, dest)
        return str(dest)
    except Exception as e:
        print(f"Warning: Could not download mmproj: {e}")
        return None


def ensure_preset():
    """Ensure preset has [*] section."""
    if not PRESET_FILE.exists() or not any(line.strip().startswith('[*]') for line in PRESET_FILE.read_text().splitlines()):
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        with open(PRESET_FILE, 'w') as f:
            f.write("; llama.cpp model presets\n")
            f.write("; Chat templates extracted from GGUF metadata automatically\n\n")
            f.write("[*]\n")
            f.write("n-gpu-layers = all\n")
            f.write("jinja = true\n\n")


def add_to_preset(model_base, mmproj_basename=None):
    """
    Add model to preset file.
    
    No template specified - llama.cpp automatically extracts chat_template
    from GGUF metadata, which is always correct for the specific model version.
    """
    ensure_preset()
    
    content = PRESET_FILE.read_text()
    
    # Check if model already in preset
    if re.search(rf'^\[{re.escape(model_base)}\]', content, re.MULTILINE):
        return
    
    # Add to preset (template omitted - uses GGUF metadata)
    with open(PRESET_FILE, 'a') as f:
        f.write(f"[{model_base}]\n")
        if mmproj_basename:
            f.write(f"mmproj = {OUT_DIR}/{mmproj_basename}\n")
        f.write("\n")
    
    print(f"Added to preset: {model_base}")


def clean_hf_cache():
    """Clean HF cache after download."""
    script_dir = Path(__file__).parent
    clean_script = script_dir / 'hf_clean_cache.py'
    
    if clean_script.exists():
        import subprocess
        subprocess.run([sys.executable, str(clean_script)], check=False)
    else:
        # Inline cleanup if script not found
        hf_cache = Path.home() / ".cache" / "huggingface" / "hub"
        if hf_cache.exists():
            import shutil
            for pattern in ["models--*", "blobs/*", "snapshots/*", ".locks"]:
                for item in hf_cache.glob(pattern):
                    try:
                        if item.is_dir():
                            shutil.rmtree(item)
                        else:
                            item.unlink()
                    except:
                        pass


def main():
    repo, quant, custom_name = parse_args()
    
    # Find and download GGUF
    filename = find_gguf(repo, quant)
    if not filename:
        print(f"No GGUF matching quant '{quant}' in {repo}")
        sys.exit(1)
    
    base = Path(filename).name
    model_base_raw = base[:-5]  # Remove .gguf
    
    # Determine final model name
    if custom_name:
        model_base = custom_name
    else:
        # Remove suffixes like hf_ollama does
        model_base = re.sub(r'-(instruct|thinking|GGUF)', '', model_base_raw, flags=re.IGNORECASE)
    
    dest = OUT_DIR / f"{model_base}.gguf"
    
    download_gguf(repo, filename, dest)
    
    # Download mmproj if available (for vision models)
    mmproj_path = download_mmproj(repo, model_base)
    mmproj_basename = Path(mmproj_path).name if mmproj_path and Path(mmproj_path).exists() else None
    if mmproj_basename:
        print(f"Downloaded mmproj: {mmproj_basename}")
    
    # Add to preset (no template - llama.cpp uses embedded GGUF metadata)
    add_to_preset(model_base, None, mmproj_basename)
    
    print(f"\nDone: {dest}")
    if mmproj_basename:
        print(f"Vision model with mmproj: {mmproj_basename}")
    
    # Clean HF cache
    print()
    clean_hf_cache()
    
    print("\nModel will be available in router mode")
    print("Restart server to reload presets: systemctl --user restart llamacpp-server.service")


if __name__ == "__main__":
    main()
