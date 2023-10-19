import tkinter as tk
import subprocess
import requests
import json


def getPlayLoc():
    result = subprocess.run(["osascript", "-e", 'tell application "Spotify" to get player position'], capture_output=True, text=True)
    return result.stdout

def connect():
    print("connecting to server...")
    updateLoop()

# def sendData

lastTime = 0
def updateLoop():
    global lastTime

    print("\nsyncing...")

    thisLoc = getPlayLoc()
    print(f"this loc: {thisLoc}")

    # send to server
    url = "https://1a9b-76-146-33-51.ngrok-free.app/receive-string"
    data = {"text": thisLoc}
    response = requests.post(url, headers={"Content-Type": "application/json"}, data=json.dumps(data))
    print("Response:", response.text)


    window.after(1000, updateLoop)
    return None


window = tk.Tk()
window.geometry("500x200")

tk.Label(text="Syncify").pack(padx = (10, 10), pady=(40, 20))

entry = tk.Entry()
entry.insert(0, "enter code")
entry.pack(pady=(5, 5))

connectBtn = tk.Button(text="Connect", command=connect)
connectBtn.pack(pady=(5, 20))

window.mainloop()
