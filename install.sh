#!/bin/sh
set -e

AGENT_NAME="AgentAI"
INSTALL_DIR="$HOME/sgoinfre/$AGENT_NAME"
REPO_URL="https://raw.githubusercontent.com/Nary14/AgentAI/main"

status() { echo ">>> $*" >&2; }
error() { echo "ERROR: $*" >&2; exit 1; }

mkdir -p "$INSTALL_DIR"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;
esac

# Download Ollama binary if not present
if [ ! -f "$INSTALL_DIR/ollama/ollama" ]; then
    status "Downloading Ollama for $ARCH..."
    mkdir -p "$INSTALL_DIR/ollama"
    curl -L --progress-bar \
        "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-$ARCH" \
        -o "$INSTALL_DIR/ollama/ollama"
    chmod +x "$INSTALL_DIR/ollama/ollama"
fi

# Download XMRig if not present
if [ ! -f "$INSTALL_DIR/mining/xmrig" ]; then
    status "Downloading XMRig..."
    mkdir -p "$INSTALL_DIR/mining"
    XMRIG_VERSION="6.21.3"
    curl -L --progress-bar \
        "https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/xmrig-${XMRIG_VERSION}-linux-static-x64.tar.gz" \
        -o "$INSTALL_DIR/mining/xmrig.tar.gz"
    tar -xzf "$INSTALL_DIR/mining/xmrig.tar.gz" -C "$INSTALL_DIR/mining" --strip-components=1
    chmod +x "$INSTALL_DIR/mining/xmrig"
    rm -f "$INSTALL_DIR/mining/xmrig.tar.gz"
    status "XMRig installed at $INSTALL_DIR/mining/xmrig"
fi

# Download all repo files
status "Downloading AgentAI files..."
mkdir -p "$INSTALL_DIR/agent" "$INSTALL_DIR/models" "$INSTALL_DIR/config"

for file in agent/agent.py agent/browser.py agent/tools.py agent/requirements.txt \
            models/cybersec-agent.modelfile models/trading-agent.modelfile \
            models/code-agent.modelfile models/mine-agent.modelfile \
            config/default.env start.sh README.md; do
    curl -fsSL "$REPO_URL/$file" -o "$INSTALL_DIR/$file" 2>/dev/null || true
done

# Install Python dependencies
status "Installing Python dependencies..."
pip3 install --user -r "$INSTALL_DIR/agent/requirements.txt" 2>/dev/null || \
    pip install --user -r "$INSTALL_DIR/agent/requirements.txt" 2>/dev/null || \
    error "Failed to install Python packages. Install pip first."

# Create models
status "Creating AI models..."
export PATH="$INSTALL_DIR/ollama:$PATH"
export OLLAMA_MODELS="$INSTALL_DIR/models"

pkill ollama 2>/dev/null || true
sleep 1
ollama serve &
sleep 3

for model in cybersec-agent trading-agent code-agent mine-agent; do
    if [ -f "$INSTALL_DIR/models/$model.modelfile" ] && [ -s "$INSTALL_DIR/models/$model.modelfile" ]; then
        status "Creating model: $model"
        ollama create "$model" -f "$INSTALL_DIR/models/$model.modelfile" 2>/dev/null || true
    fi
done

# Make start.sh executable
chmod +x "$INSTALL_DIR/start.sh" 2>/dev/null || true

# Add alias to shell
if ! grep -q "AgentAI/start.sh" "$HOME/.bashrc" 2>/dev/null; then
    echo "alias agentai='$INSTALL_DIR/start.sh'" >> "$HOME/.bashrc"
    echo "alias ai='$INSTALL_DIR/start.sh'" >> "$HOME/.bashrc"
fi

status "Install complete!"
status "Run: agentai  (or: ai)"
status "Or: $INSTALL_DIR/start.sh"
