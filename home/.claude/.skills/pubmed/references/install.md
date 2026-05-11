# OpenMed Install

## Run

```bash
git clone https://github.com/rovetia/pubmed.git
cd pubmed
docker compose up -d
```

Port **18080** (gateway). OpenMed runs behind a gateway that auto-stops it when idle to free VRAM for Ollama/TabbyAPI.

## Architecture

- **gateway** (18080): Python proxy. Stops container after 5 min idle. On model switch: unload first. Exposes `POST /unload`.
- **openmed**: GPU service, no direct port exposure. Started/stopped by gateway.

## PUBMED_HOST (API env)

- `PUBMED_HOST`: Base URL (e.g. `http://localhost:18080` local, `http://home.rovetia.com:18080` remote). Unload POSTs to `{PUBMED_HOST}/unload`.

## Gateway env (docker-compose or .env)

- `OPENMED_RESTART_KEY`: Optional. If set, `/unload` requires `Authorization: Bearer <key>` or `X-OpenMed-Restart-Key: <key>`.
- `IDLE_MINUTES`: Minutes of inactivity before stopping (default 5).

## Prerequisites

**nvidia-container-toolkit** (for GPU passthrough):

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Config

- `OPENMED_PROFILE`: gpu (uses custom profile with device=cuda)
- `OPENMED_SERVICE_PRELOAD_MODELS`: unset = no preload
