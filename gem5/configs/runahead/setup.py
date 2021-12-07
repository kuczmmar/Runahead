# File defining parameters of memory objects
# these values are set to be default for objects in caches.py

ROB_size = 192 # default is 192

class L1():
  assoc = 2
  tag_latency = 2
  data_latency = 2
  response_latency = 2
  mshrs = 4
  tgts_per_mshr = 20

  i_size = '16kB'
  d_size = '32kB'
  ra_size = '16kB'

class L2():
    size = '256kB'
    assoc = 8
    tag_latency = 20
    data_latency = 20
    response_latency = 20
    mshrs = 20
    tgts_per_mshr = 12