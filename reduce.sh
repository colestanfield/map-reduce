#!/bin/bash

awk '{map[$1]+=$2} END {for(i in map) printf("%s %s\n", i, map[i])}' /dev/stdin | sort
