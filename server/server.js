const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

var lastUpdate = [];
var controller = [];
var assignedTo = -1;

function updateLast(array, newData) {
    let found = false;
    for (let i = 0; i < array.length; i++) {
        if (array[i]["session_token"] === newData["session_token"]) {
            array[i] = newData;
            found = true;
            return;
        }
    }
    array.push(newData);
}

function responseInfo(array, token) {
    for (let i = 0; i < array.length; i++) {
        if (array[i]["session_token"] === token) {
            return array[i];
        }
    }
    return null;
}

app.use(bodyParser.json());

app.get('/connect', (req, res) => {
    let clientId = assignedTo + 1;
    assignedTo++;
    console.log('\nconnecting client ', clientId);
    res.send({"clientId": clientId});
});

app.post('/send-timestamp', (req, res) => {
    console.log("\n/send-timestamp")
    const receivedData = req.body;
    console.log('received:', receivedData);
    
    console.log("last updates", lastUpdate);
    updateLast(lastUpdate, receivedData);
    res.send(JSON.stringify(responseInfo(lastUpdate, receivedData["session_token"])));
});

app.post('/get-timestamp', (req, res) => {
    console.log("/get-timestamp")
    const receivedData = req.body;
    console.log('\nreceived:', receivedData);

    res.send(JSON.stringify(responseInfo(lastUpdate, receivedData["session_token"])));
});

app.post('/get-controller', (req, res) => {
    console.log("\n/get-controller")
    const receivedData = req.body;
    console.log('received:', receivedData);

    if (responseInfo(lastUpdate, receivedData["session_token"]) == null) {
        lastUpdate.push({"session_token": receivedData["session_token"],
        "timestamp": "missing value",
        "id": "missing value",
        "player-state": "missing value"
       })
    }
    if (responseInfo(controller, receivedData["session_token"]) == null) {
       controller.push({"session_token": receivedData["session_token"],
                        "client_id": receivedData["client_id"]})
    }

    console.log("controller is " + responseInfo(controller, receivedData["session_token"])["client_id"]);
    res.send(JSON.stringify(responseInfo(controller, receivedData["session_token"])["client_id"]));
});

app.post('/set-controller', (req, res) => {
    console.log("\n/set-controller")
    const receivedData = req.body;
    console.log('received:', receivedData);
    
    updateLast(controller, receivedData);
    res.send(JSON.stringify(responseInfo(lastUpdate, receivedData["session_token"])));
});

app.listen(port, () => {
    console.log(`server is listening on port ${port}`);
});
