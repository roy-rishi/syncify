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

def togglePlayerState():
    result = subprocess.run(["osascript", "-e", 'tell application "Spotify" to playpause'], capture_output=True, text=True)
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
client_id = None
lastUpdate = None
takeControlNow = False
def connect():
    global session_token
    global server_url
    global client_id

    print("connecting to server...")
    session_token = tokenEntry.get()
    print(urlEntry.get())
    server_url = urlEntry.get()
    print(session_token)
    print(server_url)

    response = requests.get(server_url + "/connect")
    client_id = json.loads(response.text)["clientId"]
    print("client id: " + str(client_id))

def takeControl():
    global takeControlNow
    print("taking control...")
    takeControlNow = True


def updateLoop():
    global lastUpdate
    global takeControlNow

    print("\nsyncing...")
    if session_token == None or server_url == None:
        window.after(5000, updateLoop)
        return None
    
    # get controller
    response = requests.post(server_url + "/get-controller", headers={"Content-Type": "application/json"}, data=json.dumps({"session_token": session_token, "client_id": client_id}))
    controller = response.text
    print("controller: " + controller)

    trackTS = gettrackLoc()
    trackID = gettrackID()
    playerState = getPlayerState()
    print(f"track loc   : {trackTS}")
    print(f"track id    : {trackID}")
    print(f"player state: {playerState}")
    print(f"server url  : {server_url}")

    dataS = {"session_token": session_token,
            "timestamp": str(trackTS),
            "id": str(trackID),
            "player-state": str(playerState),
            "controller": client_id
            }
    print(dataS)

    # this client is the controller
    if int(response.text) == client_id or takeControlNow:
        print("this is the controller")
        takeControlNow = False

        try:
            response = requests.post(server_url + "/send-timestamp", headers={"Content-Type": "application/json"}, data=json.dumps(dataS))
            # print("response:", response.text)
            # input("line 96")
            # serverUpdate = json.loads(response.text)
        except requests.exceptions.RequestException as e:
            print(f"error sending data to server: {e}")

    # this client is not the controller
    else:
        print("this is NOT the controller")
        try:
            response = requests.post(server_url + "/get-timestamp", headers={"Content-Type": "application/json"}, data=json.dumps({"session_token": session_token}))
            print("response:", response.text)
            serverUpdate = json.loads(response.text)

            if serverUpdate != None and serverUpdate["timestamp"] != "missing value":
                if trackID != serverUpdate["id"]:
                    print("changing this player track...")
                    setTrackID(serverUpdate["id"])
                    dataS["id"] = serverUpdate["id"]
                if abs(float(trackTS) - float(serverUpdate["timestamp"])) >= 3:
                    print("changing this player timestamp...")
                    setPlayerPos(serverUpdate["timestamp"])
                    dataS["timestamp"] = serverUpdate["timestamp"]
                if playerState != serverUpdate["player-state"]:
                    togglePlayerState()

        except requests.exceptions.RequestException as e:
            print(f"error sending data to server: {e}")

    lastUpdate = dataS

    window.after(5000, updateLoop)
    return None


window = tk.Tk()
# 16:10 landscape aspect ratio
# window.geometry("856x535")
# 4:3 portrait aspect ratio
window.geometry("428x570")
window.title("Syncify")

# title
title = tk.Label(text="Syncify", font=("Avenir Next", 60))
title.pack(padx = (5, 5), pady=(40, 5))

# image
baseDir = os.path.dirname(__file__)
filePath = os.path.join(baseDir, 'img/syncify.png')
original_image = Image.open(filePath)
width, height = 180, 180
resized_image = original_image.resize((width, height), Image.LANCZOS)
image = ImageTk.PhotoImage(resized_image)
image_label = tk.Label(image=image)
image_label.pack(padx=(5, 5), pady=(15, 0))

tk.Label(text="Start a new session\nor connect to an existing one", font=("Arial", 16)).pack(padx = (5, 5), pady=(5, 5))

tokenEntry = tk.Entry()
tokenEntry.insert(0, "session name")
tokenEntry.pack(pady=(5, 5))

urlEntry = tk.Entry()
urlEntry.insert(0, "server url")
urlEntry.pack(pady=(5, 5))

connectBtn = tk.Button(text="Connect", command=connect)
connectBtn.pack(pady=(5, 5))

controlBtn = tk.Button(text="Take Control", command=takeControl)
controlBtn.pack(pady=(5, 20))

updateLoop()

window.mainloop()
