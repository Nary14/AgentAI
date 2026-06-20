#!/bin/bash
set -e

AGENT_NAME="AgentAI"
REPO_URL="https://raw.githubusercontent.com/Nary14/AgentAI/main"

status() { echo ">>> $*" >&2; }
error() { echo "ERROR: $*" >&2; exit 1; }

echo "=========================================="
echo "         NaryAgentAI Installer            "
echo "=========================================="
echo ""
echo "Choose installation directory:"
echo "  1) ~/sgoinfre/AgentAI    (default)"
echo "  2) ~/AgentAI             (home directory)"
echo "  3) Custom path"
echo ""

choice=""
if [ -t 0 ]; then
    printf "Enter choice [1-3] (default: 1): "
    read -r choice
fi

INSTALL_DIR=""
if [ "$choice" = "2" ]; then
    INSTALL_DIR="$HOME/AgentAI"
elif [ "$choice" = "3" ]; then
    if [ -t 0 ]; then
        printf "Enter custom path: "
        read -r custom_path
    else
        custom_path=""
    fi
    if [ -z "$custom_path" ]; then
        error "Custom path cannot be empty"
    fi
    INSTALL_DIR="${custom_path/#\~/$HOME}"
else
    if [ -d "$HOME/sgoinfre" ]; then
        INSTALL_DIR="$HOME/sgoinfre/$AGENT_NAME"
        status "Using sgoinfre (detected)"
    else
        INSTALL_DIR="$HOME/$AGENT_NAME"
        status "sgoinfre not found, using home directory"
    fi
fi

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

# Download all repo files
status "Downloading AgentAI files..."
mkdir -p "$INSTALL_DIR/agent" "$INSTALL_DIR/models" "$INSTALL_DIR/config" "$INSTALL_DIR/ollama"

for file in agent/agent.py agent/browser.py agent/tools.py agent/requirements.txt \
            models/cybersec-agent.modelfile models/trading-agent.modelfile \
            models/code-agent.modelfile models/mine-agent.modelfile \
            config/default.env start.sh README.md uninstall.sh \
            ollama/install.sh; do
    curl -fsSL "$REPO_URL/$file" -o "$INSTALL_DIR/$file" 2>/dev/null || true
done

# Install Ollama using the custom installer
if [ -f "$INSTALL_DIR/ollama/install.sh" ]; then
    status "Installing Ollama using custom installer..."
    chmod +x "$INSTALL_DIR/ollama/install.sh"
    export AGENTAI_OLLAMA_DIR="$INSTALL_DIR/ollama"
    bash "$INSTALL_DIR/ollama/install.sh"
fi

# Find where ollama actually got installed
OLLAMA_BIN=""
if [ -f "$INSTALL_DIR/ollama/ollama" ]; then
    OLLAMA_BIN="$INSTALL_DIR/ollama/ollama"
elif [ -f "$INSTALL_DIR/ollama/bin/ollama" ]; then
    OLLAMA_BIN="$INSTALL_DIR/ollama/bin/ollama"
elif [ -f "$HOME/sgoinfre/Bin/ollama" ]; then
    OLLAMA_BIN="$HOME/sgoinfre/Bin/ollama"
fi

if [ -z "$OLLAMA_BIN" ]; then
    error "Ollama binary not found after installation"
fi

status "Ollama found at: $OLLAMA_BIN"

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

# Install Python dependencies
status "Installing Python dependencies..."
(
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user -r "$INSTALL_DIR/agent/requirements.txt" || true
    elif command -v pip >/dev/null 2>&1; then
        pip install --user -r "$INSTALL_DIR/agent/requirements.txt" || true
    else
        error "pip/pip3 not found. Install Python pip first."
    fi
)

# Create models
status "Creating AI models..."
export PATH="$(dirname "$OLLAMA_BIN"):$PATH"
export OLLAMA_MODELS="$INSTALL_DIR/models"

pkill ollama 2>/dev/null || true
sleep 1

# Start Ollama server
"$OLLAMA_BIN" serve &
sleep 3

# Verify Ollama is running
if ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    error "Ollama failed to start"
fi

for model in cybersec-agent trading-agent code-agent mine-agent; do
    if [ -f "$INSTALL_DIR/models/$model.modelfile" ] && [ -s "$INSTALL_DIR/models/$model.modelfile" ]; then
        status "Creating model: $model"
        ollama create "$model" -f "$INSTALL_DIR/models/$model.modelfile" 2>/dev/null || true
    fi
done

# Create start.sh dynamically with correct paths
cat > "$INSTALL_DIR/start.sh" << EOF
#!/bin/bash
export PATH="$(dirname "$OLLAMA_BIN"):\$PATH"
export OLLAMA_MODELS="$INSTALL_DIR/models"
export OLLAMA_HOST="127.0.0.1:11434"

[ -f "$INSTALL_DIR/config/default.env" ] && . "$INSTALL_DIR/config/default.env"

pkill ollama 2>/dev/null || true
sleep 1

status() { echo ">>> \$*" >&2; }
status "Starting Ollama..."
ollama serve &
sleep 2

if ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo "ERROR: Ollama failed to start"
    exit 1
fi

status "Ollama ready. Starting AgentAI..."
cd "$INSTALL_DIR/agent"

MODEL="\${1:-cybersec-agent}"
echo "Using model: \$MODEL"
MODEL="\$MODEL" python3 agent.py
EOF

chmod +x "$INSTALL_DIR/start.sh"

# Make uninstall.sh executable
chmod +x "$INSTALL_DIR/uninstall.sh" 2>/dev/null || true

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
status "Ollama binary: $OLLAMA_BIN"
status "Run: agentai  (or: ai)"
status "Or: $INSTALL_DIR/start.sh"
status "Uninstall: $INSTALL_DIR/uninstall.sh"
status ""
status "If using zsh, run: source ~/.zshrc"
status "If using bash, run: source ~/.bashrc"
