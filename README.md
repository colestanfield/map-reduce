Simple Map-Reduce Script
========================
    
Overview
--------

A simple Bash script to do map-reduce style computations on distributed data. Designed to analyze log files stored locally on many hosts. For each host listed, the `map.sh` script is executed remotely and should return a key-value pair separated by whitespace. The values returned from each host is then piped to the `reduce.sh` script. The output of that script is printed to `stdout`.


Usage
-----

    map-reduce.sh [?] [-m <map.sh>] [-r <reduce.sh>] [-t <tmp>] <host>[ <host>][...]