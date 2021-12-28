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
  # python3 `which scons` build/X86/gem5.opt -j9
  python3 ./bin/scons build/X86/gem5.opt -j17
fi

# define benchmark variables
BENCH_PATH='../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no'
ARG=1000000
RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
# RANDACC='--binary=/home/marta/runahead/test'

# define paths to configuration files
O3_TWO_LEVEL='configs/runahead/o3_2level.py'

# GEM_FLAGS='--stats-file=baseline/2level_randacc --dot-config=base_2level_randacc --debug-flags=RunaheadEnter'
# RUN_GEM_FLAGS='--stats-file=runahead/2level_randacc --dot-config=run_2level_randacc --debug-flags=RunaheadEnter'
GEM='build/X86/gem5.opt'
ARG="${ARG/$1000}k"
BASE64_GEM_FLAGS="--stats-file=base/rob64_${ARG} --dot-config=base_randacc"
BASE192_GEM_FLAGS="--stats-file=base/rob192_${ARG} --dot-config=base_randacc"
RA64_GEM_FLAGS="--stats-file=run/rob64_${ARG} --dot-config=run_randacc_64"
RA192_GEM_FLAGS="--stats-file=run/rob192_${ARG} --dot-config=run_randacc_192"
PRE64_GEM_FLAGS="--stats-file=pre/rob64_${ARG} --dot-config=pre_randacc_64"
PRE192_GEM_FLAGS="--stats-file=pre/rob192_${ARG} --dot-config=pre_randacc_192"
# CACHE,MSHR,RunaheadCommit

BASE='out/base.txt'
BASE192='out/base192.txt'
RA='out/ra.txt'
RA192='out/ra192.txt'
PRE64='out/pre64.txt'
PRE192='out/pre192.txt'

echo_lines() {
  yes '' | sed 3q
}

echo_lines

# WARNING: Clears previous statistics outputs
rm -r m5out/
rm -r out/
mkdir m5out && mkdir out && mkdir m5out/base && mkdir m5out/run && mkdir m5out/pre
rm $RA $BASE

# run two level of cache setup on randacc benchmark with varying rob size
$GEM $BASE64_GEM_FLAGS  $O3_TWO_LEVEL --mode=baseline --rob_size=64   $RANDACC > $BASE  &\
$GEM $BASE192_GEM_FLAGS $O3_TWO_LEVEL --mode=baseline --rob_size=192  $RANDACC > $BASE192  &\
$GEM $RA64_GEM_FLAGS    $O3_TWO_LEVEL --mode=runahead --rob_size=64   $RANDACC > $RA &\
$GEM $RA192_GEM_FLAGS   $O3_TWO_LEVEL --mode=runahead --rob_size=192  $RANDACC > $RA192 &\
$GEM $PRE64_GEM_FLAGS   $O3_TWO_LEVEL --mode=pre      --rob_size=64   $RANDACC > $PRE64 &\
$GEM $PRE192_GEM_FLAGS  $O3_TWO_LEVEL --mode=pre      --rob_size=192  $RANDACC > $PRE192

# --l1i_size='32kB' --l1d_size='64kB'
wait
python3 stats/summarize_stats.py m5out stats/simple.csv

echo_lines
cat stats/simple.csv  |sed 's/,/ ,/g' | column -t -s, 

# python3 `which scons` build/X86/gem5.debug -j9
# gdb build/X86/gem5.debug
# run configs/runahead/o3_2level.py --mode=runahead --binary=/home/marta/runahead/benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 100
# run configs/runahead/o3_2level.py --binary=/home/marta/runahead/benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 100
# run configs/runahead/o3_2level.py --mode=runahead --binary=/home/marta/runahead/test

