#!/usr/bin/env bash

# Messages for logging
echo "[INFO] Shutdown requested at: $(date)"
echo "[INFO] System will halt in 1 minute"

# Shut down in 1 minute
sudo shutdown -h +1