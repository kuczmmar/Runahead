# python3 `which scons` build/X86/gem5.debug -j9
python3 ./bin/scons build/X86/gem5.debug -j33

wait
gdb build/X86/gem5.debug

# run configs/runahead/o3_2level.py --mode=pre --binary=../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 525000
# run configs/runahead/o3_2level.py --binary=../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 1000
# run configs/runahead/o3_2level.py --mode=runahead --binary=/home/marta/runahead/test
# run configs/runahead/o3_2level.py --mode=pre --rob_size=192 --l2_size=32kB --binary=../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 100000