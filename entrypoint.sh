#!/bin/bash
echo " "
echo "Starting container initialization..."

# Set resolution and password with default fallback
RESOLUTION=${RESOLUTION:-"680x820"}
PASSWORD=${PASSWORD:-"password"}
export USER=root
echo "root:$PASSWORD" | chpasswd

echo " "
echo "Setting up VNC with Resolution: $RESOLUTION and Password: (hidden for security)"

# Ensure .Xresources exists
if [ ! -f /root/.Xresources ]; then
    echo " "
    echo "Creating a default '/root/.Xresources' with basic customization..."
    echo "*customization: -color" > /root/.Xresources
else
    echo " "
    echo "Found existing '/root/.Xresources'. No changes made."
fi

# Setup VNC password
echo " "
echo "Ensuring VNC configuration files are properly set up..."
mkdir -p /root/.vnc
echo -e "$PASSWORD\n$PASSWORD\n" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
echo "VNC password file created and permissions secured."

# Setup xstartup for XFCE
cat << EOF > /root/.vnc/xstartup
#!/bin/sh
xrdb \$HOME/.Xresources
startxfce4 &
EOF
chmod +x /root/.vnc/xstartup
echo "VNC xstartup script created and made executable."

# SSH
echo " "
echo "Starting SSH service..."
service ssh restart

# Kill existing VNC processes
echo " "
echo "Stopping any existing VNC server processes..."
pkill -f "Xvnc" || echo "No existing VNC processes found."

# Remove stale locks
echo " "
echo "Checking for and removing stale VNC lock and temporary files..."
rm -f /tmp/.X1-lock 2>/dev/null
rm -rf /tmp/.X11-unix 2>/dev/null

# Start VNC server
echo " "
echo "Starting VNC server on display :1 with geometry $RESOLUTION and 16-bit depth..."
vncserver :1 -geometry "$RESOLUTION" -depth 16

echo " "
echo "Initialization complete. Container is now ready."

# Keep container alive
tail -f /dev/null
