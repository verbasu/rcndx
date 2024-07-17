#!/bin/bash

# Indexer and server (cargo install tantivy-cli)
TNV=tantivy

# JSON transformer, jq analog (cargo install --locked jaq)
JQ=jaq

TRNS='data_prepared/rsessions_transformed.json'

# Index configuration with special fields and options
NDXDIR=rsessions_index
NDXCFG=${NDXDIR}/meta.json

INPUT=$1 # || rsessions.json

LOG=./$$.log

if [[ ! `which $TNV` || ! `which $JQ` ]]; then echo "No tools found"; exit 1; fi
if [[ ! -f $INPUT ]]; then echo "No input file $INPUT"; exit 1; fi
if [[ ! -f $NDXCFG ]]; then echo "No index config found $NDXCFG"; exit 1; fi
touch $TRNS || exit 1

function rsessions_transform() {
	# -c switch at jq is needed to create valid JSON 
	cat $INPUT | $JQ -c '.[] 
		| select( .device != null ) 
		| select( .device.os != null) 
		| { "id": ._id, "day": .day, "month": .month, "year": .year, "userId": .userId, 
		"role": .mostImportantRole, "host": .host, "ip": .ip, "devicetype": .device.type, 
		"devicename": .device.name, "deviceos": .device.os.name, "deviceosver": .device.os.version }' > $TRNS
}

function create_index() {
	cat $TRNS | tantivy index -i $NDXDIR > $LOG 2>&1
}

echo -n Transform mongo collection dump... 
rsessions_transform && echo Done
echo Create index... 
create_index
