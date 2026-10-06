# AVOLITE — MATLAB Golden Reference Model

Self-Adaptive Reconfigurable RF Receiver with Environment-Aware Intelligent Scan Scheduling.

## Purpose

This repository is the **golden MATLAB reference model** for AVOLITE.

It defines, verifies, and freezes:

- mathematical equations
- physical assumptions
- parameters
- signal definitions
- subsystem interfaces
- ground-truth states
- reference outputs
- performance metrics

The later Simulink implementation must reproduce these reference behaviors within explicitly defined tolerances.

## Development rule

**Equations → MATLAB reference → verification → Simulink → MATLAB/Simulink comparison → Simscape → AI/closed loop**

Do not implement a Simulink subsystem until its MATLAB reference behavior has been verified.

## Reference chain

Scenario → Emitters → Waveforms → Propagation → Antenna → RF Receiver → ADC → DDC → Digital Filter → FFT → Detection/CFAR → PDW → AoA/DOA → Environment State → Baseline Scheduler → Performance

## Ground truth rule

Ground-truth emitter/environment state is kept separate from estimated receiver/DSP/AI state. Ground truth is used for verification and performance measurement, not as an operational AI input.

## MATLAB version

MATLAB R2025b.

## Repository structure

- `config/` — master parameters and constants
- `init/` — path initialization
- `matlab/` — reference implementation by subsystem
- `tests/` — unit, subsystem, integration, regression tests
- `verification/` — reference-vs-equation and later reference-vs-Simulink verification
- `results/` — generated figures, tables, logs, and runs
- `docs/` — requirements, equations, interfaces, testing and verification

## Status

Initial scaffold. Existing emitter, coordinate-system, and waveform work from the AVOLITE project will be migrated into the corresponding folders after interface review.
