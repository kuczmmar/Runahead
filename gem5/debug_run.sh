# python3 `which scons` build/X86/gem5.debug -j9
python3 ./bin/scons build/X86/gem5.debug -j33

wait
gdb build/X86/gem5.debug

# run configs/runahead/o3_2level.py --mode=pre --rob_size=192 --l2_size=128kB --binary=../benchmarks/cgo2017/program/randacc/bin/x86/randacc-no --binary_args 100000