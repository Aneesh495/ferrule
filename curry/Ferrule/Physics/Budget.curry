-- Module: Ferrule.Physics.Budget
-- End-to-end impairment budget evaluation, GSNR combination, Q-factor, and BER estimation.

module Ferrule.Physics.Budget where

import Ferrule.Types
import Ferrule.Physics.Units
import Ferrule.Physics.Fiber
import Ferrule.Physics.EDFA
import Ferrule.Physics.GNModel

-- ROADM filter penalty: Each ROADM node introduces passband narrowing penalty (~0.15 dB SNR penalty per node)
roadmFilterPenaltyDb :: Int -> Float
roadmFilterPenaltyDb numRoadms =
  fromIntegral numRoadms * 0.15

-- Compute generalized signal to noise ratio (GSNR) combining linear ASE and nonlinear NLI noise
-- 1 / GSNR = 1 / OSNR_ASE + 1 / SNR_NLI
computeGsnrDb :: Float -> Float -> Float
computeGsnrDb osnrAseDb snrNliDb =
  combineSnrDb osnrAseDb snrNliDb

-- Convert effective SNR (GSNR in linear units) to Q-factor in dB:
-- Q_dB = 20 * log10(sqrt(SNR_linear)) = 10 * log10(SNR_linear) = SNR_dB
qFactorFromGsnrDb :: Float -> Float
qFactorFromGsnrDb gsnrDb =
  gsnrDb

-- Complementary error function approximation for BER estimation
-- erfc(x) ~ (1 / (1 + p*x)^a) ... standard Abramowitz and Stegun numerical approximation
erfcApproximation :: Float -> Float
erfcApproximation x =
  if x < 0.0
  then 2.0 - erfcApproximation (-x)
  else
    let t = 1.0 / (1.0 + 0.3275911 * x)
        poly = t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429))))
    in poly * exp (-(x * x))

-- Estimate pre-FEC Bit Error Rate from Q-factor: BER = 0.5 * erfc(Q_linear / sqrt(2))
berFromQFactorDb :: Float -> Float
berFromQFactorDb qDb =
  let qLinear = sqrt (dbToLinear qDb)
      arg = qLinear / sqrt 2.0
  in 0.5 * erfcApproximation arg

-- Complete transmission impairment evaluation across a sequence of fiber spans and ROADM nodes
evaluatePathQuality :: [Span] -> [RoadmNode] -> Float -> Float -> SignalQuality
evaluatePathQuality spans roadms launchPowerDbm centerFreqThz =
  let numSpans = max 1 (length spans)
      launchWatts = dbmToWatts launchPowerDbm
      firstSpan = head spans

      -- ASE calculation: assume each span loss is compensated by an EDFA with 5.5 dB noise figure
      avgSpanLossDb = spanTotalLossDb firstSpan
      edfa = standardEdfa avgSpanLossDb 5.5
      singleSpanOsnr = singleSpanOsnrDb launchPowerDbm centerFreqThz avgSpanLossDb (ampNoiseFigureDb edfa)
      totalOsnrAse = cascadedOsnrDb singleSpanOsnr numSpans

      -- NLI calculation: GN model
      bwGhz = 50.0  -- Standard 50 GHz DWDM grid slotting
      wavelengthNm = frequencyThzToWavelengthNm centerFreqThz
      totalSnrNli = spanSnrNliDb firstSpan launchWatts bwGhz wavelengthNm numSpans

      -- Combine and subtract ROADM filter passband narrowing penalties
      rawGsnr = computeGsnrDb totalOsnrAse totalSnrNli
      roadmPenalty = roadmFilterPenaltyDb (length roadms)
      effectiveGsnr = rawGsnr - roadmPenalty

      effectiveQ = qFactorFromGsnrDb effectiveGsnr
      estBer = berFromQFactorDb effectiveQ
  in SignalQuality
       { osnrAseDb   = totalOsnrAse
       , snrNliDb    = totalSnrNli
       , gsnrDb      = effectiveGsnr
       , qFactorDb   = effectiveQ
       , berEstimate = estBer
       }
