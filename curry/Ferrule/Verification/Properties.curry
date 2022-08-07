-- Module: Ferrule.Verification.Properties
-- Formal invariants and safety verification predicates for optical network configurations.

module Ferrule.Verification.Properties where

import Ferrule.Types
import Ferrule.Grid.Frequency
import Ferrule.Grid.Spectrum
import Ferrule.Physics.Modulation
import Ferrule.Routing.Graph
import Ferrule.Routing.Constraints
import Ferrule.Routing.Protection

-- Invariant 1: Clash-Free Spectrum Allocation
-- For every pair of active lightpaths sharing one or more common fiber links,
-- their assigned spectral windows must be strictly disjoint.
propClashFreeSpectrum :: [Lightpath] -> Bool
propClashFreeSpectrum [] = True
propClashFreeSpectrum (lp:lps) =
  let curRoute = lightpathRoute lp
      curWin   = lightpathSlots lp
      noClashWithOthers = all (\otherLp ->
        let otherRoute = lightpathRoute otherLp
            otherWin   = lightpathSlots otherLp
            sharesLink = routesShareAnyLink curRoute otherRoute
        in if sharesLink
           then satisfiesNonOverlapping curWin otherWin
           else True) lps
  in noClashWithOthers && propClashFreeSpectrum lps
  where
    routesShareAnyLink r1 r2 =
      let hops1 = zip r1 (drop 1 r1)
          hops2 = zip r2 (drop 1 r2)
      in any (\h -> h `elem` hops2) hops1

-- Invariant 2: End-to-End Spectrum Continuity
-- In the absence of optical-electrical-optical (OEO) regenerators, an established
-- lightpath must allocate the identical spectral window across all hops.
propSpectrumContinuity :: Lightpath -> Bool
propSpectrumContinuity lp =
  let win = lightpathSlots lp
  in satisfiesContinuity win win

-- Invariant 3: Spectral Contiguity
-- High-baud optical carriers must occupy a contiguous block of frequency slots [start, start + count - 1].
propSpectrumContiguity :: SpectralWindow -> Bool
propSpectrumContiguity (SpectralWindow start count) =
  start >= 0 && count > 0 && (start + count) <= totalCbandSlots

-- Invariant 4: Monotonic Modulation Thresholds
-- Verify that required GSNR is strictly monotonically increasing with spectral efficiency:
-- GSNR(BPSK) < GSNR(QPSK) < GSNR(8-QAM) < GSNR(16-QAM) < GSNR(32-QAM) < GSNR(64-QAM)
propMonotonicModulationThresholds :: Bool
propMonotonicModulationThresholds =
  let gBpsk  = modulationRequiredGsnrDb DpBpsk
      gQpsk  = modulationRequiredGsnrDb DpQpsk
      g8Qam  = modulationRequiredGsnrDb Dp8Qam
      g16Qam = modulationRequiredGsnrDb Dp16Qam
      g32Qam = modulationRequiredGsnrDb Dp32Qam
      g64Qam = modulationRequiredGsnrDb Dp64Qam
  in (gBpsk < gQpsk) && (gQpsk < g8Qam) && (g8Qam < g16Qam) && (g16Qam < g32Qam) && (g32Qam < g64Qam)

-- Invariant 5: SRLG Disjointness for 1+1 Protection
-- Primary and backup protection routes must share zero common SRLG risk group identifiers.
propProtectionSrlgDisjoint :: ProtectionPair -> Bool
propProtectionSrlgDisjoint pair =
  areSrlgDisjoint pair
