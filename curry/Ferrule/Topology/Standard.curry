-- Module: Ferrule.Topology.Standard
-- Standard North American optical reference networks (NSFNET 14 and US-Backbone 24).

module Ferrule.Topology.Standard where

import Ferrule.Types
import Ferrule.Grid.Spectrum
import Ferrule.Physics.Fiber
import Ferrule.Routing.Graph

-- Helper: create a bidirectional fiber link pair with realistic fiber parameters and SRLGs
makeBiLink :: String -> String -> String -> Float -> [Int] -> [FiberLink]
makeBiLink linkBaseName src tgt lenKm srlgs =
  let spanFwd = standardSmfSpan lenKm
      spanRev = standardSmfSpan lenKm
      fwd = FiberLink
        { linkId       = linkBaseName ++ "-Fwd"
        , linkSource   = src
        , linkTarget   = tgt
        , linkSpan     = spanFwd
        , linkSpectrum = initEmptySpectrum
        , linkSrlgSet  = srlgs
        }
      rev = FiberLink
        { linkId       = linkBaseName ++ "-Rev"
        , linkSource   = tgt
        , linkTarget   = src
        , linkSpan     = spanRev
        , linkSpectrum = initEmptySpectrum
        , linkSrlgSet  = srlgs
        }
  in [fwd, rev]

-- NSFNET 14-Node Reference Topology (21 bidirectional fiber links)
-- Nodes: SEA, SCL, SLC, DEN, HOU, KAN, NEB, CHI, CLE, ATL, PIT, NYK, BOS, WDC
nsfnetTopology :: OpticalTopology
nsfnetTopology =
  let nodeNames = ["SEA", "SCL", "SLC", "DEN", "HOU", "KAN", "NEB", "CHI", "CLE", "ATL", "PIT", "NYK", "BOS", "WDC"]
      nodes = [RoadmNode { nodeId = n, nodeDegree = 3, nodeSwitchLossDb = 3.5 } | n <- nodeNames]
      links = concat
        [ makeBiLink "L01" "SEA" "SCL"  800.0 [1]
        , makeBiLink "L02" "SEA" "SLC" 1100.0 [2]
        , makeBiLink "L03" "SCL" "SLC"  900.0 [3]
        , makeBiLink "L04" "SCL" "DEN" 1400.0 [4]
        , makeBiLink "L05" "SLC" "DEN"  650.0 [5]
        , makeBiLink "L06" "SLC" "HOU" 1800.0 [6]
        , makeBiLink "L07" "DEN" "KAN"  850.0 [7]
        , makeBiLink "L08" "HOU" "KAN" 1050.0 [8]
        , makeBiLink "L09" "HOU" "ATL" 1150.0 [9]
        , makeBiLink "L10" "KAN" "NEB"  450.0 [10]
        , makeBiLink "L11" "KAN" "PIT" 1200.0 [11]
        , makeBiLink "L12" "NEB" "CHI"  750.0 [12]
        , makeBiLink "L13" "CHI" "CLE"  500.0 [13]
        , makeBiLink "L14" "CHI" "ATL" 1000.0 [14]
        , makeBiLink "L15" "CLE" "PIT"  250.0 [15]
        , makeBiLink "L16" "CLE" "NYK"  700.0 [16]
        , makeBiLink "L17" "CLE" "BOS"  900.0 [17]
        , makeBiLink "L18" "ATL" "WDC"  850.0 [18]
        , makeBiLink "L19" "PIT" "WDC"  350.0 [19]
        , makeBiLink "L20" "NYK" "BOS"  300.0 [20]
        , makeBiLink "L21" "NYK" "WDC"  350.0 [21]
        ]
  in initOpticalTopology nodes links
