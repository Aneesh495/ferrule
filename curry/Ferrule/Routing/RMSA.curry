-- Module: Ferrule.Routing.RMSA
-- Routing, Modulation, and Spectrum Assignment (RMSA) solver using functional-logic search.

module Ferrule.Routing.RMSA where

import Ferrule.Types
import Ferrule.Grid.Frequency
import Ferrule.Grid.Spectrum
import Ferrule.Physics.Modulation
import Ferrule.Physics.Budget
import Ferrule.Routing.Graph
import Ferrule.Routing.Dijkstra
import Ferrule.Routing.Constraints

-- Candidate non-deterministic choice operator simulation for Curry functional logic search
-- Explores alternative candidate routes across K-shortest paths
chooseRouteCandidate :: [[FiberLink]] -> [FiberLink]
chooseRouteCandidate [] = []
chooseRouteCandidate (p:ps) = p ? chooseRouteCandidate ps
  where
    (?) x y = x  -- In pure Curry, (?) is the built-in non-deterministic choice operator

-- Non-deterministic modulation format selection
chooseModulationCandidate :: [ModulationScheme] -> ModulationScheme
chooseModulationCandidate (m:ms) = m ? chooseModulationCandidate ms
  where
    (?) x y = x

-- Solve RMSA for a client optical demand across an optical topology
solveRmsaDemand :: OpticalDemand -> OpticalTopology -> Maybe Lightpath
solveRmsaDemand demand topo =
  let src = demandSource demand
      tgt = demandTarget demand
      bitrate = demandBitrate demand

      -- 1. Compute candidate physical paths using K-shortest path search
      kPaths = findKShortestPaths 5 MetricImpairmentWeighted src tgt topo
  in case kPaths of
       [] -> Nothing
       _  -> searchFeasibleRmsa demand topo kPaths

-- Search through candidate paths to find a valid route, modulation, and spectral window
searchFeasibleRmsa :: OpticalDemand -> OpticalTopology -> [[FiberLink]] -> Maybe Lightpath
searchFeasibleRmsa _ _ [] = Nothing
searchFeasibleRmsa demand topo (candidatePath:remainingPaths) =
  let pathKm = pathPhysicalLengthKm candidatePath
      latency = pathPropagationLatencyMs candidatePath
      latencyOk = latency <= demandLatencyMax demand

      -- 2. Determine best feasible modulation format for path length (assuming nominal GSNR ~18 dB)
      bestMod = selectBestModulation pathKm 18.0
  in case (latencyOk, bestMod) of
       (True, Just modScheme) ->
         let -- 3. Determine required spectral slot count based on required bitrate and modulation
             bitsPerSym = modulationSpectralEfficiency modScheme
             symbolRate = demandBitrate demand / bitsPerSym
             slotsNeeded = requiredSlotCount symbolRate 0.15

             -- 4. Find contiguous and continuous free spectral window along the path
             pathSpectra = map linkSpectrum candidatePath
             commonSpec = intersectPathSpectra pathSpectra
             freeWindows = findContiguousWindows slotsNeeded commonSpec
         in case freeWindows of
              [] -> searchFeasibleRmsa demand topo remainingPaths  -- Backtrack to next candidate path
              (chosenWindow:_) ->
                let spans = map linkSpan candidatePath
                    roadmNodes = topoNodes topo
                    quality = evaluatePathQuality spans roadmNodes 0.0 193.41449
                    nodeSequence = demandSource demand : map linkTarget candidatePath
                in Just Lightpath
                     { lightpathId      = "LP-" ++ demandId demand
                     , lightpathDemand  = demandId demand
                     , lightpathRoute   = nodeSequence
                     , lightpathSlots   = chosenWindow
                     , lightpathMod     = modScheme
                     , lightpathQuality = quality
                     , lightpathBackup  = Nothing
                     }
       _ -> searchFeasibleRmsa demand topo remainingPaths
