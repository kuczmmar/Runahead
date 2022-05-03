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
RANDACC='../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no'
CG='../benchmarks/cgo2017/program/nas-cg/bin/x86/cg-no2'
IS='../benchmarks/cgo2017/program/nas-is/bin/x86/is-no1'
HASHJOIN2='../benchmarks/cgo2017/program/hashjoin-ph-2/src/bin/x86/hj2-no'
HASHJOIN8='./../benchmarks/cgo2017/program/hashjoin-ph-8/src/bin/x86/hj8-no'
GRAPH500='../benchmarks/cgo2017/program/graph500/bin/x86/g500-no'

SUSAN='../benchmarks/cbench/automotive_susan_c/src/a.out'
SUSAN_ARG='../benchmarks/cbench/automotive_susan_data/1.pgm,out/output_susan.pgm,-c'

BZIP2D='./../benchmarks/cbench/bzip2d/src/a.out'
BZIP2D_ARG='../benchmarks/cbench/bzip2_data/1.bz2,-d,-k,-f,--stdout'

CONSUMER_LAME='./../benchmarks/cbench/consumer_lame/src/a.out'
CONSUMER_ARG='../benchmarks/cbench/consumer_data/1.wav,out/consumer_output_large.mp3'

QSORT='./../benchmarks/cbench/automotive_qsort1/src/a.out'
QSORT_ARG='../benchmarks/cbench/automotive_qsort_data/1.dat,out/qsort_output.dat,out/qsort_out'

DIJKSTRA='./../benchmarks/cbench/network_dijkstra/src/a.out'
DIJKSTRA_ARG='../benchmarks/cbench/network_dijkstra_data/1.dat'
 

# define paths to configuration files
O3_TWO_LEVEL='configs/runahead/o3_2level.py'
GEM='build/X86/gem5.opt'

BASE_DEBUG=""
RA_DEBUG=""
PRE_DEBUG=""
# RA_DEBUG="--debug-flags=RunaheadDebug,RunaheadEnter,RunaheadRename"
# PRE_DEBUG="--debug-flags=PreEnter,PreDebug,PrePRDQ,Commit,PrePipelineDebug,PreIEW,PreO3CPU,PreRename,PreIQ"
# PRE_DEBUG="--debug-flags=PreEnter,PreDebug,PrePRDQ,PrePipelineDebug"

echo_lines() {
  yes '' | sed 3q
}

run_base() {
  ARG=$1;  L2=$2;  ROB=$3;  BENCH_NAME=$4;  BENCH_PATH=$5
  PROGRAM="--binary=${BENCH_PATH} "
  if ! test -z $ARG; then PROGRAM+="--binary_args ${ARG}"; fi
  NAME="${BENCH_NAME}_rob${ROB}_${L2}"

  BASE_GEM_FLAGS="--stats-file=base/${NAME} --json-config=base/${NAME}_config.json ${BASE_DEBUG}"
  OUT="out/base_${NAME}.txt"

  time $GEM $BASE_GEM_FLAGS $O3_TWO_LEVEL --mode=baseline --rob_size=$ROB --l2_size=$L2  $PROGRAM > $OUT
}


run_run() {
  ARG=$1;  L2=$2;  ROB=$3;  BENCH_NAME=$4;  BENCH_PATH=$5
  PROGRAM="--binary=${BENCH_PATH} "
  if ! test -z $ARG; then PROGRAM+="--binary_args ${ARG}"; fi
  NAME="${BENCH_NAME}_rob${ROB}_${L2}"

  RA_GEM_FLAGS="--stats-file=run/${NAME} --json-config=run/${NAME}_config.json ${RA_DEBUG}"
  OUT="out/run_${NAME}.txt"

  time $GEM $RA_GEM_FLAGS  $O3_TWO_LEVEL --mode=runahead   --rob_size=$ROB  --l2_size=$L2  $PROGRAM > $OUT
}


run_pre() {
  ARG=$1;  L2=$2;  ROB=$3;  BENCH_NAME=$4;  BENCH_PATH=$5; ADD_FLAGS=$6
  PROGRAM="--binary=${BENCH_PATH} "
  if ! test -z $ARG; then PROGRAM+="--binary_args ${ARG}"; fi
  NAME="${BENCH_NAME}_rob${ROB}_${L2}"
  
  PRE_GEM_FLAGS="--stats-file=pre/${NAME} --json-config=pre/${NAME}_config.json ${PRE_DEBUG}"
  OUT="out/pre_${NAME}.txt"

  time $GEM $PRE_GEM_FLAGS  $O3_TWO_LEVEL --mode=pre  --rob_size=$ROB --l2_size=$L2 $ADD_FLAGS  $PROGRAM > $OUT
}


