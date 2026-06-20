#!/usr/bin/env python3
import os
import sys
import requests
import re

from tools import *
from browser import BrowserController

OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
MODEL = os.getenv("MODEL", "cybersec-agent")

browser = BrowserController()

TOOLS = {
    "bash": lambda p: run_bash(p),
    "python": lambda p: exec_python(p),
    "write_file": lambda p: write_file(*p.split("|", 1)) if "|" in p else "ERROR: write_file needs path|content",
    "read_file": lambda p: read_file(p),
    "list_images": lambda p: "\n".join(list_images(p)),
    "create_excel": lambda p: create_excel(*p.split("|", 1)) if "|" in p else "ERROR: create_excel needs folder|output",
    "web_scrape": lambda p: web_scrape(*p.split("|", 1)) if "|" in p else web_scrape(p),
    "download": lambda p: download_file(*p.split("|", 1)) if "|" in p else "ERROR: download needs url|path",
    # Browser
    "browser_start": lambda p: browser.start(p.split("|")[0] if "|" in p else p, "headless" in p),
    "browser_navigate": lambda p: browser.navigate(p),
    "browser_click": lambda p: browser.click(*p.split("|", 1)) if "|" in p else browser.click(p),
    "browser_type": lambda p: browser.type_text(*p.split("|", 2)) if p.count("|") >= 2 else "ERROR: browser_type needs selector|text|submit",
    "browser_get_text": lambda _: browser.get_text(),
    "browser_get_elements": lambda p: browser.get_elements(*p.split("|", 1)) if "|" in p else browser.get_elements(p),
    "browser_get_source": lambda _: browser.get_source(),
    "browser_scroll": lambda p: browser.scroll(int(p)) if p.isdigit() else browser.scroll(),
    "browser_screenshot": lambda p: browser.screenshot(p),
    "browser_wait": lambda p: browser.wait(int(p)) if p.isdigit() else browser.wait(),
    "browser_close": lambda _: browser.close(),
}

def ask_model(prompt, context=""):
    system = f"""You are AgentNary — an autonomous agent with FULL SYSTEM and BROWSER access.
Model: {MODEL}

Available tools:
- bash|command
- python|code
- write_file|path|content
- read_file|path
- list_images|folder
- create_excel|folder|output.xlsx
- web_scrape|url|action
- download|url|path
- browser_start|firefox|headless
- browser_navigate|url
- browser_click|selector|css
- browser_type|selector|text|true/false
- browser_get_text
- browser_get_elements|selector|css
- browser_get_source
- browser_scroll|500
- browser_screenshot|path
- browser_wait|3
- browser_close

ALWAYS format actions as: EXECUTE:tool|params

Context:
{context}

User: {prompt}
Agent:"""
    
    r = requests.post(OLLAMA_URL, json={
        "model": MODEL,
        "prompt": system,
        "stream": False,
        "options": {"temperature": 0.3, "num_ctx": 16384}
    })
    return r.json().get("response", "[ERROR: No response]")

def parse_actions(text):
    pattern = r'EXECUTE:(\w+)\|(.+?)(?=\n|EXECUTE:|$)'
    return re.findall(pattern, text, re.DOTALL)

def main():
    print("=" * 60)
    print(f"  AgentNary — Model: {MODEL}")
    print("  Type 'quit' to exit")
    print("=" * 60)
    
    context = ""
    while True:
        try:
            user_input = input("\n[YOU] > ").strip()
        except EOFError:
            break
        
        if user_input.lower() in ('quit', 'exit', 'q'):
            browser.close()
            break
        if not user_input:
            continue
        
        response = ask_model(user_input, context)
        print(f"\n[AI] {response}")
        
        actions = parse_actions(response)
        for tool, params in actions:
            print(f"\n[TOOL] {tool}: {params[:100]}...")
            try:
                result = TOOLS[tool](params.strip())
                print(f"[RESULT] {str(result)[:1500]}")
                context += f"\nAction: {tool}\nResult: {result}\n"
            except Exception as e:
                print(f"[ERROR] {e}")
        
        context += f"\nQ: {user_input}\nA: {response}\n"
        if len(context) > 25000:
            context = context[-12000:]

if __name__ == "__main__":
    main()
