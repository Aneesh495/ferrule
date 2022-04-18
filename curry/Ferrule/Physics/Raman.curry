-- Module: Ferrule.Physics.Raman
-- Distributed Raman amplification model, on-off gain, and pump power propagation.

module Ferrule.Physics.Raman where

import Ferrule.Types
import Ferrule.Physics.Units
import Ferrule.Physics.Fiber

-- Raman amplifier pump configuration
data RamanPumpConfig = RamanPumpConfig
  { pumpPowerWatts     :: Float  -- Co-propagating or counter-propagating pump power
  , pumpWavelengthNm   :: Float  -- Typically 1455 nm for C-band gain
  , pumpGainEfficiency :: Float  -- 1 / (W * km), typical 0.5 to 0.7 for SMF
  , isCounterProp      :: Bool   -- Counter-propagating pump is standard to minimize RIN transfer
  }
  deriving (Eq, Show)

-- Standard backward (counter-propagating) Raman pump preset
standardBackwardRamanPump :: Float -> RamanPumpConfig
standardBackwardRamanPump powerWatts = RamanPumpConfig
  { pumpPowerWatts     = powerWatts
  , pumpWavelengthNm   = 1455.0
  , pumpGainEfficiency = 0.65
  , isCounterProp      = True
  }

-- Compute distributed on-off Raman gain in dB: G_on_off = 10 * log10(exp(g_R * P_pump * L_eff_pump))
ramanOnOffGainDb :: RamanPumpConfig -> Span -> Float
ramanOnOffGainDb pump span =
  let cr       = pumpGainEfficiency pump
      pPump    = pumpPowerWatts pump
      leffPump = spanEffectiveLengthKm span
      gainLin  = exp (cr * pPump * leffPump)
  in linearToDb gainLin

-- Net span gain with hybrid EDFA and backward Raman amplification
hybridSpanNetGainDb :: Amplifier -> RamanPumpConfig -> Span -> Float
hybridSpanNetGainDb edfa pump span =
  let edfaGainDb  = ampGainDb edfa
      ramanGainDb = ramanOnOffGainDb pump span
      lossDb      = spanTotalLossDb span
  in (edfaGainDb + ramanGainDb) - lossDb

-- Equivalent Noise Figure (ENF) reduction from distributed Raman pumping
-- Raman pumping effectively improves OSNR by distributing gain before the span output
effectiveNoiseFigureReductionDb :: Float -> Float
effectiveNoiseFigureReductionDb ramanGainDb =
  if ramanGainDb <= 0.0
  then 0.0
  else 0.6 * ramanGainDb