run_all_pre_options() {
  ARG=$1;  L2=$2;  ROB=$3;  BENCH_NAME=$4;  BENCH_PATH=$5
  run_pre $ARG $L2 $ROB "${BENCH_NAME}NoRrr" $BENCH_PATH "--rrr_enabled=False" &
  run_pre $ARG $L2 $ROB "${BENCH_NAME}NoRrrNoSst" $BENCH_PATH "--sst_enabled=False --rrr_enabled=False" &
  run_pre $ARG $L2 $ROB "${BENCH_NAME}NoSst" $BENCH_PATH "--sst_enabled=False "
}


run_all() {
  run_base "$@" &  run_run  "$@" &  run_pre  "$@"
}


run_all_randacc() {
  ARG=$1; BNAME="randacc$((ARG/1000))k";
  run_base "$@" $BNAME $RANDACC &
  run_run  "$@" $BNAME $RANDACC &
  run_pre  "$@" $BNAME $RANDACC
}

run_all_benchmarks() {
  L2=$1; ROB=$2;
  # run_all_randacc 200000        $L2 $ROB &
  # run_all_randacc 500000        $L2 $ROB &
  # run_all_randacc 600000        $L2 $ROB &
  # run_all         $DIJKSTRA_ARG $L2 $ROB "dijkstra" $DIJKSTRA &
  # run_all         $SUSAN_ARG    $L2 $ROB "susan"  $SUSAN &
  # run_all         $QSORT_ARG    $L2 $ROB "qsort"  $QSORT &
  # run_all         $BZIP2D_ARG   $L2 $ROB "bzip2d" $BZIP2D &
  # run_all         ""            $L2 $ROB "cg"     $CG &
  # run_all         $CONSUMER_ARG $L2 $ROB "consumer" $CONSUMER_LAME &
  run_all         ""            $L2 $ROB "is"     $IS &
  run_all         ""            $L2 $ROB "hj2" $HASHJOIN2
}


# WARNING: Clears previous statistics outputs
# rm -r m5out/
# rm -r out/
mkdir -p out m5out/base m5out/run m5out/pre
echo_lines

ROBS=( 64 96 128 160 192 )
L2S=( '64kB' '128kB' '256kB')

for r in ${ROBS[@]}; do 
  for l in ${L2S[@]}; do 
    echo $r, $l; run_all_benchmarks $l $r &
  done
done


## Random access benchmark runs
# TMP=600000; echo "randacc$((TMP/1000))k"; 
# run_all_pre_options 600000 '128kB' 192 "randacc$((TMP/1000))k" $RANDACC &
# TMP=1000000; 
# run_all_pre_options $TMP '128kB' 192 "randacc$((TMP/1000))k" $RANDACC &
# run_all_randacc     $TMP '128kB' 192 &
# TMP=500000; ROB=81;
# run_all_pre_options          $TMP '128kB' $ROB "randacc$((TMP/1000))k" $RANDACC &
# run_all_randacc              $TMP '128kB' $ROB



## Bzip2d
# run_pre          $BZIP2D_ARG  '256kB' 160 "bzip2d" $BZIP2D

run_all "" '128kB' 96 "g500" $GRAPH500  & # RA crashes
run_all "" '128kB' 96 "hj8" $HASHJOIN8  # RA crashes




wait
wait
wait
python3 stats/summarize_stats.py m5out stats/simple.csv
echo "----------------------------------------------------"
cat stats/simple.csv  |sed 's/,/ ,/g' | column -t -s, 

# grep -hnr -B 4 -A 4 'physical reg 189 (IntReg\|physical reg 189 (189)\|PRDQ\|1951381\|runahead\|1951379\|PhysReg: 189' out/pre_randacc500k_rob192_128kB.txt > out/grepped.txt
# head -n 100000 out/grepped.txt > out/grepped.txt

# grep -hnr 'to physical reg 189 \|Freeing register 189 (IntRegClass)\|old mapping was 189 ' out/pre_randacc500k_rob192_128kB.txt > out/grepped2.txt

# build/X86/gem5.opt --stats-file=run/d_rob81_256kB --json-config=run/dij_rob81_256kB_config.json configs/runahead/o3_2level.py --mode=runahead --rob_size=81 --l2_size=256kB --binary=./../benchmarks/cbench/network_dijkstra/src/a.out  --binary_args ../benchmarks/cbench/network_dijkstra_data/1.dat