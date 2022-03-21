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
# PRE_DEBUG="--debug-flags=PreEnter,Fetch,PreDebug,Commit,PreIQ,PreIEW,PreRename,PreO3CPU"
# PRE_DEBUG="--debug-flags=PreEnter,PreDebug,Commit,PreIEW,PreO3CPU,PreRename,PreIQ"


echo_lines() {
  yes '' | sed 3q
}

run_base() {
  ARG=$1
  L2=$2
  ROB=$3
  RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
  ARG="$((ARG/1000))k"
  NAME="rob${ROB}_${ARG}_${L2}"
  BASE_GEM_FLAGS="--stats-file=base/${NAME} --json-config=base/${NAME}_config.json ${BASE_DEBUG}"
  OUT="out/base_${NAME}.txt"

  time $GEM $BASE_GEM_FLAGS $O3_TWO_LEVEL --mode=baseline --rob_size=$ROB --l2_size=$L2  $RANDACC > $OUT
}


run_run() {
  ARG=$1
  L2=$2
  ROB=$3
  RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
  ARG="$((ARG/1000))k"
  NAME="rob${ROB}_${ARG}_${L2}"
  RA_GEM_FLAGS="--stats-file=run/${NAME} --json-config=run/${NAME}_config.json ${RUN_DEBUG}"
  OUT="out/run_${NAME}.txt"

  time $GEM $RA_GEM_FLAGS  $O3_TWO_LEVEL --mode=runahead   --rob_size=$ROB  --l2_size=$L2  $RANDACC > $OUT
}


run_pre() {
  ARG=$1
  L2=$2
  ROB=$3
  RANDACC="--binary=${BENCH_PATH} --binary_args ${ARG}"
  ARG="$((ARG/1000))k"
  NAME="rob${ROB}_${ARG}_${L2}"
  PRE_GEM_FLAGS="--stats-file=pre/${NAME} --json-config=pre/${NAME}_config.json ${PRE_DEBUG}"
  OUT="out/pre_${NAME}.txt"

  time $GEM $PRE_GEM_FLAGS  $O3_TWO_LEVEL --mode=pre      --rob_size=$ROB --l2_size=$L2 $RANDACC > $OUT
}

run_all() {
  run_base $1 $2 $3 &\
  run_run  $1 $2 $3 &\
  run_pre  $1 $2 $3 
}


# WARNING: Clears previous statistics outputs
# rm -r m5out/
# rm -r out/
mkdir -p out m5out/base m5out/run m5out/pre
echo_lines

run_all  100000 '64kB' 128  &
run_pre  525000 '256kB' 128  &  # crash
run_pre  525000 '256kB' 64   &  # crash
run_all  525000 '128kB' 192  &   # crash
run_all  1000000 '256kB' 192 &
run_pre  525000 '128kB' 192   &   # runs
run_pre  525000 '256kB' 192  & # runs
run_all  525000 '256kB' 192 &
run_all  500000 '256kB' 192 &
run_all  500000 '128kB' 192 &


# runs fine:
run_all  100000 '128kB' 128 &
run_all  100000 '128kB' 128 &
run_all  100000 '128kB' 64
# run_pre  100000 '64kB' 64 &
# run_all  50000 '128kB' 128 & 
# run_pre  50000 '64kB' 128 & 
# run_all  60000 '128kB' 128 &
# run_pre  60000 '64kB' 128

# --l1i_size='32kB' --l1d_size='64kB' --l2_size='128kB'
wait
wait
wait
python3 stats/summarize_stats.py m5out stats/simple.csv

echo_lines
cat stats/simple.csv  |sed 's/,/ ,/g' | column -t -s, 

# grep -hnr -B 4 -A 4 '2676394\|2676393' out/pre_rob64_525k_256kB.txt > out/grepped.txt
