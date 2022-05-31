-- Module: Ferrule.Routing.Dijkstra
-- K-shortest path search across optical topologies with impairment-aware edge weights.

module Ferrule.Routing.Dijkstra where

import Ferrule.Types
import Ferrule.Routing.Graph

-- Weighted path entry representing a candidate route
data CandidatePath = CandidatePath
  { candidateLinks  :: [FiberLink]
  , candidateCost   :: Float
  }
  deriving (Eq, Show)

-- Edge cost weighting strategy
data CostMetric
  = MetricPhysicalDistance   -- Pure fiber distance in kilometers
  | MetricPropagationLatency -- Fiber latency in milliseconds
  | MetricImpairmentWeighted -- Distance penalized by fiber attenuation and nonlinear coefficient
  deriving (Eq, Show)

-- Calculate scalar link cost according to the chosen metric
linkCost :: CostMetric -> FiberLink -> Float
linkCost MetricPhysicalDistance link =
  spanLengthKm (linkSpan link)
linkCost MetricPropagationLatency link =
  spanLengthKm (linkSpan link) * 0.0049
linkCost MetricImpairmentWeighted link =
  let span = linkSpan link
      len = spanLengthKm span
      atten = spanAttenuation span
      nl = spanNonlinear span
  in len * (1.0 + (atten * 0.5) + (nl * 0.2))

-- Recursive depth-first path exploration with cycle prevention
findSimplePaths :: String -> String -> OpticalTopology -> Int -> [[FiberLink]]
findSimplePaths src tgt topo maxDepth =
  explore src [] [] 0
  where
    explore current visitedNodes currentPath depth
      | current == tgt && not (null currentPath) = [reverse currentPath]
      | depth >= maxDepth = []
      | otherwise =
          let nextLinks = findOutgoingLinks current topo
              validLinks = filter (\l -> not (linkTarget l `elem` visitedNodes)) nextLinks
          in concatMap (\l -> explore (linkTarget l) (current : visitedNodes) (l : currentPath) (depth + 1)) validLinks

-- Find top K shortest paths between source and target nodes
findKShortestPaths :: Int -> CostMetric -> String -> String -> OpticalTopology -> [[FiberLink]]
findKShortestPaths k metric src tgt topo =
  let allPaths = findSimplePaths src tgt topo 10
      weightedPaths = map (\p -> (sum (map (linkCost metric) p), p)) allPaths
      sortedPaths = sortWeighted weightedPaths
  in take k (map snd sortedPaths)
  where
    sortWeighted [] = []
    sortWeighted ((c, p):rest) =
      let smaller = sortWeighted (filter (\(c1, _) -> c1 <= c) rest)
          larger  = sortWeighted (filter (\(c1, _) -> c1 > c) rest)
      in smaller ++ [(c, p)] ++ larger
