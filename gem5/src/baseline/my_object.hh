#ifndef __MY_OBJECT_HH__
#define __MY_OBJECT_HH__

#include "params/MyObject.hh"
#include "sim/sim_object.hh"

using namespace gem5;

class MyObject : public gem5::SimObject
{
  private:
    /**
     * Example function to execute on an event trigger
     */
    void processEvent();

    /// An event that wraps the above function
    EventFunctionWrapper event;

    // /// Pointer to the corresponding GoodbyeObject. Set via Python
    // GoodbyeObject* goodbye;

    // /// The name of this object in the Python config file
    const std::string myName;

    /// Latency between calling the event (in ticks)
    const Tick latency;

    /// Number of times left to fire the event before goodbye
    int timesLeft;

  public:
    MyObject(const gem5::MyObjectParams &p);
    
    void startup();
};


#endif // __MY_OBJECT_HH__