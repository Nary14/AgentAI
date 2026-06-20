#!/bin/sh
set -e

AGENT_NAME="AgentAI"
status() { echo ">>> $*" >&2; }
warning() { echo "WARNING: $*" >&2; }

status "Uninstalling AgentAI..."

# Find installation directory
INSTALL_DIR=""

# Check common locations
for dir in "$HOME/sgoinfre/$AGENT_NAME" "$HOME/$AGENT_NAME" "$HOME/AgentAI"; do
    if [ -d "$dir" ]; then
        INSTALL_DIR="$dir"
        break
    fi
done

# If not found, ask user
if [ -z "$INSTALL_DIR" ]; then
    printf "Installation directory not found automatically.\n"
    printf "Enter path (or press Enter to skip): "
    read -r custom_dir
    if [ -n "$custom_dir" ]; then
        INSTALL_DIR="${custom_dir/#\~/$HOME}"
    fi
fi

# Kill all running processes
status "Stopping AgentAI processes..."
pkill -f "python3.*agent.py" 2>/dev/null || true
pkill -f "ollama serve" 2>/dev/null || true
pkill xmrig 2>/dev/null || true
sleep 1

# Delete installation directory
if [ -n "$INSTALL_DIR" ] && [ -d "$INSTALL_DIR" ]; then
    status "Removing $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
else
    warning "Installation directory not found"
fi

# Delete old locations (backward compatibility)
for old_dir in "$HOME/sgoinfre/AgentNary" "$HOME/sgoinfre/agent" "$HOME/sgoinfre/scripts" "$HOME/sgoinfre/Bin"; do
    if [ -d "$old_dir" ]; then
        status "Removing old directory: $old_dir"
        rm -rf "$old_dir"
    fi
done

# Delete Ollama models and config
if [ -d "$HOME/.ollama" ]; then
    status "Removing ~/.ollama..."
    rm -rf "$HOME/.ollama"
fi

# Remove system-wide Ollama if exists
if [ -f "/usr/bin/ollama" ] || [ -f "/usr/local/bin/ollama" ]; then
    warning "System-wide Ollama detected. Run with sudo to remove:"
    warning "  sudo rm -f /usr/bin/ollama /usr/local/bin/ollama"
    warning "  sudo rm -rf /usr/share/ollama /etc/systemd/system/ollama.service"
fi

# Remove aliases from shell configs
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ]; then
        if grep -q "AgentAI" "$rc" 2>/dev/null; then
            status "Removing aliases from $rc..."
            sed -i '/AgentAI/d' "$rc"
            sed -i '/agentai/d' "$rc"
            sed -i '/^# AgentAI aliases/d' "$rc"
        fi
        sed -i '/sgoinfre\/Bin/d' "$rc" 2>/dev/null || true
        sed -i '/OLLAMA_MODELS/d' "$rc" 2>/dev/null || true
        sed -i '/OLLAMA_HOST/d' "$rc" 2>/dev/null || true
    fi
done

status "Uninstall complete!"
status "Please run one of these to reload your shell:"
status "  source ~/.bashrc    (for bash)"
status "  source ~/.zshrc     (for zsh)"
status ""
status "To fully remove Python packages, run:"
status "  pip3 uninstall -y requests selenium webdriver-manager openpyxl"
