
function mhpost(args) {
    return new Promise(function(resolve, reject) {
        if (!args.topic || !args.messages || !args.messages[0] || !args.kafka_rest_url || !args.api_key)
            reject("Invalid arguments. Must include topic, messages[], kafka_rest_url, api_key.");

        // construct CF-style VCAP services JSON
        var vcap_services = {
            "messagehub": [
            {
                "credentials": {
                    "kafka_rest_url": args.kafka_rest_url,
                    "api_key": args.api_key,
                },
            }
            ]
        };
        var MessageHub = require('message-hub-rest');
        var kafka = new MessageHub(vcap_services);

        kafka.produce(args.topic, args.messages)
        .then(function() {
            resolve({"result": "ok"});
        })
        .fail(function(error) {
            reject(error);
        });

    });
}

exports.main = mhpost;
