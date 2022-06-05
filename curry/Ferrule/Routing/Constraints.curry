-- Module: Ferrule.Routing.Constraints
-- Functional logic equational constraints for spectrum continuity and contiguity.

module Ferrule.Routing.Constraints where

import Ferrule.Types
import Ferrule.Grid.Frequency
import Ferrule.Grid.Spectrum
import Ferrule.Routing.Graph

-- Equational constraint: Two spectral windows must be identical across all hops in an all-optical lightpath
-- (Spectrum Continuity Constraint: no optical-electrical-optical wavelength conversion)
satisfiesContinuity :: SpectralWindow -> SpectralWindow -> Bool
satisfiesContinuity (SpectralWindow start1 count1) (SpectralWindow start2 count2) =
  (start1 == start2) && (count1 == count2)

-- Check that a candidate spectral window does not clash with already allocated slots on a link
satisfiesClashFreeConstraint :: SpectralWindow -> LinkSpectrum -> Bool
satisfiesClashFreeConstraint window linkSpec =
  isWindowFree window linkSpec

-- Verify that a candidate spectral window is universally free on EVERY link along a proposed route
satisfiesEndToEndContinuity :: SpectralWindow -> [FiberLink] -> Bool
satisfiesEndToEndContinuity window links =
  let pathSpectra = map linkSpectrum links
      commonFreeSpectrum = intersectPathSpectra pathSpectra
  in isWindowFree window commonFreeSpectrum

-- Non-overlapping constraint between two assigned lightpaths sharing a common fiber link
satisfiesNonOverlapping :: SpectralWindow -> SpectralWindow -> Bool
satisfiesNonOverlapping (SpectralWindow s1 c1) (SpectralWindow s2 c2) =
  let end1 = s1 + c1
      end2 = s2 + c2
  in (end1 <= s2) || (end2 <= s1)

-- Guard predicate checking whether a candidate lightpath allocation satisfies all physical and spectral constraints
isAllocationValid :: SpectralWindow -> [FiberLink] -> ModulationScheme -> Float -> Bool
isAllocationValid window links modulation launchPowerDbm =
  let validWindow = isWindowValid window
      continuityOk = satisfiesEndToEndContinuity window links
      pathKm = pathPhysicalLengthKm links
      reachOk = pathKm <= 3500.0  -- Physical reach constraint
  in validWindow && continuityOk && reachOk
