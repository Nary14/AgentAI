# AgentNary

Autonomous AI agent with system access, browser automation, and offline Ollama.

## One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/Nary14/AgentAI/main/install.sh | sh
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
