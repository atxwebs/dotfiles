#!/bin/bash
set -e
# Ensure llama-server is enabled and running
systemctl --user enable llamacpp-server.service
systemctl --user start llamacpp-server.service
sleep 2
curl -s http://127.0.0.1:58261/health && echo " OK" || echo " FAILED"
