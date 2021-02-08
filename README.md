# Efficient FPGA Implementation of Blockchain Operations

This repository contains an optimized VHDL implementation of the Bitcoin Proof-Of-Work algorithm. The FPGA board can receive a block header and tries out different nonces (and timestamps) until a hash digest below the specified target is found.

## Paper

The source code of the paper related to this code can be found in the documentation directory. It is also published at researchgate.net.

## Local Execution

### Simulation

Start GHDL simulation: `make trace.ghw` 

Execute testbenches: `make test`

### Building and Deployment

This project was developed using a Arty-A7-100T FPGA Board communicating with a host server using UART. Building and deployment took place on the host server using a Gitlab CI, for which the build script and configuration file can be found in this repository.

## Change Mining Core Count

The number of mining cores that can be deployed on the FPGA board is dependent on the number of logic cells available on the target board. To test different values, the constant `mining_core_count` in `src/main.vhd` can be adapted. If too many cores are deployed, the build or deployment tests will fail automatically.


## Testing

**Testbenches:** 

All testbenches which are located in the `sim` directory and have a filename ending with `_tb.vhd` are automatically executed in the `test`-stage. A local execution is possible with the command `make test`.

**Integration Testing:** 

Integration tests can be executed in the simulation as well as after deployment on the FPGA board.

* *Simulation*: The GHDL simulation can be started through the `test/simulation_test.sh` file and afterwards the corresponding tests are executed automatically. These tests can also be executed locally (`./test/simulation_test.sh`).
* *FPGA*: The tests to verify functionality after deployment are contained in the `test/post_deployment_test.sh` file.

## CLI

In order to interact with the deployed VHDL-Build, we use a small Python CLI. It is written with the `click` package and offers the following commands:

* `mine <Block-Header>` 

  Sends the given blockheader (640 bit with nonce / 608 bit without nonce) to the FPGA board and starts calculating block hashes, starting at the specified nonce or at `0x00000000`.

* `readresult` 

   Reads from the FPGA/simulation, if a hash belonging to the last sent block header was found and returns the corresponding nonce.

* `count` 

  Sends the FPGA/Simulation a block header for which no valid nonce can be found. This allows to conclude the hash rate from the difference between two nonces within a specified duration.

* `test` 

  Sends a blockheader with a valid nonce to the FPGA/Simulation, so that the execution of `readresult` should immediately return a nonce.

All commands can also be execution in the local simulation by appending `-s, --sim` (see [Local Execution](#local-execution)).

In addition, the progress of a block header can be tracked with the `-f, --follow` option for the commands `mine`, `readresult` and `test`.

## Contributors

**Timur Eke, [Nicolas Schapeler](https://github.com/nschapeler), Christop Starnecker, Florian Weiser**

## Project Supervisor

**Alexis Engelke**

* TUM: [Alexis Engelke, M. Sc.](https://www.in.tum.de/caps/mitarbeiter/engelke/)
* GitHub: [@aengelke](https://github.com/aengelke)