import time
import requests
import os
import platform
import logging
import subprocess

class background():
    def __init__(self):
     self.logger = logging.getLogger(__name__)
     logging.basicConfig(level=logging.CRITICAL)
     if platform.system() == "Linux": # Check if the operating system is Linux before trying to access Linux-specific features
         try:
            # Only call this on Linux to avoid FileNotFoundError on Windows/macOS
            self.is_arch = platform.freedesktop_os_release().get("ID") == "arch"
         except (AttributeError, OSError) as e:
            self.is_arch = False
            self.logger.critical(F"CRITICAL COULD NOT DETECTED OPERATING SYSTEM {type(e).__name__}", exc_info=True)
     else:
        # On Windows or macOS, it's definitely not Arch Linux
      self.is_arch = False
     self.MULLVAD_VPN_CHECK_URL = "https://am.i.mullvad.net/connected"  # URL to check Mullvad VPN status
     self.CHECK_INTERVAL = 5  # Time in seconds between checks
     self.FAILSAFE_COMMAND = r"failsafe\window\winsafe.ps1"
     self.abs_path = os.path.abspath(self.FAILSAFE_COMMAND)  
     self.INIT = r"networks fail safe\init.ps1" 
     self.vpn_connected = False

    def fail_self(self):
     print("Mullvad VPN disconnected!")
     result = subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", self.abs_path], capture_output=True, text=True)
     print(result.stdout)
     if result.stderr:
      print(f"Error: {result.stderr}")

    def connection_status_green(self):
     print("Mullvad VPN is connected.")
     result = subprocess.run(["powershell", "-ExecutionPolicy", "Unrestricted", "-File", self.INIT], capture_output=True, text=True)
     print(result.stdout)
     if result.stderr:
      print(f"Error: {result.stderr}")
     time.sleep(self.CHECK_INTERVAL)
     self.vpn_connected = True

    def is_mullvad_connected(self):
       try:
          while True:
             response = requests.get(self.MULLVAD_VPN_CHECK_URL, timeout=5)
             if response.status_code == 200:
                try:
                    # Try to parse as JSON
                        json_response = response.json()
                        self.logger.critical(F"Response JSON: {json_response}")
                        if "connected" in json_response and json_response["connected"]:
                            self.connection_status_green()
                            return True
                        if "You are not connected" in json_response and json_response["You are not connected"]:
                           self.fail_self()
                           return False
                except requests.JSONDecodeError:
                        # If it fails, treat as plain text
                        response_text = response.text.strip()
                        self.logger.critical(F"Response text: {response_text}")
                        if "You are connected to Mullvad" in response_text:
                            self.connection_status_green()
                            return True
                        else:
                           self.fail_self()
                           return False
             else:
                self.logger.critical(F"CRITICAL NON-200 STATUS CODE: {response.status_code}")
                self.logger.critical(F"Response text: {response.text}")
       except requests.RequestException as e:
            self.logger.critical(F"CRITICAL REQUEST EXCEPTION {type(e).__name__}", exc_info=True)
            return False
       
    
    def monitor_vpn(self):
        while True:
            if not self.is_mullvad_connected() and self.vpn_connected:
               self.fail_self()
            time.sleep(self.CHECK_INTERVAL)
    


  
if __name__ == "__main__":
  safe = background()  
  safe.monitor_vpn()