#!/bin/bash

BASE='http://localhost:7280'

## Check if curl exists. If not - exit
which curl > /dev/null || exit 1;

## JSON transformer, jq analog (cargo install --locked jaq)
JQ=jaq

## Still and patient curl
CRL='curl -k -s -H "Accept: application/json" '

VER=`$CRL -X GET $BASE/api/v1/version | $JQ -c '.build.version'`

echo "Quickwit Version: $VER"

if [ "x$VER" != "x\"v0.8.2\"" ]; then exit 1; fi

V1="$BASE/api/v1"

TRNS='data_prepared/rsessions_transformed.json'

# Index configuration with special fields and options
# Quickwit index config
NDXCFG=rsessions-index-config.yaml

INPUT=$1 # || rsessions.json
LOG=./$$.log

if [[ ! -f $INPUT ]]; then echo "No input file $INPUT"; exit 1; fi
if [[ ! -f $NDXCFG ]]; then echo "No index config found $NDXCFG"; exit 1; fi
touch $TRNS || exit 1

function rsessions_transform() {
	# -c switch at jq is needed to create valid JSON 
	cat $INPUT | $JQ -c '.[] 
		| select( .device != null ) 
		| select( .device.os != null) 
		| { "day": .day, "month": .month, "year": .year, "userId": .userId, 
		"role": .mostImportantRole, "host": .host, "ip": .ip, "devicetype": .device.type, 
		"devicename": .device.name, "deviceos": .device.os.name, "deviceosver": .device.os.version }' > $TRNS
}

function delete_old_index() {
	$CRL -XDELETE "$V1/indexes/rsessions" > $LOG 2>&1
}

function create_index_quickwit() {
	$CRL -XPOST "$V1/indexes" --header "content-type: application/yaml" --data-binary @$NDXCFG > $LOG 2>&1 &&
	$CRL -XPOST "$V1/rsessions/ingest?commit=force" --data-binary @$TRNS >> $LOG 2>&1
}

function search_query() {
	echo -n "Hits number: "
	$CRL -XGET "$V1/rsessions/search?query=desktop-app" | $JQ '.num_hits'
}

echo -n Transform mongo collection dump... 
rsessions_transform && echo Done

## Optional
echo -n Deleting index if exist... 
delete_old_index && echo Done

echo -n Create index... 
create_index_quickwit && echo Done

## Test query
search_query
