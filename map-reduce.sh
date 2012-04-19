#!/bin/bash

usage() {
	echo "Usage: $1 [?] [-m <map.sh>] [-r <reduce.sh>] [-t <tmp>] <host>[ <host>][...]" >&2
	if [ -n "$2" ] ; then
		echo "  -m map program (effectively defaults to cat)" >&2
		echo "  -r reduce program (data fed in through /dev/stdin)" >&2
		echo "  -t tmp directory (defaults to /tmp)" >&2
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

program=$(basename $0)
while getopts "m:r:t:" name; do
	case "$name" in
		m) map=$OPTARG;;
		r) reduce=$OPTARG;;
        t) tmp=$OPTARG;;
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

echo "job: $job_dir" >&2

for host in ${hosts[@]}; do
    file=$job_dir/$host.txt
    pfork cat "$map" | ssh -T $host > $file
    files+=($file)
done

pjoin

cat ${files[@]} | sh "$reduce" > $job_dir/output.txt

cat $job_dir/output.txt
