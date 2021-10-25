#include "my_object.hh"
#include "base/logging.hh"
#include "base/trace.hh"
#include "debug/MyExample.hh"

#include <iostream>

MyObject::MyObject(const gem5::MyObjectParams &params) :
    SimObject(params),
    event([this]{ processEvent(); }, name() + ".event"),
    // event(*this),
    myName(params.name),
    latency(params.time_to_wait),
    timesLeft(params.number_of_fires){
    // SimObject(params),
    // event([this]{processEvent();}, name()),
    // latency(100), timesLeft(10)

    DPRINTF(MyExample, "Created the MY hello object\n");
    // run with 
    // build/X86/gem5.opt --debug-flags=MyExample src/baseline/run_my.py
}

void MyObject::startup()
{
    // Before simulation starts, we need to schedule the event
    schedule(event, latency);
}

void MyObject::processEvent()
{
    timesLeft--;
    DPRINTF(MyExample, "Hello world! Processing the event! %d left\n", timesLeft);

    if (timesLeft <= 0) {
        DPRINTF(MyExample, "Done firing!\n");
        // goodbye->sayGoodbye(myName);
    } else {
        schedule(event, curTick() + latency);
    }
}