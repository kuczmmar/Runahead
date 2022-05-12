# File defining parameters of memory objects
# these values are set to be default for objects in caches.py

# from gem5.src.cpu.pred.BranchPredictor import LTAGE_TAGE, BranchPredictor


class L1():
  assoc = 2
  tag_latency = 2
  data_latency = 2
  response_latency = 2
  mshrs = 4
  tgts_per_mshr = 20

  i_size = '32kB'
  d_size = '32kB'

  i_assoc = 4
  d_assoc = 8
  i_latency = 2
  d_latency = 4

class L2():
    size = '256kB' # 256
    assoc = 8
    latency = 8 # 20
    tag_latency = latency
    data_latency = latency
    response_latency = latency
    mshrs = 20
    tgts_per_mshr = 12


LQEntries = 64
SQEntries = 64
numIQEntries = 92
# branchPred = LTAGE_TAGE