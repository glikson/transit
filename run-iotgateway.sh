#!/bin/sh
#
# Copyright 2016 IBM Corp. All Rights Reserved.
# 
# Licensed under the Apache License, Version 2.0 (the License);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#  https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an AS IS BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script creates a Docker container which acts as a virtual IoT
# gateway.
# Once running, the sensor readings are sent to Watson IoT Platform via MQTT.
# IMPORTANT: IoT Platform credentials must be specified in 'iotp.env'
#

usage()
{
	echo Usage:
	echo     `basename $0` DEVICE_ID [VALUE]
}

showenv()
{
	echo IOTP_ORG_ID=$IOTP_ORG_ID
	echo DEVICE_TYPE=$DEVICE_TYPE
	echo EVENT_TYPE=$EVENT_TYPE
	echo MSG_FORMAT=$MSG_FORMAT
	echo DEVICE_ID=$DEVICE_ID
	echo INTERVAL=$INTERVAL
	echo VALUE=$VALUE
}

cleanup() 
{
	echo rm $1
	rm -r $1
}

# Customize flows.json 
# $1 = directory containing flows.json
# $2 = IOTP_ORG_ID
# $3 = DEVICE_TYPE
# $4 = EVENT_TYPE
# $5 = MSG_FORMAT
# $6 = INTERVAL
# $7 = DEVICE_ID
# $8 = TOKEN
# $9 = VALUE
customize_flows()
{

sed -i 's/__IOTP_ORG_ID__/'$2'/g' $1/flows.json
if [ $? -ne 0 ];
then
	echo Error updating IoTP orgId in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__DEVICE_TYPE__/'$3'/g' $1/flows.json
if [ $? -ne 0 ];
then
	echo Error updating device type in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__EVENT_TYPE__/'$4'/g' $1/flows.json
if [ $? -ne 0 ];
then
	echo Error updating event type in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__MSG_FORMAT__/'$5'/g' $1/flows.json
if [ $? -ne 0 ];
then
	echo Error updating message format in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__INTERVAL__/'$6'/g' $1/flows.json
if [ $? -ne 0 ];
then
	echo Error updating interval in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__DEVICE_ID__/'$7'/g' $1/flows.json
if [ $? -ne 0 ];
then
	echo Error updating ID in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__DEVICE_ID__/'$7'/g' $1/functions/device_payload.js
if [ $? -ne 0 ];
then
	echo Error updating ID in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__TOKEN__/'$8'/g' $1/flows_cred.json
if [ $? -ne 0 ];
then
	echo Error updating credentials in node-red flow
	cleanup $1
	return 4
fi
sed -i 's/__VALUE__/'$9'/g' $1/functions/sensor_readings.js
if [ $? -ne 0 ];
then
	echo Error updating value in node-red flow
	cleanup $1
	return 4
fi
}

############
### MAIN ###
############
HOMEDIR=`dirname $0`

if [ ! -f $HOMEDIR/iotp.env ]; then
	echo Configuration file iotp.env not found
	exit 1
fi 

# Default value. Could be overriden via iotp.env, or via command line argument.
VALUE=30

. $HOMEDIR/iotp.env

DEVICE_ID=$1

if [ -z "$DEVICE_ID" ];
then
	echo DEVICE_ID not specified
	usage
	return 1
fi
if [ ! -z "$2" ];
then
	VALUE=$2
fi

# The convention is to have token in format "token-<DEVICE_ID>"
# The token is assigned in the Watson IoT Platform when creating a device
# Note that it is adviced to have more secure tokens (requiring changes in this script)

TOKEN=token-${DEVICE_ID}

if [ -z "$IOTP_ORG_ID" -o -z "$DEVICE_TYPE" -o -z "$EVENT_TYPE" -o -z "$MSG_FORMAT" -o -z "$INTERVAL" -o -z "$DEVICE_ID" -o -z "$TOKEN" -o -z "$VALUE" ];
then
	echo Missing parameters in iotp.env
	showenv
	return 2
fi

TEMPLATE=$HOMEDIR/node-red/template
DATA=$HOMEDIR/node-red/data-${DEVICE_ID}

if [ ! -d "$TEMPLATE" ];
then
	echo Directory $TEMPLATE not found
	return 3
fi

rm -rf $DATA 2>/dev/null

echo DEVICE_ID: $DEVICE_ID

cp -pr $TEMPLATE $DATA
if [ $? -ne 0 ];
then
	echo Error copying data directory
	cleanup $DATA
	return 3
fi
customize_flows $DATA $IOTP_ORG_ID $DEVICE_TYPE $EVENT_TYPE $MSG_FORMAT $INTERVAL $DEVICE_ID $TOKEN $VALUE

sudo docker run -d -it --name=${DEVICE_ID} -P -v `realpath $DATA`:/data nodered/node-red-docker
if [ $? -ne 0 ];
then 
	echo Error running docker container
	cleanup $DATA
	return 5
fi

