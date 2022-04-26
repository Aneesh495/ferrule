-- Module: Ferrule.Physics.GNModel
-- The Gaussian Noise (GN) analytical model for coherent optical transmission.

module Ferrule.Physics.GNModel where

import Ferrule.Types
import Ferrule.Physics.Units
import Ferrule.Physics.Fiber

-- High-accuracy closed-form approximation of the single-channel incoherent GN-model.
-- Evaluates non-linear interference power spectral density G_NLI (Watts / Hz) at center frequency.
-- Formula based on:
-- G_NLI = (8/27) * (gamma^2 * G_WD^3 * L_eff^2) / (2 * pi * alpha * |beta2|) * asinh((pi^2 / 2) * |beta2| / alpha * B_ch^2)

-- Dispersion parameter D to group velocity dispersion parameter beta2 (ps^2 / km)
-- beta2 = - (lambda^2 / (2 * pi * c)) * D
dispersionParameterToBeta2 :: Float -> Float -> Float
dispersionParameterToBeta2 dispPsNmKm wavelengthNm =
  let lambdaM = wavelengthNm * 1.0e-9
      cMps    = speedOfLightMps
      dispM   = dispPsNmKm * 1.0e-6  -- Convert to s / (m * m)
      beta2M  = - ((lambdaM * lambdaM) / (2.0 * pi * cMps)) * dispM
  in beta2M * 1.0e27 * 1.0e-3  -- ps^2 / km

-- Compute single-span nonlinear interference (NLI) power spectral density in W/Hz
spanNliPowerSpectralDensityWpHz :: Span -> Float -> Float -> Float -> Float
spanNliPowerSpectralDensityWpHz span launchPowerWatts channelBandwidthGhz centerWavelengthNm =
  let gamma   = spanNonlinear span * 1.0e-3             -- 1 / (W * m)
      alphaDb = spanAttenuation span                    -- dB / km
      alpha   = attenuationDbToLinear alphaDb * 1.0e-3  -- 1 / m
      dParam  = spanDispersion span
      beta2Ps2Km = dispersionParameterToBeta2 dParam centerWavelengthNm
      beta2S2m   = abs (beta2Ps2Km * 1.0e-24 * 1.0e-3)  -- s^2 / m
      bwHz    = channelBandwidthGhz * 1.0e9             -- Hz
      psdTx   = launchPowerWatts / bwHz                 -- W / Hz
      leffM   = spanEffectiveLengthKm span * 1000.0     -- m

      -- Coefficient: (8/27) * gamma^2 * psdTx^3 * leff^2
      prefactor = (8.0 / 27.0) * (gamma * gamma) * (psdTx * psdTx * psdTx) * (leffM * leffM)

      -- Denominator factor: 2 * pi * alpha * |beta2|
      denom = 2.0 * pi * alpha * beta2S2m

      -- Logarithmic/asinh bandwidth expansion argument: (pi^2 / 2) * (|beta2| / alpha) * Bw^2
      arg = (pi * pi / 2.0) * (beta2S2m / alpha) * (bwHz * bwHz)
      asinhTerm = log (arg + sqrt (arg * arg + 1.0))
  in if denom <= 0.0
     then 0.0
     else (prefactor / denom) * asinhTerm

-- Total NLI noise power across channel bandwidth for a single span
spanTotalNliPowerWatts :: Span -> Float -> Float -> Float -> Float
spanTotalNliPowerWatts span launchPowerWatts channelBandwidthGhz centerWavelengthNm =
  let psdNli = spanNliPowerSpectralDensityWpHz span launchPowerWatts channelBandwidthGhz centerWavelengthNm
      bwHz   = channelBandwidthGhz * 1.0e9
  in psdNli * bwHz

-- Coherent accumulation of NLI over N identical spans using the logarithmic GN scaling model:
-- P_NLI_total = N_spans^(1 + epsilon) * P_NLI_single
-- where epsilon represents the coherent phase coherence factor (typically 0.05 for SMF)
multiSpanTotalNliPowerWatts :: Span -> Float -> Float -> Float -> Int -> Float
multiSpanTotalNliPowerWatts span launchPowerWatts channelBandwidthGhz centerWavelengthNm numSpans =
  let singleNli = spanTotalNliPowerWatts span launchPowerWatts channelBandwidthGhz centerWavelengthNm
      epsilon   = 0.05
      scaling   = (fromIntegral numSpans) ** (1.0 + epsilon)
  in singleNli * scaling

-- Compute Nonlinear Signal to Noise Ratio: SNR_NLI (in dB)
spanSnrNliDb :: Span -> Float -> Float -> Float -> Int -> Float
spanSnrNliDb span launchPowerWatts channelBandwidthGhz centerWavelengthNm numSpans =
  let totalNliWatts = multiSpanTotalNliPowerWatts span launchPowerWatts channelBandwidthGhz centerWavelengthNm numSpans
  in if totalNliWatts <= 0.0
     then 100.0
     else linearToDb (launchPowerWatts / totalNliWatts)
