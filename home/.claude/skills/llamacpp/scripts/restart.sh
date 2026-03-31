#!/bin/bash
set -e
# Restart llama.cpp server via systemd

systemctl --user restart llamacpp-server.service
sleep 2
curl -s http://127.0.0.1:58261/health && echo " OK" || echo " FAILED"
