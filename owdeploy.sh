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

# This script deploys OpenWhisk artifacts associated with the
# message transformation logic
#
# Arguments:
#  - none, all the inputs are gathered from messagehub.env
#    which must reside in the same directory as the script
#  - optional: --cleanup

usage()
{
	echo Usage:
	echo     `basename $0` [--cleanup]
}

die()
{
	echo Error: $?
	exit 1
}

showenv()
{
	echo ADMIN_URL=${ADMIN_URL}
	echo REST_URL=${REST_URL}
	echo BROKERS=${BROKERS}
	echo USER=${USER}
	echo PASSWORD=${PASSWORD}
	echo API_KEY=${API_KEY}
	echo IOTP_TOPIC=${IOTP_TOPIC}
	echo TRANSFORMED_TOPIC=${TRANSFORMED_TOPIC}
}

cleanup() {
	wsk rule delete --disable ${IOTP_TOPIC}-to-${TRANSFORMED_TOPIC} 2>/dev/null
	wsk trigger delete ${IOTP_TOPIC}-trigger 2>/dev/null
	wsk action delete iotp2${TRANSFORMED_TOPIC} 2>/dev/null
	wsk action delete iotp2flat 2>/dev/null
	wsk action delete kafka/mhpost 2>/dev/null
	wsk package delete kafka 2>/dev/null
	wsk package delete kafka-${TRANSFORMED_TOPIC} 2>/dev/null
}


############
### MAIN ###
############
HOMEDIR=`dirname $0`
OW=$HOMEDIR/openwhisk

# read config file (key=value format)
if [ ! -f $HOMEDIR/messagehub.env ];
then
	echo Configuration file $HOMEDIR/messagehub.env not found
	exit 1
fi

. $HOMEDIR/messagehub.env

if [ -z "$ADMIN_URL" -o -z "$REST_URL" -o -z "$BROKERS" -o -z "$USER" -o -z "$PASSWORD" -o -z "$IOTP_TOPIC" -o -z "$TRANSFORMED_TOPIC" ];
then
	echo Error in Message Hub  configuration parameters specified in messagehub.env
	showenv
	exit 2
fi

# check arguments and perform cleanup if requested
if [ "$#" -ne 0 ];
then
	if [ "$#" -eq 1 -a "$1" = "--cleanup" ];
	then 
		echo Cleaning up..
		cleanup
		exit 0
	else
		echo Wrong arguments
		usage
		exit 9
	fi
fi

echo Cleaning up before setup 
cleanup

NAMESPACE=`wsk property get --namespace | awk '{print \$3}'`
echo Namespace: $NAMESPACE

echo -n "Setting up Message Hub package: "

wsk package create kafka && echo Done creating kafka package || die
wsk action create kafka/mhpost ${HOMEDIR}/action/mhpost/mhpost.zip --kind nodejs:6 && echo Done creating mhpost action || die
wsk package bind kafka kafka-${TRANSFORMED_TOPIC} --param api_key $API_KEY --param kafka_rest_url $REST_URL --param topic ${TRANSFORMED_TOPIC} && echo Done creating package binding || die

echo -n "Setting up trigger: "

wsk trigger create ${IOTP_TOPIC}-trigger --feed /whisk.system/messaging/messageHubFeed --param kafka_brokers_sasl $BROKERS --param user $USER --param password $PASSWORD --param kafka_admin_url $ADMIN_URL --param isJSONData false --param topic ${IOTP_TOPIC} && echo Done || die

echo -n "Setting up sequence: "
wsk action create iotp2flat action/iotp2flat/iotp2flat.js && echo Done creating iotp2flat || die
wsk action create --sequence iotp2${TRANSFORMED_TOPIC} iotp2flat,kafka-${TRANSFORMED_TOPIC}/mhpost && echo Done creating sequence || die

echo -n "Setting up rule: "
wsk rule create ${IOTP_TOPIC}-to-${TRANSFORMED_TOPIC} ${IOTP_TOPIC}-trigger iotp2${TRANSFORMED_TOPIC} && echo Done || die


echo All Set!

