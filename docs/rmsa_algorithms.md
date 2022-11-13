# Routing, Modulation, and Spectrum Assignment (RMSA)

Routing, Modulation, and Spectrum Assignment (RMSA) in flexible-grid optical networks is an NP-hard combinatorial problem. Ferrule formulates RMSA as a declarative constraint satisfaction and non-deterministic search problem in Curry.

## 1. Physical Constraints

An optical lightpath allocation must satisfy three fundamental invariants:

1. **Spectrum Continuity Constraint**:
   In transparent all-optical networks without wavelength converters, an optical lightpath must occupy the identical frequency slot indices across all intermediate links from source to destination.

2. **Spectrum Contiguity Constraint**:
   High-baud rate coherent optical carriers require multiple adjacent 12.5 GHz slots. An allocation of `N` slots must form an uninterrupted contiguous block `[s, s + N - 1]`.

3. **Clash-Free Allocation Constraint**:
   Two lightpaths sharing a common fiber link must never occupy overlapping spectral slots.

```
Link 1:  [..@@@@........................]  (Lightpath A: slots 2-5)
Link 2:  [..@@@@....######..............]  (Lightpath A: slots 2-5, Lightpath B: slots 10-15)
Link 3:  [..........######..............]  (Lightpath B: slots 10-15)
```

## 2. Functional-Logic Formulation in Curry

In Curry, candidate solutions are explored using non-deterministic choices and equational constraints:

```curry
-- Free logical variable represents the starting slot index
let startSlot free

-- Equational constraint enforces universal availability across all hops
satisfiesEndToEndContinuity (SpectralWindow startSlot slotCount) pathLinks =:= True

-- Non-deterministic choice explores K-shortest path candidates
chosenPath = chooseRouteCandidate kShortestPaths
```

Because Curry evaluates constraints via needed narrowing, paths that violate physical GSNR thresholds or encounter spectral conflicts are pruned early in the search tree, avoiding exponential backtracking.

## 3. Hitless Push-Pull Spectrum Defragmentation

Dynamic circuit provisioning and teardowns cause spectral fragmentation. Ferrule plans hitless defragmentation steps that shift active lightpaths towards lower frequency slots.

By coordinating with tunable transmitter local oscillators and receiver DSP equalizers, carriers are shifted in sub-gigahertz increments without optical packet loss.
