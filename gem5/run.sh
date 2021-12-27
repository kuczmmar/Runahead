#!/bin/bash
export M5_BUILD_CACHE=$M5_PATH/build/cache

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
BENCH_PATH='../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no'
ARG=1000
RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
# RANDACC='--binary=/home/marta/runahead/test'

# define paths to configuration files
O3_TWO_LEVEL='configs/runahead/o3_2level.py'

# GEM_FLAGS='--stats-file=baseline/2level_randacc --dot-config=base_2level_randacc --debug-flags=RunaheadEnter'
# RUN_GEM_FLAGS='--stats-file=runahead/2level_randacc --dot-config=run_2level_randacc --debug-flags=RunaheadEnter'
GEM='build/X86/gem5.opt'
GEM_FLAGS="--stats-file=base/rand_${ARG} --dot-config=base_randacc"
RA64_GEM_FLAGS="--stats-file=run/rand_rob64_${ARG} --dot-config=run_randacc_64"
RA192_GEM_FLAGS="--stats-file=run/rand_rob192_${ARG} --dot-config=run_randacc_192"
PRE64_GEM_FLAGS="--stats-file=pre/rand_rob64_${ARG} --dot-config=pre_randacc_64"
PRE192_GEM_FLAGS="--stats-file=pre/rand_rob192_${ARG} --dot-config=pre_randacc_192"
# CACHE,MSHR,RunaheadCommit


# RunaheadO3CPU
RA='ra.txt'
RA192='ra192.txt'
BASE='base.txt'
PRE64='pre64.txt'
PRE192='pre192.txt'

echo_lines() {
  yes '' | sed 3q
}

# print_new_line() {
#   echo_lines
#   echo '' >> $OUT && echo '------------------' >> $OUT && echo '' >> $OUT
# }


# WARNING: Clears previous statistics outputs
rm -r m5out/
mkdir m5out && mkdir m5out/base && mkdir m5out/run && mkdir m5out/pre
rm $RA $BASE

# run two level of cache setup on randacc benchmark
$GEM $GEM_FLAGS $O3_TWO_LEVEL --rob_size=64 $RANDACC > $BASE 
$GEM $RA64_GEM_FLAGS $O3_TWO_LEVEL --mode=runahead --rob_size=64 $RANDACC >> $RA
# $GEM $RA192_GEM_FLAGS $O3_TWO_LEVEL --mode=runahead --rob_size=192 $RANDACC >> $RA192
$GEM $PRE64_GEM_FLAGS $O3_TWO_LEVEL --mode=pre --rob_size=64 $RANDACC >> $PRE64
# --l1i_size='32kB' --l1d_size='64kB'

python stats/summarize_stats.py m5out stats/simple.csv

echo_lines
cat stats/simple.csv  |sed 's/,/ ,/g' | column -t -s, 

# python3 `which scons` build/X86/gem5.debug -j9
# gdb build/X86/gem5.debug
# run configs/runahead/o3_2level.py --mode=runahead --binary=/home/marta/runahead/benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 100
# run configs/runahead/o3_2level.py --binary=/home/marta/runahead/benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 100
# run configs/runahead/o3_2level.py --mode=runahead --binary=/home/marta/runahead/test

