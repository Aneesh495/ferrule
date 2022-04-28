-- Module: Ferrule.Physics.Modulation
-- Coherent modulation schemes, spectral efficiency, required OSNR, and reach limits.

module Ferrule.Physics.Modulation where

import Ferrule.Types

-- Spectral efficiency in bits per second per Hertz (bits/s/Hz) across dual polarizations
modulationSpectralEfficiency :: ModulationScheme -> Float
modulationSpectralEfficiency DpBpsk  = 2.0   -- 1 bit/symbol * 2 pols
modulationSpectralEfficiency DpQpsk  = 4.0   -- 2 bits/symbol * 2 pols
modulationSpectralEfficiency Dp8Qam  = 6.0   -- 3 bits/symbol * 2 pols
modulationSpectralEfficiency Dp16Qam = 8.0   -- 4 bits/symbol * 2 pols
modulationSpectralEfficiency Dp32Qam = 10.0  -- 5 bits/symbol * 2 pols
modulationSpectralEfficiency Dp64Qam = 12.0  -- 6 bits/symbol * 2 pols

-- Minimum required Generalized Signal to Noise Ratio (GSNR in dB) for 15% Soft-Decision FEC threshold (BER = 2e-2)
modulationRequiredGsnrDb :: ModulationScheme -> Float
modulationRequiredGsnrDb DpBpsk  = 7.0
modulationRequiredGsnrDb DpQpsk  = 10.5
modulationRequiredGsnrDb Dp8Qam  = 14.5
modulationRequiredGsnrDb Dp16Qam = 17.0
modulationRequiredGsnrDb Dp32Qam = 20.5
modulationRequiredGsnrDb Dp64Qam = 24.0

-- Minimum required Optical Signal to Noise Ratio (OSNR in dB, reference 0.1 nm bandwidth)
modulationRequiredOsnrDb :: ModulationScheme -> Float
modulationRequiredOsnrDb DpBpsk  = 8.5
modulationRequiredOsnrDb DpQpsk  = 12.0
modulationRequiredOsnrDb Dp8Qam  = 16.0
modulationRequiredOsnrDb Dp16Qam = 18.5
modulationRequiredOsnrDb Dp32Qam = 22.0
modulationRequiredOsnrDb Dp64Qam = 25.5

-- Typical optical reach limit in kilometers on standard SMF-28 without regeneration
modulationMaxReachKm :: ModulationScheme -> Float
modulationMaxReachKm DpBpsk  = 5000.0  -- Ultra-long-haul / transoceanic
modulationMaxReachKm DpQpsk  = 3000.0  -- Long-haul core
modulationMaxReachKm Dp8Qam  = 1800.0  -- Extended regional
modulationMaxReachKm Dp16Qam = 1000.0  -- Regional metro
modulationMaxReachKm Dp32Qam = 500.0   -- Metro core
modulationMaxReachKm Dp64Qam = 200.0   -- Data center interconnect (DCI)

-- Net data rate in Gbps for a given modulation scheme operating at a standard 64 GBaud symbol rate
modulationDataRate64Gbaud :: ModulationScheme -> Float
modulationDataRate64Gbaud scheme =
  let bitsPerSymPol = case scheme of
        DpBpsk  -> 1.0
        DpQpsk  -> 2.0
        Dp8Qam  -> 3.0
        Dp16Qam -> 4.0
        Dp32Qam -> 5.0
        Dp64Qam -> 6.0
      grossRate = 64.0 * bitsPerSymPol * 2.0  -- Dual polarization
      fecOverhead = 0.15                      -- 15% SD-FEC
  in grossRate / (1.0 + fecOverhead)

-- Check whether a candidate modulation scheme satisfies both the physical reach and GSNR criteria
isModulationFeasible :: ModulationScheme -> Float -> Float -> Bool
isModulationFeasible scheme pathLengthKm pathGsnrDb =
  let reachOk = pathLengthKm <= modulationMaxReachKm scheme
      gsnrOk  = pathGsnrDb >= modulationRequiredGsnrDb scheme
  in reachOk && gsnrOk

-- Select the highest spectral efficiency modulation format feasible for a given path length and GSNR
selectBestModulation :: Float -> Float -> Maybe ModulationScheme
selectBestModulation pathLengthKm pathGsnrDb =
  let candidates = [Dp64Qam, Dp32Qam, Dp16Qam, Dp8Qam, DpQpsk, DpBpsk]
      feasible = filter (\m -> isModulationFeasible m pathLengthKm pathGsnrDb) candidates
  in case feasible of
       []    -> Nothing
       (m:_) -> Just m
