#!/bin/bash
# colab_experiment.sh
# Best-effort experimental installer for ephemeral Colab containers
# DOES NOT bypass Colab runtime limits. Use only for short experiments.

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "===== colab_experiment.sh started ====="

# Step 0: quick root check
if [ "$(id -u)" -ne 0 ]; then
  echo "WARNING: Not running as root. Please run with sudo. Exiting."
  exit 1
fi

echo "Updating apt..."
apt-get update -y

echo "Installing a minimal set of packages..."
apt-get install -y --no-install-recommends \
    wget curl git ca-certificates \
    xvfb x11vnc x11-utils xbase-clients \
    xfce4 xfce4-terminal dbus-x11 \
    python3 python3-pip fonts-lklug-sinhala \
    libgbm1 libfuse2 || true

# Step 1: Install Chrome Remote Desktop
CRD_DEB="/tmp/chrome-remote-desktop_current_amd64.deb"
echo "Downloading Chrome Remote Desktop..."
wget -q -O "$CRD_DEB" "https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb" || true
dpkg -i "$CRD_DEB" || true
apt-get install -f -y || true

# Step 2: Setup virtual display (Xvfb) for headless mode
export DISPLAY=:1
echo "Starting Xvfb on $DISPLAY..."
Xvfb $DISPLAY -screen 0 1920x1080x24 &

# Step 3: Optional - launch XFCE4 desktop in background
echo "Starting XFCE4 desktop environment..."
xfce4-session &

# Step 4: Run Chrome Remote Desktop host
# Replace the --code value with your own from https://remotedesktop.google.com/headless
CRD_CODE="4/0AVGzR1DJrJALS4EnYI5oSJ0rJcZWZVODGn5yvRK2V8u68gEbotpiyUVJLUuv-EAIjDCgfg"
CRD_NAME="Colab-VM"

echo "Starting Chrome Remote Desktop host..."
/opt/google/chrome-remote-desktop/start-host \
  --code="$CRD_CODE" \
  --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
  --name="$CRD_NAME" \
  --pin=123456 &

echo "===== Chrome Remote Desktop is launching ====="
echo "Connect via https://remotedesktop.google.com/access using PIN: 123456"

