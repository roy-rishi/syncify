const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

var lastUpdate = [];

function updateLast(array, newData) {
    let found = false;
    for (let i = 0; i < array.length; i++) {
        if (array[i]["token"] === newData["token"]) {
            array[i] = newData;
            found = true;
            return;
        }
    }
    array.push(newData);
}

function responseInfo(array, token) {
    for (let i = 0; i < array.length; i++) {
        if (array[i]["token"] === token) {
            return array[i];
        }
    }
    return null;
}

app.use(bodyParser.json());

app.post('/receive-timestamp', (req, res) => {
    const receivedData = req.body;
    console.log('\nreceived:', receivedData);

    // copy new instance of last update to send back at end of request
    let tempOldUpdate = JSON.parse(JSON.stringify(lastUpdate));
    
    console.log("last updates", lastUpdate);
    updateLast(lastUpdate, { "token": receivedData["session_token"], "data": receivedData["data"]});
    
    res.send(JSON.stringify(responseInfo(tempOldUpdate, receivedData["session_token"])));
});

app.listen(port, () => {
    console.log(`server is listening on port ${port}`);
});
