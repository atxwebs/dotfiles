#!/usr/bin/env python3
"""Clean HuggingFace cache after model download to save disk space."""

import shutil
from pathlib import Path


def clean_hf_cache():
    """Remove HF cache files after successful download."""
    hf_cache = Path.home() / ".cache" / "huggingface" / "hub"
    
    if not hf_cache.exists():
        print("HF cache directory not found")
        return
    
    total_freed = 0
    
    # Remove model directories (these contain full copies)
    model_dirs = [d for d in hf_cache.glob("models--*") if d.is_dir()]
    if model_dirs:
        for d in model_dirs:
            try:
                dir_size = sum(f.stat().st_size for f in d.rglob("*") if f.is_file())
                total_freed += dir_size
                shutil.rmtree(d)
            except Exception as e:
                print(f"Warning: Could not delete {d}: {e}")
    
    # Remove blob files
    blobs = list(hf_cache.glob("blobs/*"))
    if blobs:
        for f in blobs:
            try:
                total_freed += f.stat().st_size
                f.unlink()
            except Exception as e:
                print(f"Warning: Could not delete {f}: {e}")
    
    # Remove snapshot directories
    for snapshot_dir in hf_cache.glob("snapshots/*"):
        if snapshot_dir.is_dir():
            try:
                shutil.rmtree(snapshot_dir)
            except:
                pass
    
    # Remove lock files
    locks_dir = hf_cache / ".locks"
    if locks_dir.exists():
        try:
            shutil.rmtree(locks_dir)
        except:
            pass
    
    # Report
    if total_freed > 0:
        print(f"HF cache cleaned: {total_freed / 1024 / 1024 / 1024:.2f} GB freed")
    else:
        print("HF cache already clean")


if __name__ == "__main__":
    clean_hf_cache()
