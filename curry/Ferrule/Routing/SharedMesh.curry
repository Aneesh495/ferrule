-- Module: Ferrule.Routing.SharedMesh
-- 1:N Shared Mesh Protection (SMP) and backup capacity sharing across independent failure risks.

module Ferrule.Routing.SharedMesh where

import Ferrule.Types
import Ferrule.Grid.Frequency
import Ferrule.Grid.Spectrum
import Ferrule.Routing.Graph

-- A Shared Protection Reservation records a spectral window reserved on a link for backup protection,
-- shared among a group of primary lightpaths whose primary paths are mutually SRLG-disjoint.
data SmpReservation = SmpReservation
  { reservationId     :: String
  , reservedWindow    :: SpectralWindow
  , protectedDemands  :: [String]       -- List of demand IDs sharing this backup window
  , protectedSrlgSets :: [[Int]]        -- SRLGs of each primary path; must be pairwise disjoint
  }
  deriving (Eq, Show)

-- Verify whether a new demand with a given primary path SRLG set can safely share an existing SMP backup window
canShareSmpWindow :: [Int] -> SmpReservation -> Bool
canShareSmpWindow primarySrlgs reservation =
  let existingSrlgGroups = protectedSrlgSets reservation
      noConflict = not (any (\group -> any (\g -> g `elem` group) primarySrlgs) existingSrlgGroups)
  in noConflict

-- Add a new demand to an SMP reservation if failure independence holds
addDemandToSmpReservation :: String -> [Int] -> SmpReservation -> Maybe SmpReservation
addDemandToSmpReservation demandId' primarySrlgs res =
  if canShareSmpWindow primarySrlgs res
  then Just res
         { protectedDemands  = demandId' : protectedDemands res
         , protectedSrlgSets = primarySrlgs : protectedSrlgSets res
         }
  else Nothing

-- Calculate protection sharing efficiency factor (Total Protected Demands / Total Reserved Spectral Windows)
smpSharingEfficiency :: [SmpReservation] -> Float
smpSharingEfficiency reservations =
  if null reservations
  then 1.0
  else
    let totalProtected = sum (map (length . protectedDemands) reservations)
        totalWindows   = length reservations
    in fromIntegral totalProtected / fromIntegral totalWindows
