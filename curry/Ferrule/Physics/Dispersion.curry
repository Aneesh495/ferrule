-- Module: Ferrule.Physics.Dispersion
-- Chromatic dispersion (CD), polarization mode dispersion (PMD), and nonlinear phase shift.

module Ferrule.Physics.Dispersion where

import Ferrule.Types
import Ferrule.Physics.Units
import Ferrule.Physics.Fiber

-- Compute accumulated chromatic dispersion across a span in ps/nm: CD = D * L
spanAccumulatedCd :: Span -> Float
spanAccumulatedCd span =
  spanDispersion span * spanLengthKm span

-- Compute total accumulated chromatic dispersion across an entire path of spans
totalPathCd :: [Span] -> Float
totalPathCd spans =
  sum (map spanAccumulatedCd spans)

-- Polarization Mode Dispersion (PMD) parameter (ps / sqrt(km))
data PmdProfile = PmdProfile
  { pmdCoefficient :: Float  -- ps / sqrt(km), typically 0.04 to 0.1 for modern fiber
  }
  deriving (Eq, Show)

standardPmdProfile :: PmdProfile
standardPmdProfile = PmdProfile { pmdCoefficient = 0.05 }

-- Mean Differential Group Delay (DGD) accumulation across a link: <Delta tau> = PMD_coeff * sqrt(L)
meanDifferentialGroupDelayPs :: PmdProfile -> Float -> Float
meanDifferentialGroupDelayPs profile lengthKm =
  pmdCoefficient profile * sqrt lengthKm

-- Total mean DGD across an optical path of spans
pathTotalDgdPs :: PmdProfile -> [Span] -> Float
pathTotalDgdPs profile spans =
  let totalLen = sum (map spanLengthKm spans)
  in meanDifferentialGroupDelayPs profile totalLen

-- Maximum tolerable DGD in ps as a fraction of symbol duration
-- For modern coherent receivers with DSP equalizer, typical limit is ~30% of symbol period
tolerableDgdLimitPs :: Float -> Float
tolerableDgdLimitPs symbolRateGbaud =
  let symbolPeriodPs = 1000.0 / symbolRateGbaud
  in 0.35 * symbolPeriodPs

-- Check whether accumulated PMD / DGD is within coherent DSP equalizer compensation capacity
isPmdAcceptable :: PmdProfile -> Float -> [Span] -> Bool
isPmdAcceptable profile symbolRateGbaud spans =
  let actualDgd = pathTotalDgdPs profile spans
      limitDgd  = tolerableDgdLimitPs symbolRateGbaud
  in actualDgd <= limitDgd

-- Compute nonlinear phase shift: phi_NL = gamma * P_launch * L_eff
spanNonlinearPhaseShiftRad :: Span -> Float -> Float
spanNonlinearPhaseShiftRad span launchPowerWatts =
  let gamma = spanNonlinear span
      leff  = spanEffectiveLengthKm span
  in gamma * launchPowerWatts * leff
