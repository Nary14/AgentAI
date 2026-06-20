#!/bin/bash
set -e

AGENT_NAME="AgentAI"
REPO_URL="https://raw.githubusercontent.com/Nary14/AgentAI/main"

status() { echo ">>> $*" >&2; }
error() { echo "ERROR: $*" >&2; exit 1; }

echo "=========================================="
echo "  AgentAI Installer"
echo "=========================================="
echo ""
echo "Choose installation directory:"
echo "  1) ~/sgoinfre/AgentAI  (default, recommended for 42 students)"
echo "  2) ~/AgentAI             (home directory)"
echo "  3) Custom path"
echo ""

printf "Enter choice [1-3] (default: 1): "
read -r choice

case "$choice" in
    "2")
        INSTALL_DIR="$HOME/AgentAI"
        ;;
    "3")
        printf "Enter custom path: "
        read -r custom_path
        if [ -z "$custom_path" ]; then
            error "Custom path cannot be empty"
        fi
        INSTALL_DIR="${custom_path/#\~/$HOME}"
        ;;
    *)
        if [ -d "$HOME/sgoinfre" ]; then
            INSTALL_DIR="$HOME/sgoinfre/$AGENT_NAME"
            status "Using sgoinfre (detected)"
        else
            INSTALL_DIR="$HOME/$AGENT_NAME"
            status "sgoinfre not found, using home directory"
        fi
        ;;
esac

if [ -d "$INSTALL_DIR" ]; then
    printf "Directory %s already exists. Overwrite? [y/N]: " "$INSTALL_DIR"
    read -r overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        error "Installation cancelled"
    fi
    rm -rf "$INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
status "Installing to: $INSTALL_DIR"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;
esac

if [ ! -f "$INSTALL_DIR/ollama/ollama" ]; then
    status "Downloading Ollama for $ARCH..."
    mkdir -p "$INSTALL_DIR/ollama"
    curl -L --progress-bar \
        "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-$ARCH" \
        -o "$INSTALL_DIR/ollama/ollama"
    chmod +x "$INSTALL_DIR/ollama/ollama"
fi

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

status "Downloading AgentAI files..."
mkdir -p "$INSTALL_DIR/agent" "$INSTALL_DIR/models" "$INSTALL_DIR/config"

for file in agent/agent.py agent/browser.py agent/tools.py agent/requirements.txt \
            models/cybersec-agent.modelfile models/trading-agent.modelfile \
            models/code-agent.modelfile models/mine-agent.modelfile \
            config/default.env start.sh README.md; do
    curl -fsSL "$REPO_URL/$file" -o "$INSTALL_DIR/$file" 2>/dev/null || true
done

if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user -r "$INSTALL_DIR/agent/requirements.txt"
elif command -v pip >/dev/null 2>&1; then
    pip install --user -r "$INSTALL_DIR/agent/requirements.txt"
else
    error "pip/pip3 not found. Install Python pip first."
fi

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

chmod +x "$INSTALL_DIR/start.sh" 2>/dev/null || true

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -q "$INSTALL_DIR/start.sh" "$rc" 2>/dev/null; then
        echo "" >> "$rc"
        echo "# AgentAI aliases" >> "$rc"
        echo "alias agentai='$INSTALL_DIR/start.sh'" >> "$rc"
        echo "alias ai='$INSTALL_DIR/start.sh'" >> "$rc"
    fi
done

status "Install complete!"
status "Installation directory: $INSTALL_DIR"
status "Run: agentai  (or: ai)"
status "Or: $INSTALL_DIR/start.sh"
status ""
status "If using zsh, run: source ~/.zshrc"
status "If using bash, run: source ~/.bashrc"
