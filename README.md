# syncify
Sync spotify players across two or more devices on separate accounts.

## usage
The client app must be ran on each device. Whichever client starts first chooses a code and shares it for the other client to use to join the same session. The server can differntiate between different sessions, allowing for concurrent sessions. [DMG installers](https://github.com/roy-rishi/syncify/releases) for macOS are included, but may not be up to date. Tested on macOS Ventura (13.3 22E252 arm64), macOS Ventura (13.5.1 22G90 Intel), and macOS Monterey (Intel). Compatible with macOS 11.0 and above.

The server must be run on a central computer or on any one of the devices running the client app and should be accessible by both client apps.
### run clients
The session name is shared between clients that will sync together. One client becomes the controller, but others may gain control by pressing the corresponding button.
![client demo](/docs/img/client.png)
Upon clicking "Connect", you may be prompted to allow Apple Events.
![client demo](/docs/img/apple-events.png)
### run server
* `cd PATH_TO/syncify/server`
* `npm install`
* `node server.js`
* `ngrok http 3000`


## build client
* __dependencies__
* macOS
* uncomment the following and hardcode the server url before building, or uncomment it and leave the string equal to "" to leave a textfield for the the user to enter a url. The url will persist between sessions
```
//struct Config {
//    static let SERVER_URL = ""
//}
```
* build `syncify-client/` in Xcode
