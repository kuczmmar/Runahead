#!/bin/bash

compile=false
while getopts 'c' flag; do
  case "${flag}" in
    c) compile=true ;;
    *) print_usage
       exit 1 ;;
  esac
done

if $compile ; then
  echo "Compiling gem5"
  python3 `which scons` build/X86/gem5.opt -j9
fi

# define benchmark variables
RANDACC='--binary=/home/marta/runahead/benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 100'

# define paths to configuration files
TWO_LEVEL='configs/learning_gem5/part1/two_level.py'
O3_TWO_LEVEL='configs/runahead/o3_2level.py'

GEM_FLAGS='--stats-file=baseline/2level_randacc'
RUN_GEM_FLAGS='--stats-file=runahead/2level_randacc --debug-flags=RunaheadO3CPU'
OUT='out.txt'

echo_lines() {
  yes '' | sed 3q
}

print_new_line() {
  echo_lines
  echo '' >> $OUT && echo '------------------' >> $OUT && echo '' >> $OUT
}


# WARNING: Clears previous statistics outputs
rm -r m5out/
mkdir m5out && mkdir m5out/baseline && mkdir m5out/runahead

# run two level of cache setup on randacc benchmark
build/X86/gem5.opt $GEM_FLAGS $O3_TWO_LEVEL $RANDACC > $OUT
print_new_line

build/X86/gem5.opt $RUN_GEM_FLAGS $O3_TWO_LEVEL --mode=runahead --l1i_size='64kB' \
  --l1d_size='128kB' $RANDACC >> $OUT
print_new_line


python stats/summarize_stats.py m5out stats/simple.csv

echo_lines
cat stats/simple.csv  |sed 's/,/ ,/g' | column -t -s, 
