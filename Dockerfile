# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set environment variable to suppress interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure keyboard layout to English (US)
RUN echo 'keyboard-configuration keyboard-configuration/layoutcode select us' | debconf-set-selections

# Change APT mirror to Vietnam mirror FIRST, then update and upgrade
# This is crucial if you are facing 403 Forbidden errors
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://vn.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's|http://security.ubuntu.com/ubuntu/|http://vn.archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update -o Acquire::Retries=3 -o Acquire::http::Timeout="60" && \
    apt-get upgrade -y

# Install packages (list cleaned up)
RUN apt-get install -y --no-install-recommends \
    xfce4-session xfwm4 xfce4-panel \
    tightvncserver xfonts-base xfonts-75dpi xfonts-100dpi \
    gnome-keyring seahorse openssh-server \
    dbus dbus-x11 thunar xterm \
    sudo wget curl nano gnupg gdebi util-linux uuid-runtime \
    apt-transport-https \
    xautomation proxychains4 tesseract-ocr imagemagick tini iputils-ping \
    ca-certificates fonts-liberation xdg-utils \
    libappindicator3-1 libasound2t64 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 libayatana-common0 libayatana-indicator3-7 \
    libbsd0 libc6 libcairo2 libcups2 libcurl4 \
    libdbus-1-3 libexpat1 \
    libgbm1 libgl1 libglib2.0-0 libgtk-3-0 libgtk-3-0t64 libgtk-3-bin libgtk-3-common libgtk-4-1 libgtk-4-bin libgtk-4-common \
    libnotify4 libnotify-bin libnspr4 libnss3 \
    libpango-1.0-0 libudev1 libuuid1 libvulkan1 \
    libwebkit2gtk-4.1-0 libwebkitgtk-6.0-4 \
    libx11-6 libx11-xcb1 libxau6 libxcb1 \
    libxcb-glx0 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-randr0 libxcb-render0 \
    libxcb-render-util0 libxcb-shape0 libxcb-shm0 \
    libxcb-sync1 libxcb-util1 libxcb-xfixes0 \
    libxcb-xinerama0 libxcb-xkb1 libxcomposite1 \
    libxdamage1 libxdmcp6 libxext6 libxfixes3 \
    libxkbcommon0 libxkbcommon-x11-0 libxrandr2

# Commented out Google Chrome installation
# RUN wget -O /tmp/google-chrome-stable.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
#     gdebi --n /tmp/google-chrome-stable.deb && \
#     rm /tmp/google-chrome-stable.deb

# Commented out Wipter application installation
# RUN wget -O /tmp/wipter.deb https://github.com/hoainv1807/Docker-Ubuntu-XFCE-XRDP/releases/download/wipter/wipter.deb && \
# gdebi --n /tmp/wipter.deb && \
# rm /tmp/wipter.deb

# Download and install the UpRock Mining application from the official source
RUN wget -O /tmp/UpRock-Mining.deb https://edge.uprock.com/v1/app-download/UpRock-Mining-v0.0.16.deb && \
    gdebi --n /tmp/UpRock-Mining.deb && \
    rm /tmp/UpRock-Mining.deb

# Commented out Grass installation
# RUN apt-mark hold \
#     grass-core grass-dev-doc grass-dev grass-doc grass-gui grass
# RUN wget -O /tmp/grass.deb https://github.com/hoainv1807/Docker-Ubuntu-XFCE-XRDP/releases/download/wipter/grass.deb && \
#     apt install /tmp/grass.deb -y --allow-change-held-packages && apt update && apt install -f -y && rm /tmp/grass.deb

# Set up X resources for customization
RUN echo "*customization: -color" > /root/.Xresources

# Set up TightVNC configuration
RUN mkdir -p /root/.vnc
RUN mkdir -p /root/.local/share

# Set alias for xterm as default terminal emulator
RUN update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xterm 100

# Create .Xauthority for root and ensure correct permissions
RUN touch /root/.Xauthority && chmod 600 /root/.Xauthority

# Move OpenSSH Server to 22222
RUN sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "ListenAddress 0.0.0.0" >> /etc/ssh/sshd_config && \
    echo "ListenAddress ::" >> /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd

# Clean up unnecessary packages and cache to reduce image size
RUN apt-get autoclean && apt-get autoremove -y && apt-get autopurge -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose the VNC port
EXPOSE 5901 22222

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/entrypoint.sh

# Use tini clear zombie process
ENTRYPOINT ["/usr/bin/tini", "--"]

# Set the default command
CMD ["/usr/local/bin/entrypoint.sh"]
