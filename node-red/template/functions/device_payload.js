var id = "__DEVICE_ID__";
var type = "Taxi";
var sensor_data = msg.payload;
msg.payload = { 
    d:{
        "id" : id,
     	 "type" : type,
        "sensor_data": sensor_data
    }
}
 
return msg;
