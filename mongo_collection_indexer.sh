#!/bin/bash

# Indexer and server (cargo install tantivy-cli)
TNV=tantivy

# JSON transformer, jq analog (cargo install --locked jaq)
JQ=jaq

TRNS=transformed.json

INPUT=$1 # || rsessions.json

if [[ ! `which $TNV` || ! `which $JQ` ]]; then echo "No tools found"; exit 1; fi
if [[ ! -f $INPUT ]]; then echo "No input file $INPUT"; exit 1; fi
if [[ ! touch $TRNS ]]; then echo "Can't create file"; exit 1; fi

function rsessions_transform() {
	# -c switch at jq is needed to create valid JSON 
	cat $INPUT | $JQ -c '.[] 
		| select( .device != null ) 
		| select( .device.os != null) 
		| { "id": ._id, "day": .day, "month": .month, "year": .year, "userId": .userId, 
		"role": .mostImportantRole, "host": .host, "ip": .ip, "devicetype": .device.type, 
		"devicename": .device.name, "deviceos": .device.os.name, "deviceosver": .device.os.version }' > $TRNS
}

rsessions_transform
