-- Module: Ferrule.Physics.Fiber
-- Physical transmission fiber parameters, effective length, and attenuation loss.

module Ferrule.Physics.Fiber where

import Ferrule.Types

-- Factory for standard ITU-T G.652.D Single Mode Fiber (SMF-28)
standardSmfSpan :: Float -> Span
standardSmfSpan lengthKm = Span
  { spanLengthKm    = lengthKm
  , spanAttenuation = 0.20   -- dB/km at 1550 nm
  , spanDispersion   = 16.7   -- ps/(nm*km) at 1550 nm
  , spanNonlinear    = 1.3    -- 1/(W*km)
  , spanProfile      = StandardSMF
  }

-- Factory for ITU-T G.655 Non-Zero Dispersion Shifted Fiber (NZDSF)
nzdsfSpan :: Float -> Span
nzdsfSpan lengthKm = Span
  { spanLengthKm    = lengthKm
  , spanAttenuation = 0.22   -- dB/km at 1550 nm
  , spanDispersion   = 4.2    -- ps/(nm*km) at 1550 nm
  , spanNonlinear    = 1.7    -- 1/(W*km)
  , spanProfile      = NZDSF
  }

-- Factory for ITU-T G.656 Large Effective Area Fiber (LEAF)
leafSpan :: Float -> Span
leafSpan lengthKm = Span
  { spanLengthKm    = lengthKm
  , spanAttenuation = 0.21   -- dB/km at 1550 nm
  , spanDispersion   = 8.0    -- ps/(nm*km) at 1550 nm
  , spanNonlinear    = 1.1    -- 1/(W*km)
  , spanProfile      = LargeEffective
  }

-- Convert attenuation in dB/km to linear loss coefficient alpha (1/km)
-- alpha_linear = (alpha_db / 10) * ln(10)
attenuationDbToLinear :: Float -> Float
attenuationDbToLinear alphaDb =
  (alphaDb / 10.0) * (log 10.0)

-- Compute total end-to-end insertion loss of an unamplified fiber span in dB
spanTotalLossDb :: Span -> Float
spanTotalLossDb span =
  spanLengthKm span * spanAttenuation span

-- Compute effective nonlinear interaction length: L_eff = (1 - exp(-alpha * L)) / alpha
spanEffectiveLengthKm :: Span -> Float
spanEffectiveLengthKm span =
  let alpha = attenuationDbToLinear (spanAttenuation span)
      len   = spanLengthKm span
  in (1.0 - exp (-(alpha * len))) / alpha

-- Compute asymptotic effective length for long spans (L_eff_inf = 1 / alpha)
spanAsymptoticEffectiveLengthKm :: Span -> Float
spanAsymptoticEffectiveLengthKm span =
  let alpha = attenuationDbToLinear (spanAttenuation span)
  in 1.0 / alpha
