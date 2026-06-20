#!/bin/sh

AGENT_NAME="AgentNary"
INSTALL_DIR="$HOME/sgoinfre/$AGENT_NAME"
export PATH="$INSTALL_DIR/ollama:$PATH"
export OLLAMA_MODELS="$INSTALL_DIR/models"
export OLLAMA_HOST="127.0.0.1:11434"

# Load config if exists
[ -f "$INSTALL_DIR/config/default.env" ] && . "$INSTALL_DIR/config/default.env"

# Kill old Ollama
pkill ollama 2>/dev/null || true
sleep 1

# Start Ollama
status() { echo ">>> $*" >&2; }
status "Starting Ollama..."
ollama serve &
sleep 2

# Check if running
if ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo "ERROR: Ollama failed to start"
    exit 1
fi

status "Ollama ready. Starting AgentNary..."
cd "$INSTALL_DIR/agent"

# Default model or choose
MODEL="${1:-cybersec-agent}"
echo "Using model: $MODEL"

MODEL="$MODEL" python3 agent.py
