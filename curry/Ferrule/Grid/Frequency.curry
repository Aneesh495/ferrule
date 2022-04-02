-- Module: Ferrule.Grid.Frequency
-- ITU-T G.694.1 flexible optical frequency grid definition and calculations.

module Ferrule.Grid.Frequency where

import Ferrule.Types

-- Base reference anchor frequency for the C-band flex-grid (193.100 THz)
gridAnchorFrequencyThz :: Float
gridAnchorFrequencyThz = 193.100

-- Channel slice granularity (12.5 GHz = 0.0125 THz)
slotGranularityThz :: Float
slotGranularityThz = 0.0125

-- Total number of standard 12.5 GHz slots in the optical C-band (191.325 to 196.100 THz)
totalCbandSlots :: Int
totalCbandSlots = 384

-- Minimum frequency of slot 0 in THz
cbandBaseFrequencyThz :: Float
cbandBaseFrequencyThz = 191.325

-- Compute center frequency for a given slot index
slotCenterFrequencyThz :: SlotIndex -> Float
slotCenterFrequencyThz slotIdx =
  cbandBaseFrequencyThz + (fromIntegral slotIdx * slotGranularityThz) + (slotGranularityThz / 2.0)

-- Compute center frequency for a multi-slot spectral window
windowCenterFrequencyThz :: SpectralWindow -> Float
windowCenterFrequencyThz (SpectralWindow start count) =
  let startFreq = cbandBaseFrequencyThz + (fromIntegral start * slotGranularityThz)
      bandwidth = fromIntegral count * slotGranularityThz
  in startFreq + (bandwidth / 2.0)

-- Compute nominal bandwidth in GHz for a given number of 12.5 GHz slots
slotCountToBandwidthGhz :: Int -> Float
slotCountToBandwidthGhz count =
  fromIntegral count * 12.5

-- Determine required number of 12.5 GHz slots for a given optical symbol rate (Baud)
requiredSlotCount :: Float -> Float -> Int
requiredSlotCount symbolRateGbaud rollOff =
  let occupiedGhz = symbolRateGbaud * (1.0 + rollOff)
      guardBandGhz = 5.0
      totalRequiredGhz = occupiedGhz + guardBandGhz
      exactSlots = totalRequiredGhz / 12.5
      ceilSlots = ceiling exactSlots
  in max 2 ceilSlots

-- Check whether a spectral window lies entirely within the valid C-band spectrum
isWindowValid :: SpectralWindow -> Bool
isWindowValid (SpectralWindow start count) =
  start >= 0 && count > 0 && (start + count) <= totalCbandSlots
