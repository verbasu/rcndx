#!/bin/bash

BASE='http://localhost:7280'

## Check if curl exists. If not - exit
which curl > /dev/null || exit 1;

## Compile it (cd qwingest; cargo run --bin ndxmsg; cp -a ./target/debug/ndxmsg ~/.cargo/bin/)
which ndxmsg > /dev/null || exit 1;

## JSON transformer, jq analog (cargo install --locked jaq)
JQ=jaq

## Still and patient curl
CRL='curl -k -s -H "Accept: application/json" '

VER=`$CRL -X GET $BASE/api/v1/version | $JQ -c '.build.version'`

echo "Quickwit Version: $VER"

if [ "x$VER" != "x\"v0.8.2\"" ]; then exit 1; fi

V1="$BASE/api/v1"

TRNS='messages_transformed.json'

# Index configuration with special fields and options
# Quickwit index config
NDXCFG=messages-index-config.yaml

LOG=./$$.log

if [[ ! -f $NDXCFG ]]; then echo "No index config found $NDXCFG"; exit 1; fi
touch $TRNS || exit 1

function get_messages() {
	time ndxmsg get 1000000 $TRNS > $LOG 2>&1
}

function delete_old_index() {
	$CRL -XDELETE "$V1/indexes/messages" > $LOG 2>&1
}

function create_index_quickwit() {
	$CRL -XPOST "$V1/indexes" --header "content-type: application/yaml" --data-binary @$NDXCFG > $LOG 2>&1 &&
	# $CRL -XPOST "$V1/messages/ingest?commit=force" --data-binary @$TRNS >> $LOG 2>&1
	quickwit index ingest --index messages --input-path $TRNS --force
}

function search_query() {
	echo -n "Hits number: "
	$CRL -XGET "$V1/messages/search?query=msg:app" | $JQ '.num_hits'
}

echo -n Get messages from mongo... 
#get_messages && echo Done

## Optional
echo -n Deleting index if exist... 
delete_old_index && echo Done

echo -n Create index... 
create_index_quickwit && echo Done

## Test query
search_query
