from m5.params import *
from m5.SimObject import SimObject

class MyObject(SimObject):
    type = 'MyObject'
    cxx_header = "baseline/my_object.hh"
    time_to_wait = Param.Latency("Time before firing the event")
    number_of_fires = Param.Int(1, "Number of times to fire the event before goodbye")