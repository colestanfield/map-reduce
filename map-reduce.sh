#!/bin/bash

usage() {
	echo "Usage: $1 [?] [-m <map.sh>] [-r <reduce.sh>] [-t <tmp>] [-d] <host>[ <host>][...]" >&2
	if [ -n "$2" ] ; then
		echo "  -m map program (effectively defaults to cat)" >&2
		echo "  -r reduce program (data fed in through /dev/stdin)" >&2
		echo "  -t tmp directory (defaults to /tmp)" >&2
		echo "  -d don't clean up job files (defaults to false)" >&2
		echo "  -? prints this message" >&2
	fi
	exit 2
}

# usage: pfork cp file1 file2
# backgrounds processes to be run in parallel and later pjoined
pfork() {
    if [[ ${!forked_pids} || ! ${!forked_pids-_} ]]; then
        declare -a forked_pids
    fi
    $* &
    forked_pids+=($!)
}

# usage: pjoin
# waits for all previously pforked processes to complete
pjoin() {
    wait "${forked_pids[@]}"
    forked_pids=
}

# Defaults
map=
reduce=
tmp=/tmp
clean=true

program=$(basename $0)
while getopts "m:r:t:d" name; do
	case "$name" in
		m) map=$OPTARG;;
		r) reduce=$OPTARG;;
        t) tmp=$OPTARG;;
		d) clean=false;;
		?) usage $program MOAR;;
		*) usage $program;;
	esac
done
shift $((OPTIND - 1))

hosts=$@

if [[ -z "$hosts" ]]; then
	echo "$program: must specify hosts"
	usage $program
fi

jobid="$(uuidgen)"
job_dir=$tmp/$jobid
mkdir -p $job_dir
files=()

for host in ${hosts[@]}; do
    file=$job_dir/$host.txt
    pfork cat "$map" | ssh -T $host > $file
    files+=($file)
done

pjoin

cat ${files[@]} | sh "$reduce"

[[ $clean ]] && rm -rf $job_dir
