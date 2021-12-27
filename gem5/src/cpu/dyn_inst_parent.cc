#include "dyn_inst_parent.hh"

namespace gem5 {

DynInstParent::DynInstParent(InstSeqNum seq_num) : seqNum(seq_num)
{}

void
DynInstParent::addReq(RequestPtr req)
{   
  _outstandingReqs.emplace_back(req);
  if (_runaheadInst) {
      req->setGeneratedInRunahead();
  }
}

void 
DynInstParent::reqCompleted(RequestPtr req) 
{
  // remove the completed request
  for (int i=0; i<_outstandingReqs.size(); ++i) {
      if (_outstandingReqs[i].get() == req.get()) {
          _outstandingReqs.erase(_outstandingReqs.begin() + i);
      }
  }
}

void 
DynInstParent::setRunaheadInst() { 
    _runaheadInst = true;
    for (auto r : _outstandingReqs) {
        r->setGeneratedInRunahead(); 
    }
}


void 
DynInst::setTriggeredRunahead() 
{ 
    assert(numOutstandingRequests() > 0);
    _triggeredRunahead = true; 
    setRunaheadInst();
}

} //namespace gem5