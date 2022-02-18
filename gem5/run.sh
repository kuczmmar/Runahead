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
  python3 ./bin/scons build/X86/gem5.opt -j33
fi

date

# define benchmark variables
BENCH_PATH='../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no'
# define paths to configuration files
O3_TWO_LEVEL='configs/runahead/o3_2level.py'
GEM='build/X86/gem5.opt'

BASE_DEBUG=""
RA_DEBUG=""
PRE_DEBUG=""
# BASE_DEBUG="--debug-flags=Commit,RunaheadCompare,RunaheadEnter,O3CPUAll"
# RA_DEBUG="--debug-flags=RunaheadDebug,CACHE,MSHR,RunaheadCommit"
# PRE_DEBUG="--debug-flags=PreEnter"
# PRE_DEBUG="--debug-flags=PreEnter,Fetch,PreDebug,Commit,PreIQ,PreIEW,PreRename,PreO3CPU"
# PRE_DEBUG="--debug-flags=PreEnter,PreDebug,Commit,PreIEW,PreO3CPU"
# PRE_DEBUG="--debug-flags=PreEnter,PreDebug,PreO3CPU"


echo_lines() {
  yes '' | sed 3q
}

run_base() {
  ARG=$1
  L2=$2
  ROB=$3
  RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
  ARG="$((ARG/1000))k"
  BASE_GEM_FLAGS="--stats-file=base/rob${ROB}_${ARG}_${L2} --dot-config=base_randacc_${ROB} --dump-config=base/rob${ROB}_${ARG}_config --json-config=base/rob${ROB}_${ARG}_config.json ${BASE_DEBUG}"
  OUT="out/base${ROB}_${ARG}_${L2}.txt"

  time $GEM $BASE_GEM_FLAGS $O3_TWO_LEVEL --mode=baseline --rob_size=$ROB --l2_size=$L2  $RANDACC > $OUT
}


run_run() {
  ARG=$1
  L2=$2
  ROB=$3
  RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
  ARG="$((ARG/1000))k"
  RA_GEM_FLAGS="--stats-file=run/rob${ROB}_${ARG}_${L2} --dot-config=run_randacc_${ROB} --dump-config=run/rob${ROB}_${ARG}_${L2}_config ${RUN_DEBUG}"
  OUT="out/run${ROB}_${ARG}_${L2}.txt"

  time $GEM $RA_GEM_FLAGS  $O3_TWO_LEVEL --mode=runahead   --rob_size=$ROB  --l2_size=$L2  $RANDACC > $OUT
}


run_pre() {
  ARG=$1
  L2=$2
  ROB=$3
  RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
  ARG="$((ARG/1000))k"
  PRE_GEM_FLAGS="--stats-file=pre/rob${ROB}_${ARG}_${L2} --dot-config=pre_randacc_${ROB} --dump-config=pre/rob${ROB}_${ARG}_${L2}_config ${PRE_DEBUG}"
  OUT="out/pre${ROB}_${ARG}_${L2}.txt"

  time $GEM $PRE_GEM_FLAGS  $O3_TWO_LEVEL --mode=pre      --rob_size=$ROB --l2_size=$L2 $RANDACC > $OUT
}

run_all() {
  run_base $1 $2 $3 &\
  run_run  $1 $2 $3 &\
  run_pre  $1 $2 $3 &\
}


# WARNING: Clears previous statistics outputs
# rm -r m5out/
# rm -r out/
mkdir -p out m5out/base m5out/run m5out/pre
echo_lines

# run_all  500000 '64kB' 192 &\
run_all  500000 '128kB' 192 &\
run_all  525000 '256kB' 192 &\
run_all 1000000 '256kB' 192 

# --l1i_size='32kB' --l1d_size='64kB' --l2_size='128kB'
wait
python3 stats/summarize_stats.py m5out stats/simple.csv

echo_lines
cat stats/simple.csv  |sed 's/,/ ,/g' | column -t -s, 


# grep -hnr -B 2 -A 2 '6072588\|6072575\|runahead' out/pre192_525k.txt > out/grepped.txt