// Generate an array of sensor readings
// {"location" : {"longitude": longitude, 
//                "latidute": lat},
//  "velocity" : velocity}
var lon = [-98.49,-97.74,-96.79,-94.20,-90.19,-94.57,-87.62,-87.90,-93.26,-95.99];
var lat = [29.42,30.26,32.77,36.37,38.62,39.09,41.87,43.03,44.97,41.25];

var velocity = context.global.get('velocity')||0;
var max = __VALUE__;   // max velocity
var delta = Math.floor(Math.random() * 5);
var dir = Math.floor(Math.random() * 3);
var mult = 0;
switch(dir) {
    case 0:
        mult = 1;
        break;
    case 1:
        mult = -1;
        break;
    default:
        // mult is 0
        break;
}
velocity = velocity+mult*delta;
if(velocity > max) velocity=max;
if(velocity < 0) velocity=0;

context.global.set('velocity',velocity);

var counter = Math.floor(Math.random() * 10);

msg.payload = JSON.stringify(
    {
        "location" : {
            "longitude" : lon[counter],
            "latitude" : lat[counter]
        },
        "velocity" : velocity
    }
);

return msg;

