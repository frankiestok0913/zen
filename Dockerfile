# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set environment variable to suppress interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure keyboard layout to English (US)
RUN echo 'keyboard-configuration keyboard-configuration/layoutcode select us' | debconf-set-selections

RUN apt update && apt upgrade -y

# Install packages - Consolidated and added noVNC related packages
RUN apt-get install -y --no-install-recommends \
    xfce4-session xfwm4 xfce4-panel xfce4-goodies \
    tigervnc-standalone-server novnc websockify \
    # tightvncserver # Replaced by tigervnc-standalone-server for consistency with original
    xfonts-base xfonts-75dpi xfonts-100dpi \
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
    libxkbcommon0 libxkbcommon-x11-0 libxrandr2 \
    software-properties-common xubuntu-icon-theme net-tools vim git tzdata

# Download and install the UpRock Mining application from the official source
RUN wget -O /tmp/UpRock-Mining.deb https://edge.uprock.com/v1/app-download/UpRock-Mining-v0.0.10.deb && \
    gdebi --n /tmp/UpRock-Mining.deb && \
    rm /tmp/UpRock-Mining.deb

# Set up X resources for customization
RUN echo "*customization: -color" > /root/.Xresources

# Set up VNC configuration (tigervnc uses ~/.vnc, which is created by vncserver command)
RUN mkdir -p /root/.local/share # For other user specific configs if needed

# Set alias for xterm as default terminal emulator (xfce4-terminal is usually better if installed with goodies)
RUN update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xterm 100

# Create .Xauthority for root and ensure correct permissions
RUN touch /root/.Xauthority && chmod 600 /root/.Xauthority

# Clean up unnecessary packages and cache to reduce image size
RUN apt-get autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose the VNC, noVNC/websockify, and SSH ports
# Railway will map one of these (typically the one specified by $PORT or the lowest one if not specified)
EXPOSE 5901 6080

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod a+x /usr/local/bin/entrypoint.sh

# Use tini to clear zombie processes
ENTRYPOINT ["/usr/bin/tini", "--"]

# Set the default command to run the entrypoint script
CMD ["/usr/local/bin/entrypoint.sh"]
