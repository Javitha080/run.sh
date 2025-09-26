#!/bin/bash
# colab_experiment.sh
# Best-effort experimental installer for ephemeral containers (Colab)
# DOES NOT bypass Colab runtime limits. Use only for short experiments.

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "===== colab_experiment.sh started ====="

# Step 0: quick checks
if [ "$(id -u)" -ne 0 ]; then
  echo "WARNING: Not running as root. Please run with sudo. Exiting."
  exit 1
fi

echo "Updating apt..."
apt-get update -y

echo "Installing a minimal set of packages that usually work in containers..."
# We avoid packages that strongly require systemd to function during install
apt-get install -y --no-install-recommends \
    wget curl git ca-certificates \
    xvfb x11vnc x11-utils xbase-clients \
    xfce4 xfce4-terminal dbus-x11 \
    python3 python3-pip fonts-lklug-sinhala \
    libgbm1 libfuse2 || true

echo "Cloning target repo..."
git clone https://github.com/ravindu644/LinuxRDP.git /opt/LinuxRDP || true
ls -la /opt/LinuxRDP || true

# Inspect run.sh (for your info)
echo "---- start run.sh (first 200 lines) ----"
sed -n '1,200p' /opt/LinuxRDP/run.sh || true
echo "---- end run.sh ----"

# Try to install chrome-remote-desktop package (may not fully work w/o systemd)
CRD_DEB="/tmp/chrome-remote-desktop_current_amd64.deb"
echo "Downloading Chrome Remote Desktop .deb (might fail to run as service in containers)..."
wget -q -O "$CRD_DEB" "https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb" || true
dpkg -i "$CRD_DEB" || true
apt-get install -f -y || true

echo "IMPORTANT:"
echo " - If CRD installed, headless auth still needs the command you get from:"
echo "   https://remotedesktop.google.com/headless"
echo " - Open the above URL in your browser, authenticate with the Google account you want to use,"
echo "   copy the full auth command it shows (it will start with /opt/google/chrome-remote-desktop/start-host ...)"
echo " - Then run that full command in this container (example below)."

cat <<'EOF'

EXAMPLE: Run the CRD auth command after you copy it from the web page:

# replace the example below with the exact command you received from remotedesktop.google.com/headless
CRD_CMD="/opt/google/chrome-remote-desktop/start-host --code=4/..long..token.. --redirect-url=https://remotedesktop.google.com/_/oauthredirect --name=colab-host"
# THEN run:
bash -c "$CRD_CMD --pin=123456"

EOF

echo "If you want to create a local test user in this container for GUI, run:"
echo "  useradd -m -s /bin/bash testuser && echo 'testuser:password' | chpasswd && adduser testuser sudo"

echo "NOTE: systemctl and persistent services are not available in typical Colab runtimes."
echo "This script finishes now. Use it only for experiments. Expect to re-run after disconnect."

echo "===== colab_experiment.sh finished ====="
