-- Module: Ferrule.Routing.Graph
-- Optical network topology graph, directed fiber links, and Shared Risk Link Groups (SRLGs).

module Ferrule.Routing.Graph where

import Ferrule.Types
import Ferrule.Grid.Spectrum

-- Directed fiber link connecting two ROADM nodes
data FiberLink = FiberLink
  { linkId          :: String
  , linkSource      :: String
  , linkTarget      :: String
  , linkSpan        :: Span
  , linkSpectrum    :: LinkSpectrum
  , linkSrlgSet     :: [Int]     -- Shared Risk Link Group IDs (e.g. shared physical conduit or bridge)
  }
  deriving (Eq, Show)

-- Complete optical network topology representation
data OpticalTopology = OpticalTopology
  { topoNodes       :: [RoadmNode]
  , topoLinks       :: [FiberLink]
  }
  deriving (Eq, Show)

-- Initialize an optical topology with given nodes and bidirectional links
initOpticalTopology :: [RoadmNode] -> [FiberLink] -> OpticalTopology
initOpticalTopology nodes links = OpticalTopology
  { topoNodes = nodes
  , topoLinks = links
  }

-- Find all outgoing fiber links from a given node ID
findOutgoingLinks :: String -> OpticalTopology -> [FiberLink]
findOutgoingLinks srcNode topo =
  filter (\l -> linkSource l == srcNode) (topoLinks topo)

-- Look up a specific fiber link between two adjacent nodes
findLinkBetween :: String -> String -> OpticalTopology -> Maybe FiberLink
findLinkBetween src tgt topo =
  let matches = filter (\l -> linkSource l == src && linkTarget l == tgt) (topoLinks topo)
  in case matches of
       []    -> Nothing
       (l:_) -> Just l

-- Check whether two fiber links share any physical risk group (SRLG overlap)
hasSrlgOverlap :: FiberLink -> FiberLink -> Bool
hasSrlgOverlap l1 l2 =
  let s1 = linkSrlgSet l1
      s2 = linkSrlgSet l2
  in any (\g -> g `elem` s2) s1

-- Check whether two complete paths share any common nodes (other than endpoints) or common links/SRLGs
arePathsSrlgDisjoint :: [FiberLink] -> [FiberLink] -> Bool
arePathsSrlgDisjoint path1 path2 =
  let linksDisjoint = not (any (\l1 -> any (\l2 -> linkId l1 == linkId l2) path2) path1)
      srlgsDisjoint = not (any (\l1 -> any (\l2 -> hasSrlgOverlap l1 l2) path2) path1)
  in linksDisjoint && srlgsDisjoint

-- Calculate total physical length in km of an ordered sequence of fiber links
pathPhysicalLengthKm :: [FiberLink] -> Float
pathPhysicalLengthKm links =
  sum (map (spanLengthKm . linkSpan) links)

-- Calculate cumulative propagation latency across a path (assuming 4.9 microseconds per km in silica fiber)
pathPropagationLatencyMs :: [FiberLink] -> Float
pathPropagationLatencyMs links =
  let totalKm = pathPhysicalLengthKm links
  in totalKm * 0.0049
