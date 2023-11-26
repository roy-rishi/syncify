# syncify
Sync spotify players across two or more devices on separate accounts.

## usage
The client app must be ran on each device. Whichever client starts first chooses a code and shares it for the other client to use to join the same session. The server can differntiate between different sessions, allowing for concurrent sessions (untested). [DMG installers](https://github.com/roy-rishi/syncify/releases) for macOS are included, but all other operating systems must be manually built according to the following intructions. Tested on macOS Ventura (13.3 22E252 arm64) and macOS Ventura (13.5.1 22G90 Intel).

The server must be run on a central computer or on any one of the devices running the client app and should be accessible by both client apps.
### run clients
All clients must share a session name. The server url can be a public ip for using with devices on the same network, or a proxy tunnel. 
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
* uncomment the following and hardcode the server url before building, or uncomment it and leave the string equal to "" to prompt the user for a url
```
//struct Config {
//    static let SERVER_URL = ""
//}
```
* build `syncify-client/` in Xcode