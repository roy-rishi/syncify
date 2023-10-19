import tkinter as tk
import requests
from PIL import ImageTk, Image
import subprocess
import json
import os


def gettrackLoc():
    result = subprocess.run(["osascript", "-e", 'tell application "Spotify" to get player position'], capture_output=True, text=True)
    return result.stdout.strip()

def gettrackID():
    result = subprocess.run(["osascript", "-e", 'tell application "Spotify" to get id of current track'], capture_output=True, text=True)
    return result.stdout.strip()

def getPlayerState():
    result = subprocess.run(["osascript", "-e", 'tell application "Spotify" to get player state'], capture_output=True, text=True)
    return result.stdout.strip()

def setPlayerPos(timestamp):
    print(f"this player set to {timestamp}")
    result = subprocess.run(["osascript", "-e", 'tell application "Spotify" to set player position to ' + str(int(float(timestamp)))], capture_output=True, text=True)
    return result.stdout.strip()

def setTrackID(id):
    print(f"track set to {id}")
    result = subprocess.run(["osascript", "-e", f'tell application "Spotify" to play track "{id}"'], capture_output=True, text=True)
    return result.stdout.strip()

session_token = None
server_url = None
lastUpdate = None
def connect():
    global session_token
    global server_url

    session_token = tokenEntry.get()
    print(urlEntry.get())
    server_url = urlEntry.get() + "/receive-timestamp"
    print(session_token)
    print(server_url)

    print("connecting to server...")


def updateLoop():
    global lastUpdate

    print("\nsyncing...")
    if session_token == None or server_url == None:
        window.after(1000, updateLoop)
        return None

    trackTS = gettrackLoc()
    trackID = gettrackID()
    playerState = getPlayerState()
    print(f"track loc   : {trackTS}")
    print(f"track id    : {trackID}")
    print(f"player state: {playerState}")
    print(f"server url  : {server_url}")

    # send to server
    changed = lastUpdate != None and (trackID != lastUpdate["data"]["id"] or abs(float(trackTS) - float(lastUpdate["data"]["timestamp"])) >= 3)
    print("changed: " + str(changed))
    dataS = {"session_token": session_token,
             "data": {
                 "timestamp": str(trackTS),
                 "id": str(trackID),
                 "player-state": str(playerState),
                 "changed": changed
                 }
            }

    try:
        response = requests.post(server_url, headers={"Content-Type": "application/json"}, data=json.dumps(dataS))
        print("Response:", response.text)
        serverUpdate = json.loads(response.text)

        if serverUpdate != None:
            serverChanged = serverUpdate["data"]["changed"]
            if (trackID != serverUpdate["data"]["id"] or abs(float(trackTS) - float(serverUpdate["data"]["timestamp"])) >= 3) and serverChanged and not changed:
                print("changing this player state...")
                setTrackID(serverUpdate["data"]["id"])
                setPlayerPos(serverUpdate["data"]["timestamp"])

                dataS["data"]["id"] = serverUpdate["data"]["id"]
                dataS["data"]["timestamp"] = serverUpdate["data"]["timestamp"]

    except requests.exceptions.RequestException as e:
        print(f"Error sending data to server: {e}")

    lastUpdate = dataS

    window.after(1000, updateLoop)
    return None


window = tk.Tk()
# 16:10 landscape aspect ratio
window.geometry("856x535")
# 4:3 portrait aspect ratio
# window.geometry("428x570")

window.title("Syncify")

# image
baseDir = os.path.dirname(__file__)
filePath = os.path.join(baseDir, 'img/syncify.png')
original_image = Image.open(filePath)
width, height = 200, 200
resized_image = original_image.resize((width, height), Image.LANCZOS)
image = ImageTk.PhotoImage(resized_image)
image_label = tk.Label(image=image)
image_label.pack(padx=(10, 10), pady=(40, 20))

tk.Label(text="Create a a new session, or join an existing one").pack(padx = (10, 10), pady=(40, 20))

tokenEntry = tk.Entry()
tokenEntry.insert(0, "session name")
tokenEntry.pack(pady=(5, 5))

urlEntry = tk.Entry()
urlEntry.insert(0, "server url")
urlEntry.pack(pady=(5, 5))

connectBtn = tk.Button(text="Connect", command=connect)
connectBtn.pack(pady=(5, 20))

updateLoop()

window.mainloop()
