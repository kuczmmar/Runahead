/*
 * Copyright (c) 2004-2005 The Regents of The University of Michigan
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met: redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer;
 * redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution;
 * neither the name of the copyright holders nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "cpu/pre/mem_dep_unit.hh"

#include <map>
#include <memory>
#include <vector>

#include "base/compiler.hh"
#include "base/debug.hh"
#include "cpu/pre/dyn_inst.hh"
#include "cpu/pre/inst_queue.hh"
#include "cpu/pre/limits.hh"
#include "debug/PreMemDepUnit.hh"
#include "params/PreO3CPU.hh"

namespace gem5
{

namespace pre
{

#ifdef DEBUG
int MemDepUnit::MemDepEntry::memdep_count = 0;
int MemDepUnit::MemDepEntry::memdep_insert = 0;
int MemDepUnit::MemDepEntry::memdep_erase = 0;
#endif

MemDepUnit::MemDepUnit() : iqPtr(NULL), stats(nullptr) {}

MemDepUnit::MemDepUnit(const PreO3CPUParams &params)
    : _name(params.name + ".memdepunit"),
      depPred(params.store_set_clear_period, params.SSITSize,
              params.LFSTSize),
      iqPtr(NULL),
      stats(nullptr)
{
    DPRINTF(PreMemDepUnit, "Creating MemDepUnit object.\n");
}

MemDepUnit::~MemDepUnit()
{
    for (ThreadID tid = 0; tid < MaxThreads; tid++) {

        ListIt inst_list_it = instList[tid].begin();

        MemDepHashIt hash_it;

        while (!instList[tid].empty()) {
            hash_it = memDepHash.find((*inst_list_it)->seqNum);

            assert(hash_it != memDepHash.end());

            memDepHash.erase(hash_it);

            instList[tid].erase(inst_list_it++);
        }
    }

#ifdef DEBUG
    assert(MemDepEntry::memdep_count == 0);
#endif
}

void
MemDepUnit::init(const PreO3CPUParams &params, ThreadID tid, CPU *cpu)
{
    DPRINTF(PreMemDepUnit, "Creating MemDepUnit %i object.\n",tid);

    _name = csprintf("%s.memDep%d", params.name, tid);
    id = tid;

    depPred.init(params.store_set_clear_period, params.SSITSize,
            params.LFSTSize);

    std::string stats_group_name = csprintf("MemDepUnit__%i", tid);
    cpu->addStatGroup(stats_group_name.c_str(), &stats);
}

MemDepUnit::MemDepUnitStats::MemDepUnitStats(statistics::Group *parent)
    : statistics::Group(parent),
      ADD_STAT(insertedLoads, statistics::units::Count::get(),
               "Number of loads inserted to the mem dependence unit."),
      ADD_STAT(insertedStores, statistics::units::Count::get(),
               "Number of stores inserted to the mem dependence unit."),
      ADD_STAT(conflictingLoads, statistics::units::Count::get(),
               "Number of conflicting loads."),
      ADD_STAT(conflictingStores, statistics::units::Count::get(),
               "Number of conflicting stores.")
{
}

bool
MemDepUnit::isDrained() const
{
    bool drained = instsToReplay.empty()
                 && memDepHash.empty()
                 && instsToReplay.empty();
    for (int i = 0; i < MaxThreads; ++i)
        drained = drained && instList[i].empty();

    return drained;
}

void
MemDepUnit::drainSanityCheck() const
{
    assert(instsToReplay.empty());
    assert(memDepHash.empty());
    for (int i = 0; i < MaxThreads; ++i)
        assert(instList[i].empty());
    assert(instsToReplay.empty());
    assert(memDepHash.empty());
}

void
MemDepUnit::takeOverFrom()
{
    // Be sure to reset all state.
    loadBarrierSNs.clear();
    storeBarrierSNs.clear();
    depPred.clear();
}

void
MemDepUnit::setIQ(InstructionQueue *iq_ptr)
{
    iqPtr = iq_ptr;
}

void
MemDepUnit::insertBarrierSN(const DynInstPtr &barr_inst)
{
    InstSeqNum barr_sn = barr_inst->seqNum;

    if (barr_inst->isReadBarrier() || barr_inst->isHtmCmd())
        loadBarrierSNs.insert(barr_sn);
    if (barr_inst->isWriteBarrier() || barr_inst->isHtmCmd())
        storeBarrierSNs.insert(barr_sn);

    if (debug::PreMemDepUnit) {
        const char *barrier_type = nullptr;
        if (barr_inst->isReadBarrier() && barr_inst->isWriteBarrier())
            barrier_type = "memory";
        else if (barr_inst->isReadBarrier())
            barrier_type = "read";
        else if (barr_inst->isWriteBarrier())
            barrier_type = "write";

        if (barrier_type) {
            DPRINTF(PreMemDepUnit, "Inserted a %s barrier %s SN:%lli\n",
                    barrier_type, barr_inst->pcState(), barr_sn);
        }

        if (loadBarrierSNs.size() || storeBarrierSNs.size()) {
            DPRINTF(PreMemDepUnit, "Outstanding load barriers = %d; "
                                "store barriers = %d\n",
                    loadBarrierSNs.size(), storeBarrierSNs.size());
        }
    }
}

void
MemDepUnit::insert(const DynInstPtr &inst)
{
    ThreadID tid = inst->threadNumber;

    MemDepEntryPtr inst_entry = std::make_shared<MemDepEntry>(inst);

    // Add the MemDepEntry to the hash.
    memDepHash.insert(
        std::pair<InstSeqNum, MemDepEntryPtr>(inst->seqNum, inst_entry));
#ifdef DEBUG
    MemDepEntry::memdep_insert++;
#endif

    instList[tid].push_back(inst);

    inst_entry->listIt = --(instList[tid].end());

    // Check any barriers and the dependence predictor for any
    // producing memrefs/stores.
    std::vector<InstSeqNum>  producing_stores;
    if ((inst->isLoad() || inst->isAtomic()) && hasLoadBarrier()) {
        DPRINTF(PreMemDepUnit, "%d load barriers in flight\n",
                loadBarrierSNs.size());
        producing_stores.insert(std::end(producing_stores),
                                std::begin(loadBarrierSNs),
                                std::end(loadBarrierSNs));
    } else if ((inst->isStore() || inst->isAtomic()) && hasStoreBarrier()) {
        DPRINTF(PreMemDepUnit, "%d store barriers in flight\n",
                storeBarrierSNs.size());
        producing_stores.insert(std::end(producing_stores),
                                std::begin(storeBarrierSNs),
                                std::end(storeBarrierSNs));
    } else {
        InstSeqNum dep = depPred.checkInst(inst->instAddr());
        if (dep != 0)
            producing_stores.push_back(dep);
    }

    std::vector<MemDepEntryPtr> store_entries;

    // If there is a producing store, try to find the entry.
    for (auto producing_store : producing_stores) {
        DPRINTF(PreMemDepUnit, "Searching for producer [sn:%lli]\n",
                            producing_store);
        MemDepHashIt hash_it = memDepHash.find(producing_store);

        if (hash_it != memDepHash.end()) {
            store_entries.push_back((*hash_it).second);
            DPRINTF(PreMemDepUnit, "Producer found\n");
        }
    }

    // If no store entry, then instruction can issue as soon as the registers
    // are ready.
    if (store_entries.empty()) {
        DPRINTF(PreMemDepUnit, "No dependency for inst PC "
                "%s [sn:%lli].\n", inst->pcState(), inst->seqNum);

        assert(inst_entry->memDeps == 0);

        if (inst->readyToIssue()) {
            inst_entry->regsReady = true;

            moveToReady(inst_entry);
        }
    } else {
        // Otherwise make the instruction dependent on the store/barrier.
        DPRINTF(PreMemDepUnit, "Adding to dependency list\n");
        for (GEM5_VAR_USED auto producing_store : producing_stores)
            DPRINTF(PreMemDepUnit, "\tinst PC %s is dependent on [sn:%lli].\n",
                inst->pcState(), producing_store);

        if (inst->readyToIssue()) {
            inst_entry->regsReady = true;
        }

        // Clear the bit saying this instruction can issue.
        inst->clearCanIssue();

        // Add this instruction to the list of dependents.
        for (auto store_entry : store_entries)
            store_entry->dependInsts.push_back(inst_entry);

        inst_entry->memDeps = store_entries.size();

        if (inst->isLoad()) {
            ++stats.conflictingLoads;
        } else {
            ++stats.conflictingStores;
        }
    }

    // for load-acquire store-release that could also be a barrier
    insertBarrierSN(inst);

    if (inst->isStore() || inst->isAtomic()) {
        DPRINTF(PreMemDepUnit, "Inserting store/atomic PC %s [sn:%lli].\n",
                inst->pcState(), inst->seqNum);

        depPred.insertStore(inst->instAddr(), inst->seqNum,
                inst->threadNumber);

        ++stats.insertedStores;
    } else if (inst->isLoad()) {
        ++stats.insertedLoads;
    } else {
        panic("Unknown type! (most likely a barrier).");
    }
}

void
MemDepUnit::insertNonSpec(const DynInstPtr &inst)
{
    insertBarrier(inst);

    // Might want to turn this part into an inline function or something.
    // It's shared between both insert functions.
    if (inst->isStore() || inst->isAtomic()) {
        DPRINTF(PreMemDepUnit, "Inserting store/atomic PC %s [sn:%lli].\n",
                inst->pcState(), inst->seqNum);

        depPred.insertStore(inst->instAddr(), inst->seqNum,
                inst->threadNumber);

        ++stats.insertedStores;
    } else if (inst->isLoad()) {
        ++stats.insertedLoads;
    } else {
        panic("Unknown type! (most likely a barrier).");
    }
}

void
MemDepUnit::insertBarrier(const DynInstPtr &barr_inst)
{
    ThreadID tid = barr_inst->threadNumber;

    MemDepEntryPtr inst_entry = std::make_shared<MemDepEntry>(barr_inst);

    // Add the MemDepEntry to the hash.
    memDepHash.insert(
        std::pair<InstSeqNum, MemDepEntryPtr>(barr_inst->seqNum, inst_entry));
#ifdef DEBUG
    MemDepEntry::memdep_insert++;
#endif

    // Add the instruction to the instruction list.
    instList[tid].push_back(barr_inst);

    inst_entry->listIt = --(instList[tid].end());

    insertBarrierSN(barr_inst);
}

void
MemDepUnit::regsReady(const DynInstPtr &inst)
{
    DPRINTF(PreMemDepUnit, "Marking registers as ready for "
            "instruction PC %s [sn:%lli].\n",
            inst->pcState(), inst->seqNum);

    MemDepEntryPtr inst_entry = findInHash(inst);

    inst_entry->regsReady = true;

    if (inst_entry->memDeps == 0) {
        DPRINTF(PreMemDepUnit, "Instruction has its memory "
                "dependencies resolved, adding it to the ready list.\n");

        moveToReady(inst_entry);
    } else {
        DPRINTF(PreMemDepUnit, "Instruction still waiting on "
                "memory dependency.\n");
    }
}

void
MemDepUnit::nonSpecInstReady(const DynInstPtr &inst)
{
    DPRINTF(PreMemDepUnit, "Marking non speculative "
            "instruction PC %s as ready [sn:%lli].\n",
            inst->pcState(), inst->seqNum);

    MemDepEntryPtr inst_entry = findInHash(inst);

    moveToReady(inst_entry);
}

void
MemDepUnit::reschedule(const DynInstPtr &inst)
{
    instsToReplay.push_back(inst);
}

void
MemDepUnit::replay()
{
    DynInstPtr temp_inst;

    // For now this replay function replays all waiting memory ops.
    while (!instsToReplay.empty()) {
        temp_inst = instsToReplay.front();

        MemDepEntryPtr inst_entry = findInHash(temp_inst);

        DPRINTF(PreMemDepUnit, "Replaying mem instruction PC %s [sn:%lli].\n",
                temp_inst->pcState(), temp_inst->seqNum);

        moveToReady(inst_entry);

        instsToReplay.pop_front();
    }
}

void
MemDepUnit::completed(const DynInstPtr &inst)
{
    DPRINTF(PreMemDepUnit, "Completed mem instruction PC %s [sn:%lli].\n",
            inst->pcState(), inst->seqNum);

    ThreadID tid = inst->threadNumber;

    // Remove the instruction from the hash and the list.
    MemDepHashIt hash_it = memDepHash.find(inst->seqNum);

    assert(hash_it != memDepHash.end());

    instList[tid].erase((*hash_it).second->listIt);

    (*hash_it).second = NULL;

    memDepHash.erase(hash_it);
#ifdef DEBUG
    MemDepEntry::memdep_erase++;
#endif
}

void
MemDepUnit::completeInst(const DynInstPtr &inst)
{
    wakeDependents(inst);
    completed(inst);
    InstSeqNum barr_sn = inst->seqNum;

    if (inst->isWriteBarrier() || inst->isHtmCmd()) {
        assert(hasStoreBarrier());
        storeBarrierSNs.erase(barr_sn);
    }
    if (inst->isReadBarrier() || inst->isHtmCmd()) {
        assert(hasLoadBarrier());
        loadBarrierSNs.erase(barr_sn);
    }
    if (debug::PreMemDepUnit) {
        const char *barrier_type = nullptr;
        if (inst->isWriteBarrier() && inst->isReadBarrier())
            barrier_type = "Memory";
        else if (inst->isWriteBarrier())
            barrier_type = "Write";
        else if (inst->isReadBarrier())
            barrier_type = "Read";

        if (barrier_type) {
            DPRINTF(PreMemDepUnit, "%s barrier completed: %s SN:%lli\n",
                                barrier_type, inst->pcState(), inst->seqNum);
        }
    }
}

void
MemDepUnit::wakeDependents(const DynInstPtr &inst)
{
    // Only stores, atomics and barriers have dependents.
    if (!inst->isStore() && !inst->isAtomic() && !inst->isReadBarrier() &&
        !inst->isWriteBarrier() && !inst->isHtmCmd()) {
        return;
    }

    MemDepEntryPtr inst_entry = findInHash(inst);

    for (int i = 0; i < inst_entry->dependInsts.size(); ++i ) {
        MemDepEntryPtr woken_inst = inst_entry->dependInsts[i];

        if (!woken_inst->inst) {
            // Potentially removed mem dep entries could be on this list
            continue;
        }

        DPRINTF(PreMemDepUnit, "Waking up a dependent inst, "
                "[sn:%lli].\n",
                woken_inst->inst->seqNum);

        assert(woken_inst->memDeps > 0);
        woken_inst->memDeps -= 1;

        if ((woken_inst->memDeps == 0) &&
            woken_inst->regsReady &&
            !woken_inst->squashed) {
            moveToReady(woken_inst);
        }
    }

    inst_entry->dependInsts.clear();
}

MemDepUnit::MemDepEntry::MemDepEntry(const DynInstPtr &new_inst) :
    inst(new_inst)
{
#ifdef DEBUG
    ++memdep_count;

    DPRINTF(PreMemDepUnit,
            "Memory dependency entry created. memdep_count=%i %s\n",
            memdep_count, inst->pcState());
#endif
}

MemDepUnit::MemDepEntry::~MemDepEntry()
{
    for (int i = 0; i < dependInsts.size(); ++i) {
        dependInsts[i] = NULL;
    }
#ifdef DEBUG
    --memdep_count;

    DPRINTF(PreMemDepUnit,
            "Memory dependency entry deleted. memdep_count=%i %s\n",
            memdep_count, inst->pcState());
#endif
}

void
MemDepUnit::squash(const InstSeqNum &squashed_num, ThreadID tid)
{
    if (!instsToReplay.empty()) {
        ListIt replay_it = instsToReplay.begin();
        while (replay_it != instsToReplay.end()) {
            if ((*replay_it)->threadNumber == tid &&
                (*replay_it)->seqNum > squashed_num) {
                instsToReplay.erase(replay_it++);
            } else {
                ++replay_it;
            }
        }
    }

    ListIt squash_it = instList[tid].end();
    --squash_it;

    MemDepHashIt hash_it;

    while (!instList[tid].empty() &&
           (*squash_it)->seqNum > squashed_num) {

        DPRINTF(PreMemDepUnit, "Squashing inst [sn:%lli]\n",
                (*squash_it)->seqNum);

        loadBarrierSNs.erase((*squash_it)->seqNum);

        storeBarrierSNs.erase((*squash_it)->seqNum);

        hash_it = memDepHash.find((*squash_it)->seqNum);

        assert(hash_it != memDepHash.end());

        (*hash_it).second->squashed = true;

        (*hash_it).second = NULL;

        memDepHash.erase(hash_it);
#ifdef DEBUG
        MemDepEntry::memdep_erase++;
#endif

        instList[tid].erase(squash_it--);
    }

    // Tell the dependency predictor to squash as well.
    depPred.squash(squashed_num, tid);
}

void
MemDepUnit::violation(const DynInstPtr &store_inst,
        const DynInstPtr &violating_load)
{
    DPRINTF(PreMemDepUnit, "Passing violating PCs to store sets,"
            " load: %#x, store: %#x\n", violating_load->instAddr(),
            store_inst->instAddr());
    // Tell the memory dependence unit of the violation.
    depPred.violation(store_inst->instAddr(), violating_load->instAddr());
}

void
MemDepUnit::issue(const DynInstPtr &inst)
{
    DPRINTF(PreMemDepUnit, "Issuing instruction PC %#x [sn:%lli].\n",
            inst->instAddr(), inst->seqNum);

    depPred.issued(inst->instAddr(), inst->seqNum, inst->isStore());
}

MemDepUnit::MemDepEntryPtr &
MemDepUnit::findInHash(const DynInstConstPtr &inst)
{
    MemDepHashIt hash_it = memDepHash.find(inst->seqNum);

    assert(hash_it != memDepHash.end());

    return (*hash_it).second;
}

void
MemDepUnit::moveToReady(MemDepEntryPtr &woken_inst_entry)
{
    DPRINTF(PreMemDepUnit, "Adding instruction [sn:%lli] "
            "to the ready list.\n", woken_inst_entry->inst->seqNum);

    assert(!woken_inst_entry->squashed);

    iqPtr->addReadyMemInst(woken_inst_entry->inst);
}


void
MemDepUnit::dumpLists()
{
    for (ThreadID tid = 0; tid < MaxThreads; tid++) {
        cprintf("Instruction list %i size: %i\n",
                tid, instList[tid].size());

        ListIt inst_list_it = instList[tid].begin();
        int num = 0;

        while (inst_list_it != instList[tid].end()) {
            cprintf("Instruction:%i\nPC: %s\n[sn:%llu]\n[tid:%i]\nIssued:%i\n"
                    "Squashed:%i\n\n",
                    num, (*inst_list_it)->pcState(),
                    (*inst_list_it)->seqNum,
                    (*inst_list_it)->threadNumber,
                    (*inst_list_it)->isIssued(),
                    (*inst_list_it)->isSquashed());
            inst_list_it++;
            ++num;
        }
    }

    cprintf("Memory dependence hash size: %i\n", memDepHash.size());

#ifdef DEBUG
    cprintf("Memory dependence entries: %i\n", MemDepEntry::memdep_count);
#endif
}

} // namespace pre
} // namespace gem5
