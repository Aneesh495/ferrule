-- Module: Ferrule.Topology.Parser
-- Topology structural validation, degree distributions, and graph connectivity checks.

module Ferrule.Topology.Parser where

import Ferrule.Types
import Ferrule.Routing.Graph

-- Verify that all fiber links connect valid ROADM nodes defined in the topology
validateLinkEndpoints :: OpticalTopology -> Bool
validateLinkEndpoints topo =
  let validNodeIds = map nodeId (topoNodes topo)
  in all (\l -> linkSource l `elem` validNodeIds && linkTarget l `elem` validNodeIds) (topoLinks topo)

-- Compute the actual outgoing degree of each ROADM node from the link table
computeNodeDegree :: String -> OpticalTopology -> Int
computeNodeDegree node topo =
  length (findOutgoingLinks node topo)

-- Verify that the topology is fully connected (no isolated components)
isTopologyConnected :: OpticalTopology -> Bool
isTopologyConnected topo =
  case topoNodes topo of
    [] -> True
    (rootNode:_) ->
      let visited = reachableFrom (nodeId rootNode) []
          allNodeIds = map nodeId (topoNodes topo)
      in all (`elem` visited) allNodeIds
  where
    reachableFrom cur visited
      | cur `elem` visited = visited
      | otherwise =
          let neighbors = map linkTarget (findOutgoingLinks cur topo)
              newVisited = cur : visited
          in foldl (\acc n -> reachableFrom n acc) newVisited neighbors

-- Compute total network fiber length across all links in the topology
totalNetworkFiberKm :: OpticalTopology -> Float
totalNetworkFiberKm topo =
  sum (map (spanLengthKm . linkSpan) (topoLinks topo))
