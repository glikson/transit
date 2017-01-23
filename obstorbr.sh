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

# This script deploys Object Storage bridge in Message Hub
#
# Arguments:
#  - none, all the inputs are gathered from messagehub.env and objectstorage.env
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
	echo API_KEY=${API_KEY}
	echo TRANSFORMED_TOPIC=${TRANSFORMED_TOPIC}
	echo OBJECT_STORAGE_AUTH_URL=${OBJECT_STORAGE_AUTH_URL}
	echo OBJECT_STORAGE_TENANT_ID=${OBJECT_STORAGE_TENANT_ID}
	echo OBJECT_STORAGE_USER_ID=${OBJECT_STORAGE_USER_ID}
	echo OBJECT_STORAGE_REGION=${OBJECT_STORAGE_REGION}
	echo OBJECT_STORAGE_CONTAINER=${OBJECT_STORAGE_CONTAINER}
	echo SIZE_THRESHOLD_KB=${SIZE_THRESHOLD_KB}
	echo DURATION_THRESHOLD_SEC=${DURATION_THRESHOLD_SEC}
}

cleanup() {
curl -X DELETE ${ADMIN_URL}/admin/bridges/taxi -H "X-Auth-Token:${API_KEY}" -H "Content-type:application/json" 2>/dev/null
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

if [ ! -f $HOMEDIR/objectstorage.env ];
then
	echo Configuration file $HOMEDIR/objectstorage.env not found
	exit 1
fi

. $HOMEDIR/messagehub.env
. $HOMEDIR/objectstorage.env

if [ -z "$ADMIN_URL" -o -z "$API_KEY" -o -z "$TRANSFORMED_TOPIC" -o -z "$SIZE_THRESHOLD_KB" -o -z "$DURATION_THRESHOLD_SEC" ];
then
	echo Error in Message Hub configuration parameters specified in messagehub.env
	showenv
	exit 2
fi

if [ -z "$OBJECT_STORAGE_AUTH_URL" -o -z "$OBJECT_STORAGE_TENANT_ID" -o -z "$OBJECT_STORAGE_USER_ID" -o -z "$OBJECT_STORAGE_PASSWORD" -o -z "$OBJECT_STORAGE_REGION" -o -z "$OBJECT_STORAGE_CONTAINER" ];
then
	echo Error in Object Storage configuration parameters specified in objectstorage.env
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

echo -n "Setting up Message Hub bridge to Object Storage: "

curl -X POST ${ADMIN_URL}/admin/bridges -H "X-Auth-Token:${API_KEY}" -H "Content-type:application/json" -d "{\"configuration\":{\"container\":\"${OBJECT_STORAGE_CONTAINER}\",\"credentials\":{\"authUrl\":\"${OBJECT_STORAGE_AUTH_URL}\",\"password\":\""${OBJECT_STORAGE_PASSWORD}"\",\"region\":\"${OBJECT_STORAGE_REGION}\",\"projectId\":\"${OBJECT_STORAGE_TENANT_ID}\",\"userId\":\"${OBJECT_STORAGE_USER_ID}\"},\"inputFormat\":\"json\",\"uploadSizeThresholdKB\":${SIZE_THRESHOLD_KB},\"partitioning\":[{\"type\":\"dateIso8601\",\"propertyName\":\"timestamp\"}],\"uploadDurationThresholdSeconds\":${DURATION_THRESHOLD_SEC}},\"name\":\"taxi\",\"topic\":\"${TRANSFORMED_TOPIC}\",\"type\":\"objectStorageOut\"}" && echo Done || die

echo All Set!

