# Runahead and Precise Runahead Execution implementation using system simulator [gem5](https://www.gem5.org/)
This is the repository used for my final year projectduring my Computer Science degree at the University of Cambridge. 
The project is fully described in my dissertation --- ''Running ahead of memory latency - processor runahead'', which can be found in this [repository](https://github.com/kuczmmar/Running-ahead-of-memory-latency).
My implementations are based on the papers that proposed [runahead](https://ieeexplore.ieee.org/document/1183532) and [PRE](https://ieeexplore.ieee.org/document/9065552).


## Installation
Following the online [gem5 tutorial](https://www.gem5.org/documentation/learning_gem5/part1/building/), the recommended way tp install all dependencies on Ubuntu is to run the following command:
```sh
sudo apt install build-essential git m4 scons zlib1g zlib1g-dev libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev python-dev python
```

Clone the repository.

## Development
The best place to start learning gem5 is [the online tutorial](https://www.gem5.org/documentation/learning_gem5/introduction/).

To run my simulation setup enter the gem5  and in script run.sh ammend line number 15, this is responsible for compiling gem5. 
On a computer with 8 cores the recommended way to compile is:
```sh
python3 `which scons` build/X86/gem5.opt -j9
```
Alternatively, one can specify the exact path to scons directory. Given more cores, you can increase the parallelisation parameter e.g. on a 32 core machine:
```sh
python3 ./bin/scons build/X86/gem5.opt -j33
```

To compile gem5 and run the test script simply use:
```sh
./gem5/run.sh -c
```
To only run the tests:
```sh
./gem5/run.sh
```
## Repository structure
|Top | Subfolders  | | Description |
| ------ | ------ | ------ | ------ |
| gem5/  ||| Source code of the [gem5](https://www.gem5.org/) simulator tool version 21.1.0.2.
||src/cpu/ | o3/         |The baseline CPU implementation.  |
|        ||ra/ | The runahead CPU that extends O3CPU. |
|        | |pre/       |The PRE CPU that extends O3CPU. |
|   | src/mem/ | | The memory system, contains caches and MSHRs.|
|                | src/kern/ | | Implementation of system-call interfaces. |
|                | configs/ | | Python scripts configuring architecture features.|
|                | m5out/ | | Simulation statistics (used by McPAT).|
|                | stats/ | | Scripts for parsing and displaying chosen statistics.|
|                | build/ | | The build directory contains gem5's binary files.|
|benchmarks/  |cbench/ || {Banchmarks based on standard type files e.g.~txt, png, mp3. |
|   |cgo2017/|| Memory-latency bound benchmarks.|
|parsing_data/| mcpat/ | |Source code of the [McPAT](https://www.hpl.hp.com/research/mcpat/) power consumption tool (https://github.com/HewlettPackard/mcpat).|
|                 |Gem5McPatParser | | Script converting gem5 statistics to a format used by McPAT based on (https://github.com/saitiku/Gem5McPatParser).|
|                 |parse.py | | Script that runs parsing and McPAT, saves the output.|
|             |mcpat\_in/ | | Output of Gem5McPatParser and input to McPAT.|
|             |mcpat\_out/ | | This is where energy output from McPAT after running the parse.py script.|
|plotting_stats/     | | | Parsing and plotting statistics and McPAT output.|


## License
### _BSD 2-Clause License_

Copyright (c) 2022, Marta Walentynowicz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
