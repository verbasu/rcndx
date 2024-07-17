#!/bin/bash

# Indexer and server (cargo install tantivy-cli)
TNV="tantivy"

# JSON transformer, jq analog (cargo install --locked jaq)
JQ="jaq -c"

INPUT=rsessions.json

if [[ ! `which $TNV` || ! `which $JQ` ]]; then echo "No tools found"; exit 1
if [[ !-f $INPUT ]]; then echo "No input file $INPUT"; exit 1

function rsessions_transform() {
	cat $INPUT | $JQ '.[] 
		| select( .device != null ) 
		| select( .device.os != null) 
		| { "id": ._id, "day": .day, "month": .month, "year": .year, "userId": .userId, 
		"role": .mostImportantRole, "host": .host, "ip": .ip, "devicetype": .device.type, 
		"devicename": .device.name, "deviceos": .device.os.name, "deviceosver": .device.os.version }'
}

rsessions_transform
