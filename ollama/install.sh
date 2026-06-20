#!/bin/sh
set -eu

red="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 1 || :) 2>&-)"
plain="$( (/usr/bin/tput sgr0 || :) 2>&-)"

status() { echo ">>> $*" >&2; }
error() { echo "${red}ERROR:${plain} $*"; exit 1; }
warning() { echo "${red}WARNING:${plain} $*"; }

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf $TEMP_DIR; }
trap cleanup EXIT

available() { command -v $1 >/dev/null; }
require() {
    local MISSING=''
    for TOOL in $*; do
        if ! available $TOOL; then
            MISSING="$MISSING $TOOL"
        fi
    done
    echo $MISSING
}

OS="$(uname -s)"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;
esac

###########################################
# Linux (user install, no sudo) — LATEST
###########################################

[ "$OS" = "Linux" ] || error 'This script is intended to run on Linux only.'

NEEDS=$(require curl tar grep sed)
if [ -n "$NEEDS" ]; then
    status "ERROR: The following tools are required but missing:"
    for NEED in $NEEDS; do
        echo "  - $NEED"
    done
    exit 1
fi

# User install directory
BINDIR="/home/$USER/sgoinfre/Bin"
OLLAMA_INSTALL_DIR="$BINDIR"
mkdir -p "$BINDIR" || error "Cannot create $BINDIR"

if [ -d "$OLLAMA_INSTALL_DIR/lib/ollama" ] ; then
    status "Cleaning up old version at $OLLAMA_INSTALL_DIR/lib/ollama"
    rm -rf "$OLLAMA_INSTALL_DIR/lib/ollama"
fi

status "Installing latest ollama to $OLLAMA_INSTALL_DIR"
mkdir -p "$OLLAMA_INSTALL_DIR/lib/ollama"

# Download and extract latest from GitHub releases
download_latest() {
    local dest_dir="$1"
    
    status "Fetching latest release URL from GitHub..."
    
    # Get latest release download URL from GitHub API
    LATEST_URL=$(curl -s "https://api.github.com/repos/ollama/ollama/releases/latest" | \
        grep -o '"browser_download_url": "[^"]*ollama-linux-'$ARCH'\.tar\.zst"' | \
        cut -d'"' -f4)
    
    if [ -z "$LATEST_URL" ]; then
        error "Could not find latest release download URL"
    fi
    
    status "Downloading: $LATEST_URL"
    
    if available zstd; then
        curl -L --progress-bar "$LATEST_URL" | zstd -d | tar -xf - -C "$dest_dir"
    else
        # Try .tgz fallback
        LATEST_URL_TGZ=$(echo "$LATEST_URL" | sed 's/\.tar\.zst/\.tgz/')
        status "zstd not found, trying .tgz fallback..."
        curl -L --progress-bar "$LATEST_URL_TGZ" | tar -xzf - -C "$dest_dir"
    fi
}

download_latest "$OLLAMA_INSTALL_DIR"

# Symlink to BINDIR
if [ -f "$OLLAMA_INSTALL_DIR/bin/ollama" ] && [ "$OLLAMA_INSTALL_DIR/bin/ollama" != "$BINDIR/ollama" ]; then
    status "Making ollama accessible in $BINDIR"
    ln -sf "$OLLAMA_INSTALL_DIR/bin/ollama" "$BINDIR/ollama"
elif [ -f "$OLLAMA_INSTALL_DIR/ollama" ] && [ "$OLLAMA_INSTALL_DIR/ollama" != "$BINDIR/ollama" ]; then
    ln -sf "$OLLAMA_INSTALL_DIR/ollama" "$BINDIR/ollama"
fi

status 'The Ollama API is now available at 127.0.0.1:11434.'
status 'Install complete. Run "ollama" from the command line.'
status "Make sure $BINDIR is in your PATH:"
status "  export PATH=\"/home/$USER/sgoinfre/Bin:\$PATH\""

exit 0
