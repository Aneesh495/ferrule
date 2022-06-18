-- Module: Ferrule.Routing.Protection
-- 1+1 hitless optical protection and SRLG-disjoint backup path synthesis.

module Ferrule.Routing.Protection where

import Ferrule.Types
import Ferrule.Grid.Spectrum
import Ferrule.Routing.Graph
import Ferrule.Routing.Dijkstra
import Ferrule.Routing.Constraints

-- 1+1 Optical Protection Pair: Primary active lightpath and dedicated hot-standby protection lightpath
data ProtectionPair = ProtectionPair
  { primaryLightpath    :: Lightpath
  , protectionLightpath :: Lightpath
  , areSrlgDisjoint     :: Bool
  }
  deriving (Eq, Show)

-- Synthesize an SRLG-disjoint 1+1 protection path for an established primary route
findSrlgDisjointProtectionRoute :: [FiberLink] -> String -> String -> OpticalTopology -> Maybe [FiberLink]
findSrlgDisjointProtectionRoute primaryLinks src tgt topo =
  let candidateBackupPaths = findKShortestPaths 10 MetricPhysicalDistance src tgt topo
      disjointPaths = filter (\backup -> arePathsSrlgDisjoint primaryLinks backup) candidateBackupPaths
  in case disjointPaths of
       []        -> Nothing
       (backup:_) -> Just backup

-- Verify whether a primary and backup path satisfy the sub-50ms protection switching requirement
-- (Differential propagation delay must be within optical buffer window: typically < 10 ms differential latency)
checkDifferentialDelayOk :: [FiberLink] -> [FiberLink] -> Bool
checkDifferentialDelayOk primaryLinks backupLinks =
  let delayPrimary = pathPropagationLatencyMs primaryLinks
      delayBackup  = pathPropagationLatencyMs backupLinks
      diffDelay    = abs (delayBackup - delayPrimary)
  in diffDelay <= 10.0  -- 10 ms max differential delay
