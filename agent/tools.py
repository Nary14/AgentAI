import os
import subprocess
import tempfile
import glob
import re
import json
import time

# Safety blocks
BLOCKED_PATTERNS = [
    r'rm\s+-rf\s+/',
    r'rm\s+-rf\s+/\s*\*',
    r':\(\)\{\s*:\|\s*:\&\s*\};',
    r'mkfs\.',
    r'dd\s+if=.*of=/dev/sd',
    r'>\s*/dev/sda',
    r'curl.*\|\s*sh',
    r'wget.*\|\s*sh',
]

def is_safe(cmd):
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, cmd, re.I):
            return False, pattern
    return True, ""

def run_bash(cmd, timeout=120):
    safe, reason = is_safe(cmd)
    if not safe:
        return subprocess.CompletedProcess(args=[], returncode=1, stdout="", stderr=f"BLOCKED: {reason}")
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)

def exec_python(code):
    script_dir = os.path.expanduser("~/sgoinfre/AgentAI/scripts")
    os.makedirs(script_dir, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False, dir=script_dir) as f:
        f.write(code)
        f.flush()
        result = subprocess.run(["python3", f.name], capture_output=True, text=True, timeout=120)
        os.unlink(f.name)
    return result

def write_file(path, content):
    full = os.path.expanduser(path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'w') as f:
        f.write(content)
    return f"Written: {full} ({len(content)} bytes)"

def read_file(path):
    with open(os.path.expanduser(path), 'r') as f:
        return f.read()

def list_images(folder):
    path = os.path.expanduser(folder)
    images = []
    for ext in ['*.jpg', '*.jpeg', '*.png', '*.gif', '*.webp', '*.bmp']:
        images.extend(glob.glob(os.path.join(path, ext)))
        images.extend(glob.glob(os.path.join(path, ext.upper())))
    return images

def create_excel(folder, output):
    full_folder = os.path.expanduser(folder)
    output = os.path.expanduser(output)
    
    if not os.path.exists(full_folder):
        return f"ERROR: Folder not found: {full_folder}"
    
    try:
        from openpyxl import Workbook
        from openpyxl.drawing.image import Image as XLImage
        from openpyxl.styles import Font
    except ImportError:
        return "ERROR: openpyxl not installed. Run: pip3 install --user openpyxl"
    
    wb = Workbook()
    ws = wb.active
    ws.title = os.path.basename(full_folder)
    
    headers = ["First Name", "Last Name", "Picture"]
    for i, h in enumerate(headers, 1):
        cell = ws.cell(row=1, column=i, value=h)
        cell.font = Font(bold=True)
    
    ws.column_dimensions['A'].width = 20
    ws.column_dimensions['B'].width = 20
    ws.column_dimensions['C'].width = 30
    
    images = list_images(full_folder)
    row = 2
    for img_path in sorted(images):
        name = os.path.splitext(os.path.basename(img_path))[0]
        parts = name.replace("_", " ").replace("-", " ").split()
        first = parts[0].title() if parts else ""
        last = " ".join(p.title() for p in parts[1:]) if len(parts) > 1 else ""
        
        ws.cell(row=row, column=1, value=first)
        ws.cell(row=row, column=2, value=last)
        
        try:
            img = XLImage(img_path)
            img.width = 120
            img.height = 120
            ws.add_image(img, f'C{row}')
            ws.row_dimensions[row].height = 100
        except Exception as e:
            ws.cell(row=row, column=3, value=f"Error: {e}")
        
        row += 1
    
    wb.save(output)
    return f"Excel created: {output} with {row-2} entries"

def download_file(url, output_path):
    try:
        import urllib.request
        output = os.path.expanduser(output_path)
        os.makedirs(os.path.dirname(output), exist_ok=True)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=60) as response:
            with open(output, 'wb') as f:
                f.write(response.read())
        return f"Downloaded: {output} ({os.path.getsize(output)} bytes)"
    except Exception as e:
        return f"ERROR: {str(e)}"

def web_scrape(url, action="get_text"):
    try:
        import urllib.request
        from html.parser import HTMLParser
        
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=30) as response:
            html = response.read().decode('utf-8', errors='ignore')
