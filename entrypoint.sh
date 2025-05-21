#!/bin/bash

# Default VNC display is :1, which corresponds to port 5901
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT_DEFAULT="6080"

# Use Railway's assigned port for noVNC, or default to 6080
# Railway typically sets the PORT environment variable
NOVNC_PORT=${PORT:-$NOVNC_PORT_DEFAULT}

# Set VNC password if VNC_PASSWORD environment variable is set, otherwise no password
VNC_SECURITY_OPTIONS="-SecurityTypes None --I-KNOW-THIS-IS-INSECURE"
if [ -n "$VNC_PASSWORD" ]; then
  echo "Setting VNC password."
  mkdir -p /root/.vnc
  echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
  chmod 600 /root/.vnc/passwd
  VNC_SECURITY_OPTIONS="-SecurityTypes VncAuth -PasswordFile /root/.vnc/passwd"
else
  echo "No VNC_PASSWORD set, VNC will start without a password."
fi

# Start VNC server
echo "Starting VNC server on display ${VNC_DISPLAY} (port ${VNC_PORT})"
# -localhost no: Allows connections from non-localhost (i.e., websockify)
# -fg: Runs in the foreground (optional, but can be useful for debugging; remove if causing issues with tini)
# Added -desktop and -depth for better compatibility
vncserver ${VNC_DISPLAY} -localhost no ${VNC_SECURITY_OPTIONS} -geometry 1024x768 -depth 24 -desktop "XFCE on Docker" -fg &
VNC_PID=$!
sleep 2 # Give VNC server a moment to start

# Generate self-signed certificate for websockify (HTTPS for noVNC) if it doesn't exist
CERT_DIR="/root/.certs"
CERT_PEM="${CERT_DIR}/self.pem"
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_PEM" ]; then
  echo "Generating self-signed SSL certificate for noVNC at ${CERT_PEM}"
  openssl req -new -subj "/C=US/ST=CA/L=Railway/O=User/CN=localhost" -x509 -days 365 -nodes -out "${CERT_PEM}" -keyout "${CERT_PEM}"
else
  echo "Using existing SSL certificate at ${CERT_PEM}"
fi

# Start websockify to bridge noVNC to the VNC server
echo "Starting noVNC websockify proxy on port ${NOVNC_PORT} to VNC localhost:${VNC_PORT}"
# -D: Run as daemon (optional, remove if you want it in foreground for debugging with tini)
# --web=/usr/share/novnc/: Path to noVNC web files
# --cert=${CERT_PEM}: Path to SSL certificate
# ${NOVNC_PORT}: External port websockify listens on (from $PORT or default)
# localhost:${VNC_PORT}: Target VNC server
/usr/bin/websockify --web=/usr/share/novnc/ --cert="${CERT_PEM}" "${NOVNC_PORT}" "localhost:${VNC_PORT}" &
WEBSOCKIFY_PID=$!

# Optional: Start SSH server if you need it
# /usr/sbin/sshd -D &
# SSHD_PID=$!

echo "----------------------------------------------------"
echo "VNC and noVNC services started."
echo "VNC Server (internal): localhost:${VNC_PORT} (Display ${VNC_DISPLAY})"
if [ -n "$VNC_PASSWORD" ]; then
  echo "VNC Password: Set via VNC_PASSWORD environment variable"
else
  echo "VNC Password: Not set (SecurityTypes None)"
fi
echo "noVNC (Web Access): Connect via https://<your-railway-app-url>"
echo "(Your Railway app URL will point to container port ${NOVNC_PORT})"
echo "You might see a browser warning for self-signed certificate. Please accept it to proceed."
echo "----------------------------------------------------"

# Wait for any process to exit
wait -n $VNC_PID $WEBSOCKIFY_PID # Add $SSHD_PID if you uncomment sshd start

# If any of the main processes exit, bring down the container
exit $?
