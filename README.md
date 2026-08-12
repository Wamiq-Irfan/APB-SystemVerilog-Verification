# APB SystemVerilog Verification

A SystemVerilog-based verification project for an **AMBA APB (Advanced Peripheral Bus) Slave** using a structured **Layered Testbench** and **Functional Coverage**.

## Project Overview

This project implements an APB Slave with a 256-entry memory and verifies its read/write operations using a modular SystemVerilog layered testbench.

The verification environment consists of:

- Transaction
- Generator
- Driver
- Monitor
- Scoreboard
- Functional Coverage
- Environment
- Test

## APB Slave

The APB Slave supports:

- Read transactions
- Write transactions
- 8-bit address
- 32-bit read/write data
- `PREADY` response
- `PSLVERR` error response
- Address `8'hFF` as an error address

The internal memory contains **256 locations**, with each location storing **32-bit data**.

## Layered Testbench

The testbench follows a structured layered verification architecture:

```text
                 +-------------+
                 |     Test    |
                 +------+------+
                        |
                 +------v------+
                 | Environment |
                 +------+------+
                        |
          +-------------+-------------+
          |             |             |
     +----v----+    +---v----+   +----v----+
     |Generator|    | Driver |   | Monitor |
     +----+----+    +----+----+   +----+----+
          |              |             |
          |              v             |
          |          +--------+        |
          +--------->| APB DUT|<-------+
                     +--------+
                           |
                     +-----v-----+
                     | Scoreboard|
                     +-----------+
                           
                     +-----------+
                     | Coverage  |
                     +-----------+
