/**
Transformation of messages read from Message Hub feed originated from IoTP into a flat JSON

Example input:
{
	"messages": [
    	{
            "partition": 0,
            "key": "{\"orgId\":\"9zdck8\",\"deviceType\":\"nrsim_device\",\"deviceId\":\"dev1\",\"eventType\":\"myevent\",\"format\":\"json\",\"timestamp\":\"2017-01-04T13:11:33.601+02\"}",
            "offset": 107,
            "topic": "nrsim_events",
            "value": <BLOB-with-compressed-sensor-data>
        },
        { ... }
    ]
}

Expected output:
{
	"messages": [
		{
			"orgId": "9zdck8",
			"deviceType": "taxi",
			"deviceId": "taxi1",
			"eventType": "update",
			"timestamp": "2017-01-04T13:11:33.601+02",
			"payload" : {
				"velocity": 8,
				"type": "taxi",
				"name": "taxi1",
				"location": {
					"latitude": 39.09,
					"longitude": -94.57
				}
			}
		}
		<, ...>
	]
}

**/

function main(params) {
	zlib = require('zlib');
	return new Promise(function(resolve, reject) {
		if (!params.messages || !params.messages[0] || !params.messages[0].key || !params.messages[0].value) {
			reject("Invalid arguments. Must include 'messages' JSON array with 'key' and 'value' fields");
		}
		var msgs = params.messages;
		var out = [];
		for (var i=0; i<msgs.length; i++){
			var msg = msgs[i];
			console.log ("Processing MSG=" + JSON.stringify(msg));
			var key = JSON.parse(msg.key);
			var buf = Buffer.from(msg.value, "base64");
			var sensorReadings = JSON.parse(zlib.gunzipSync(buf))["d"].sensor_data;
			console.log ("sensor data: " + sensorReadings);
			for (var j=0; j<sensorReadings.length; j++) {
				newmsg = {
					orgId: key.orgId,
					deviceType: key.deviceType,
					deviceId: key.deviceId,
					eventType: key.eventType,
					timestamp: key.timestamp.substr(0,19),
					sensorData: sensorReadings[j]
					};
				out.push(newmsg);
				console.log("result: " + newmsg);
			}
		}
		resolve({ "messages": out });
	});
}

