# APB SystemVerilog Verification

A SystemVerilog-based verification project for an AMBA APB (Advanced Peripheral Bus) Slave using a structured Layered Testbench and Functional Coverage.

# Project Overview

This project implements an APB slave with a 256-entry memory and verifies its read/write operations using a modular SystemVerilog testbench.

The verification environment includes:

Transaction

Generator

Driver

Monitor

Scoreboard

Functional Coverage

Environment

Test

APB Slave

The APB slave supports:

Read transactions

Write transactions

8-bit address

32-bit write/read data

PREADY response

PSLVERR error response

Address 8'hFF is treated as an error address

The internal memory contains 256 locations, each storing 32-bit data.

# Transaction

The transaction class contains:

write — read/write control

addr — 8-bit APB address

data — 32-bit write data

rdata — 32-bit read data

pslverr — APB error response

# Generator

The generator creates 1000 randomized write/read transaction pairs.

For each iteration:

A random address from 0 to 255 is generated.

A write transaction is created.

Random write data is generated.

The write transaction is sent to the driver.

A read transaction for the same address is generated.

The read transaction is sent to the driver.

# Driver

The driver converts transactions into APB interface signals.

It drives:

PSEL

PENABLE

PWRITE

PADDR

PWDATA

The driver also captures PRDATA for read transactions.

# Monitor

The monitor observes APB transactions from the interface and collects:

Write/read operation

Address

Write data

Read data

PREADY

PSLVERR

Captured transactions are sent to the scoreboard.

# Scoreboard

The scoreboard contains a reference memory model.

It verifies:

Write transactions

Read data correctness

Error response behavior

Expected vs. actual read data

The scoreboard reports:

WRITE PASS

READ PASS

READ FAIL

ERROR RESPONSE PASS

ERROR RESPONSE FAIL

# Functional Coverage

Functional coverage is implemented using a SystemVerilog covergroup.

Coverpoints

Read/Write transactions

Address ranges

Data values

PREADY

PSLVERR

Address Coverage

The address space is divided into four ranges:

0–63

64–127

128–191

192–255

Data Coverage

Data coverage includes:

Zero data

Small data values

Other/default data

Cross Coverage

The project includes cross coverage for:

Write × Address

Write × PREADY

Address × PREADY

Write × PSLVERR

The coverage goal is configured using:

option.at_least = 10;

Files

Suggested repository structure:

APB-SystemVerilog-Verification/
│
├── apb_slave.sv
├── apb_if.sv
├── apb_pkg.sv
├── apb_top_tb.sv
└── README.md

Technologies Used

SystemVerilog

AMBA APB

RTL Verification

Layered Testbench

Randomized Testing

Functional Coverage

Scoreboard-Based Verification

EDA Simulation

Verification Flow

Randomized Transactions
          |
          v
      Generator
          |
          v
        Driver
          |
          v
       APB Slave
          |
          v
       Monitor
       /           v       v
Coverage   Scoreboard
              |
              v
       Pass / Fail Check

# Author

Wamiq Irfan
Electronics Engineering

# Project Highlights

This project demonstrates practical experience with SystemVerilog verification, including layered testbench architecture, randomized stimulus generation, reference-model-based checking, protocol transaction monitoring, and functional coverage.
