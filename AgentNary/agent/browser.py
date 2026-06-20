import os
try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.common.keys import Keys
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    SELENIUM_OK = True
except ImportError:
    SELENIUM_OK = False

class BrowserController:
    def __init__(self):
        self.driver = None
    
    def start(self, browser="firefox", headless=False):
        if not SELENIUM_OK:
            return "ERROR: Selenium not installed. Run: pip3 install --user selenium webdriver-manager"
        
        if self.driver:
            self.driver.quit()
        
        download_dir = os.path.expanduser("~/sgoinfre/AgentNary/downloads")
        os.makedirs(download_dir, exist_ok=True)
        
        if browser == "chrome":
            from selenium.webdriver.chrome.options import Options
            options = Options()
            if headless:
                options.add_argument("--headless")
            options.add_argument("--no-sandbox")
            options.add_argument("--disable-dev-shm-usage")
            prefs = {
                "download.default_directory": download_dir,
                "download.prompt_for_download": False,
                "plugins.always_open_pdf_externally": True
            }
            options.add_experimental_option("prefs", prefs)
            self.driver = webdriver.Chrome(options=options)
        else:
            from selenium.webdriver.firefox.options import Options
            options = Options()
            if headless:
                options.add_argument("--headless")
            options.set_preference("browser.download.folderList", 2)
            options.set_preference("browser.download.dir", download_dir)
            options.set_preference("browser.download.useDownloadDir", True)
            options.set_preference("browser.helperApps.neverAsk.saveToDisk", "application/pdf,application/octet-stream")
            self.driver = webdriver.Firefox(options=options)
        
        return f"Browser started: {browser}"
    
    def navigate(self, url):
        if not self.driver:
            return "ERROR: Browser not started"
        self.driver.get(url)
        return f"Navigated to {url}\nTitle: {self.driver.title}"
    
    def click(self, selector, by="css"):
        if not self.driver:
            return "ERROR: Browser not started"
        by_type = By.CSS_SELECTOR if by == "css" else By.XPATH if by == "xpath" else By.ID
        elem = WebDriverWait(self.driver, 10).until(
            EC.element_to_be_clickable((by_type, selector))
        )
        elem.click()
        return f"Clicked: {selector}"
    
    def type_text(self, selector, text, submit=False):
        if not self.driver:
            return "ERROR: Browser not started"
        by_type = By.CSS_SELECTOR if "|" not in selector else By.XPATH
        elem = self.driver.find_element(by_type, selector.split("|")[0] if "|" in selector else selector)
        elem.clear()
        elem.send_keys(text)
        if submit:
            elem.send_keys(Keys.RETURN)
        return f"Typed into {selector}"
    
    def get_text(self):
        if not self.driver:
            return "ERROR: Browser not started"
        return self.driver.find_element(By.TAG_NAME, "body").text[:5000]
    
    def get_elements(self, selector, by="css"):
        if not self.driver:
            return "ERROR: Browser not started"
        by_type = By.CSS_SELECTOR if by == "css" else By.XPATH
        elems = self.driver.find_elements(by_type, selector)
        texts = [e.text for e in elems if e.text]
        return f"Found {len(elems)} elements:\n" + "\n".join(texts[:50])
    
    def get_source(self):
        if not self.driver:
            return "ERROR: Browser not started"
        return self.driver.page_source[:10000]
    
    def scroll(self, amount=500):
        if not self.driver:
            return "ERROR: Browser not started"
        self.driver.execute_script(f"window.scrollBy(0, {amount});")
        return f"Scrolled {amount}px"
    
    def screenshot(self, path):
        if not self.driver:
            return "ERROR: Browser not started"
        full = os.path.expanduser(path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        self.driver.save_screenshot(full)
        return f"Screenshot: {full}"
    
    def wait(self, seconds=2):
        import time
        time.sleep(seconds)
        return f"Waited {seconds}s"
    
    def close(self):
        if self.driver:
            self.driver.quit()
            self.driver = None
            return "Browser closed"
        return "Browser not running"
