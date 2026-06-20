# AgentNary

Autonomous AI agent with system access, browser automation, and offline Ollama.

## One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/Nary14/AgentAI/main/install.sh -o /tmp/install.sh
bash /tmp/install.sh
```
## Run
```bash
agentnary        # or: an
```
## Or with specific model:
```bash
~/sgoinfre/AgentNary/start.sh trading-agent
```
## Available Models

|Model	|Purpose|
|:------|------:|
|cybersec-agent	|Cybersecurity, pentesting, HTB|
|trading-agent	|Finance, stocks, data analysis|
|code-agent	|Coding, development, debugging|

## Examples
```plain
Create Excel from photos in ~/Pictures/Class
Go to Google and search for "python tutorial"
Start HTB and open the machines page
Write a port scanner in Python
```

## Structure
```plain
~/sgoinfre/AgentNary/
├── ollama/          # Ollama binary
├── models/          # AI models
├── agent/           # Python agent
├── config/          # Settings
└── start.sh         # Launcher
```

## Requirements

and hoe to make dot
like this but with dot
- Linux (Ubuntu/Debian preferred)
- Python 3.8+
- 16GB+ RAM (for CPU inference)
- No sudo needed

# About


## Update `start.sh` for `AgentAI`

```bash
#!/bin/sh

AGENT_NAME="AgentAI"
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

status "Ollama ready. Starting AgentAI..."
cd "$INSTALL_DIR/agent"

# Default model or choose
MODEL="${1:-cybersec-agent}"
echo "Using model: $MODEL"

MODEL="$MODEL" python3 agent.py
```
