#!/bin/bash
INSTALL_DIR="$HOME/sgoinfre/AgentAI"
OLLAMA_BIN="$INSTALL_DIR/ollama/ollama"

export PATH="$(dirname "$OLLAMA_BIN"):$PATH"
export OLLAMA_MODELS="$INSTALL_DIR/models"
export OLLAMA_HOST="127.0.0.1:11434"

# Load config if exists
[ -f "$INSTALL_DIR/config/default.env" ] && . "$INSTALL_DIR/config/default.env"

# Kill old Ollama
pkill ollama 2>/dev/null || true
sleep 1

# Start Ollama silently
status() { echo ">>> $*" >&2; }
status "Starting Ollama..."
nohup ollama serve >/dev/null 2>&1 &
sleep 2

# Check if running
if ! curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo "ERROR: Ollama failed to start"
    exit 1
fi

status "Ollama ready. Starting AgentAI..."
cd "$INSTALL_DIR/agent"

# Default model or choose
MODEL="${1:-cybersec-agent}"
echo "Using model: $MODEL"
MODEL="$MODEL" python3 agent.py
