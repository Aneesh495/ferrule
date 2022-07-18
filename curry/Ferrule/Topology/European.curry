-- Module: Ferrule.Topology.European
-- Standard European optical reference networks (COST 239 11-node and German 17-node).

module Ferrule.Topology.European where

import Ferrule.Types
import Ferrule.Grid.Spectrum
import Ferrule.Physics.Fiber
import Ferrule.Routing.Graph
import Ferrule.Topology.Standard

-- Pan-European COST 239 Reference Topology (11 nodes, 26 bidirectional links)
-- Nodes: AMS (Amsterdam), BER (Berlin), BRU (Brussels), COP (Copenhagen),
--        LON (London), LUX (Luxembourg), MAD (Madrid), MIL (Milan),
--        PAR (Paris), PRA (Prague), ZUR (Zurich)
cost239Topology :: OpticalTopology
cost239Topology =
  let nodeNames = ["AMS", "BER", "BRU", "COP", "LON", "LUX", "MAD", "MIL", "PAR", "PRA", "ZUR"]
      nodes = [RoadmNode { nodeId = n, nodeDegree = 4, nodeSwitchLossDb = 3.2 } | n <- nodeNames]
      links = concat
        [ makeBiLink "E01" "LON" "PAR" 340.0 [101]
        , makeBiLink "E02" "LON" "BRU" 320.0 [102]
        , makeBiLink "E03" "LON" "AMS" 360.0 [103]
        , makeBiLink "E04" "PAR" "BRU" 280.0 [104]
        , makeBiLink "E05" "PAR" "LUX" 310.0 [105]
        , makeBiLink "E06" "PAR" "MAD" 1050.0 [106]
        , makeBiLink "E07" "PAR" "MIL" 640.0 [107]
        , makeBiLink "E08" "BRU" "AMS" 170.0 [108]
        , makeBiLink "E09" "BRU" "LUX" 190.0 [109]
        , makeBiLink "E10" "AMS" "COP" 620.0 [110]
        , makeBiLink "E11" "AMS" "BER" 580.0 [111]
        , makeBiLink "E12" "LUX" "ZUR" 300.0 [112]
        , makeBiLink "E13" "ZUR" "MIL" 220.0 [113]
        , makeBiLink "E14" "ZUR" "PRA" 510.0 [114]
        , makeBiLink "E15" "BER" "COP" 350.0 [115]
        , makeBiLink "E16" "BER" "PRA" 280.0 [116]
        , makeBiLink "E17" "MAD" "MIL" 1180.0 [117]
        , makeBiLink "E18" "MIL" "PRA" 650.0 [118]
        ]
  in initOpticalTopology nodes links
