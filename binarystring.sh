#!/usr/bin/bash
echo -n '"'
cat $1 | xxd -p -u -c 100000 | awk '{gsub(/../,"\\x\u00&"); printf "%s", $0}'
echo '"'
