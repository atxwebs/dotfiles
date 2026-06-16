# llama.cpp Upgrade Guide

**Last tested:** 2026-04-13 | **RTX 4070 Laptop (8GB)** | **CUDA 12.6**

---

## Quick Upgrade (Recommended)

```bash
cd ~/Applications/llamacpp

# 1. Update source
git pull origin master

# 2. Clean old build (prevents conflicts)
rm -rf build/

# 3. Configure with CUDA (disable NCCL to avoid initialization errors)
cmake -B build -DGGML_CUDA=ON -DGGML_CUDA_NCCL=OFF -DCMAKE_BUILD_TYPE=Release

# 4. Build (use all cores)
cmake --build build --config Release -j$(nproc)

# 5. Restart server
systemctl --user restart llamacpp-server.service

# 6. Verify
curl -s http://127.0.0.1:58261/health && echo " ✅ OK"
```

**Total time:** ~5-10 minutes (depending on CPU)

---

## Why Disable NCCL?

NCCL (NVIDIA Collective Communications Library) causes initialization errors on single-GPU laptop setups:

```
CUDA error: unhandled cuda error
ncclCommInitAll(info.comms, info.device_count, dev_ids)
```

**Solution:** `-DGGML_CUDA_NCCL=OFF`

NCCL is only needed for multi-GPU distributed training. For single-GPU inference, it's unnecessary overhead.

---

## Complete Rebuild (If Issues)

If you encounter strange errors after upgrade:

```bash
cd ~/Applications/llamacpp

# Stop server first
systemctl --user stop llamacpp-server.service

# Complete clean
rm -rf build/ .cache/

# Fresh build
cmake -B build -DGGML_CUDA=ON -DGGML_CUDA_NCCL=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(nproc)

# Restart
systemctl --user start llamacpp-server.service
sleep 5
curl -s http://127.0.0.1:58261/health
```

---

## Build Configuration Explained

|Flag|Value|Why|
|---|---|---|
|`-DGGML_CUDA=ON`|Required|Enable NVIDIA GPU acceleration|
|`-DGGML_CUDA_NCCL=OFF`|**Critical**|Prevents CUDA initialization errors on single-GPU|
|`-DCMAKE_BUILD_TYPE=Release`|Required|Optimized build (10x faster than Debug)|
|`-j$(nproc)`|Recommended|Parallel build (uses all CPU cores)|

### Optional Flags (Not Needed)

- `~~-DGGML_BLAS=ON~~` - CPU BLAS (useless with full GPU offload)
- `~~-DGGML_METAL=ON~~` - macOS only
- `~~-DGGML_VULKAN=ON~~` - AMD/Intel GPUs
- `~~-DBUILD_SHARED_LIBS=OFF~~` - Static libs (not needed for server)

---

## Post-Upgrade Checklist

```bash
# 1. Check version
~/Applications/llamacpp/build/bin/llama-cli --version

# 2. Verify server health
curl -s http://127.0.0.1:58261/health

# 3. Test model loading
curl -s -X POST http://127.0.0.1:58261/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gemma-4-E4B-it-UD-Q5_K_XL", "messages": [{"role": "user", "content": "Hi"}], "max_tokens": 5}'

# 4. Check VRAM (should be ~5.5GB for Gemma-4)
nvidia-smi --query-gpu=memory.used --format=csv,noheader
```

---

## Common Issues & Solutions

### Issue: "CUDA error: unhandled cuda error"
**Cause:** NCCL trying to initialize multi-GPU communication  
**Fix:** Rebuild with `-DGGML_CUDA_NCCL=OFF`

### Issue: "unknown model architecture: 'gemma4'"
**Cause:** Outdated llama.cpp version  
**Fix:** `git pull` and rebuild (Gemma 4 support added in build 75f3bc9+)

### Issue: Model stuck in "loading" state
**Cause:** Build incomplete or server using old binary  
**Fix:** 
```bash
systemctl --user stop llamacpp-server.service
rm -rf build/
cmake -B build -DGGML_CUDA=ON -DGGML_CUDA_NCCL=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(nproc)
systemctl --user start llamacpp-server.service
```

### Issue: mmproj not loading for vision
**Cause:** Relative path in models.ini  
**Fix:** Use absolute path in preset:
```ini
[gemma-4-E4B-it-UD-Q5_K_XL]
mmproj = ~/Applications/llamacpp/models/mmproj-BF16.gguf
```

### Issue: Server won't start after build
**Cause:** systemd still running old binary  
**Fix:**
```bash
systemctl --user daemon-reload
systemctl --user restart llamacpp-server.service
journalctl --user -u llamacpp-server.service -n 50
```

---

## Performance Tips

### Faster Compilation
Install ccache for 3-5x faster rebuilds:
```bash
sudo apt install ccache
cmake -B build -DGGML_CUDA=ON -DGGML_CUDA_NCCL=OFF -DCMAKE_BUILD_TYPE=Release -DGGML_CCACHE=ON
```

### Keep Build Artifacts
Don't delete `build/` between upgrades unless you have issues. Incremental builds are much faster.

### Monitor Build Progress
```bash
watch -n 1 'ps aux | grep cmake | grep -v grep'
```

---

## Model-Specific Notes

### Gemma 4 Support
- **Minimum version:** 75f3bc9 (2026-04-13)
- **VRAM required:** ~5.5GB (Q5_K_XL quantization)
- **mmproj needed:** Yes, for vision (mmproj-BF16.gguf)
- **Config in models.ini:**
```ini
[gemma-4-E4B-it-UD-Q5_K_XL]
mmproj = ~/Applications/llamacpp/models/mmproj-BF16.gguf
```

### Vision Models
All multimodal models need mmproj files. Download with:
```bash
~/.claude/skills/llamacpp/scripts/hf.py --mmproj <repo> <quant>
```

---

## Rollback Procedure

If new build breaks something:

```bash
# Stop server
systemctl --user stop llamacpp-server.service

# Checkout previous known-good version
cd ~/Applications/llamacpp
git checkout 90aa83c  # or any known-good commit

# Rebuild
rm -rf build/
cmake -B build -DGGML_CUDA=ON -DGGML_CUDA_NCCL=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j$(nproc)

# Restart
systemctl --user start llamacpp-server.service
```

---

## System Requirements

|Component|Minimum|Recommended|
|---|---|---|
|GPU|NVIDIA 6GB+|NVIDIA 8GB+ (RTX 4070)|
|CUDA|12.0+|12.6+|
|RAM|16GB|32GB+|
|Disk|20GB free|50GB free|
|CPU|4 cores|8+ cores (faster builds)|

---

## Quick Reference Commands

```bash
# Check current version
cd ~/Applications/llamacpp && git log -1 --oneline

# Check for updates
git fetch origin && git log HEAD..origin/master --oneline | head -10

# Check available models
~/.claude/skills/llamacpp/scripts/models.sh

# Check loaded models
~/.claude/skills/llamacpp/scripts/ps.sh

# View server logs (last 100 lines)
~/.claude/skills/llamacpp/scripts/logs.js 100

# Restart server
~/.claude/skills/llamacpp/scripts/restart.sh

# Monitor VRAM
watch -n 2 'nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader'
```

---

## Update Frequency

- **Weekly:** Good balance (new features, stable)
- **Monthly:** Conservative (well-tested builds)
- **As needed:** Only when you need specific model support

**Tip:** Check commit messages for model support additions before upgrading.

---

**Maintained by:** Ariel Flesler  
**Hardware:** RTX 4070 Laptop (8GB VRAM), CUDA 12.6  
**OS:** Linux (Ubuntu-based)
