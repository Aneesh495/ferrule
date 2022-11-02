# Ferrule: Architecture and Design

Ferrule is an Optical Transport Network (OTN) and Dense Wavelength Division Multiplexing (DWDM) routing, spectrum allocation, and physical impairment validation engine.

The core computational heart of Ferrule is implemented in Curry, a declarative functional-logic programming language combining higher-order lazy functional programming with constraint logic programming, non-deterministic choices, and needed narrowing.

```
+------------------------------------------------------------------------+
|                          Ferrule Northbound API                        |
|              (CLI Tools, REST / JSON-RPC SDN Controller)               |
+------------------------------------------------------------------------+
                                   |
                                   v
+------------------------------------------------------------------------+
|                 Curry Functional-Logic Execution Core                  |
|                                                                        |
|  +--------------------+  +--------------------+  +------------------+  |
|  |     RMSA Solver    |  | Spectrum Allocation|  | 1+1/1:N Protect  |  |
|  |   (Curry Choices)  |  |  (Constraints =:=) |  | (SRLG Disjoint)  |  |
|  +--------------------+  +--------------------+  +------------------+  |
|  |   Optical Physics  |  |  ITU-T G.709 OTN   |  |   GMPLS / LMP    |  |
|  | (Analytical GN/ASE)|  | (Framing & GMP)    |  |  (G.808.1 State) |  |
|  +--------------------+  +--------------------+  +------------------+  |
+------------------------------------------------------------------------+
                                   |
                                   v
+------------------------------------------------------------------------+
|                      Simulation & Runtime Engine                       |
|   (Curry Abstract Machine, Type Checker, C Numerical Acceleration)     |
+------------------------------------------------------------------------+
```

## System Layers

1. **Physical Layer (DWDM Optics)**:
   - Models single-mode fibers (SMF-28, NZDSF, LEAF), chromatic dispersion accumulation, and polarization mode dispersion.
   - Evaluates Erbium-Doped Fiber Amplifier (EDFA) gain saturation and Amplified Spontaneous Emission (ASE) noise.
   - Closed-form analytical Gaussian Noise (GN) model for Kerr nonlinear interference (NLI: SPM and XPM).
   - Generalized Signal-to-Noise Ratio (GSNR) budgeting and coherent optical reach calculation.

2. **Routing, Modulation, and Spectrum Assignment (RMSA)**:
   - Formulated as a constraint satisfaction problem in Curry.
   - Uses non-deterministic choice to explore candidate paths and frequency slots.
   - Equational constraints enforce spectrum continuity and contiguity.
   - Disjoint path synthesis enforces Shared Risk Link Group (SRLG) diversity.

3. **Digital Transport Layer (ITU-T G.709 OTN)**:
   - Models 4-row by 4080-column OTN framing with FAS alignment.
   - Hierarchical ODUk multiplexing trees (ODU0 to ODU4, ODUflex).
   - Generic Mapping Procedure (GMP) with sigma-delta byte justification.
   - Tandem Connection Monitoring (TCM1 to TCM6) and defect classification.

4. **Control Plane and Protection (GMPLS)**:
   - Link Management Protocol (LMP - RFC 4204) state machine.
   - ITU-T G.808.1 sub-50ms linear protection switching engine.
