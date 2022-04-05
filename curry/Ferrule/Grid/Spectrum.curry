-- Module: Ferrule.Grid.Spectrum
-- Spectrum occupancy representation, continuity, and slot allocation logic.

module Ferrule.Grid.Spectrum where

import Ferrule.Types
import Ferrule.Grid.Frequency

-- A LinkSpectrum represents a list of booleans of length totalCbandSlots (True = Available, False = InUse)
type LinkSpectrum = [Bool]

-- Initialize a completely free optical spectrum for a fiber link
initEmptySpectrum :: LinkSpectrum
initEmptySpectrum = replicate totalCbandSlots True

-- Check whether a specific slot is available in the spectrum
isSlotFree :: SlotIndex -> LinkSpectrum -> Bool
isSlotFree idx spec
  | idx < 0 || idx >= length spec = False
  | otherwise                     = spec !! idx

-- Check if an entire contiguous window of slots is free
isWindowFree :: SpectralWindow -> LinkSpectrum -> Bool
isWindowFree (SpectralWindow start count) spec
  | not (isWindowValid (SpectralWindow start count)) = False
  | otherwise =
      let slice = take count (drop start spec)
      in all (== True) slice

-- Allocate a spectral window, marking its slots as unavailable (False)
allocateWindow :: SpectralWindow -> LinkSpectrum -> LinkSpectrum
allocateWindow (SpectralWindow start count) spec =
  let prefix = take start spec
      allocated = replicate count False
      suffix = drop (start + count) spec
  in prefix ++ allocated ++ suffix

-- Release a spectral window, returning its slots to the available pool (True)
releaseWindow :: SpectralWindow -> LinkSpectrum -> LinkSpectrum
releaseWindow (SpectralWindow start count) spec =
  let prefix = take start spec
      freed = replicate count True
      suffix = drop (start + count) spec
  in prefix ++ freed ++ suffix

-- Compute the intersection of available spectrum across a path of multiple links
-- (True only if the slot is free on EVERY link in the path)
intersectPathSpectra :: [LinkSpectrum] -> LinkSpectrum
intersectPathSpectra [] = []
intersectPathSpectra [s] = s
intersectPathSpectra (s:ss) =
  zipWith (&&) s (intersectPathSpectra ss)

-- Find all contiguous free blocks of at least 'neededSlots' in a spectrum
findContiguousWindows :: Int -> LinkSpectrum -> [SpectralWindow]
findContiguousWindows neededSlots spec =
  scanBlocks 0 0 spec
  where
    scanBlocks _ _ [] = []
    scanBlocks curIdx curLen (b:bs)
      | b = if (curLen + 1) >= neededSlots
            then SpectralWindow (curIdx - curLen) (curLen + 1) : scanBlocks (curIdx + 1) (curLen + 1) bs
            else scanBlocks (curIdx + 1) (curLen + 1) bs
      | otherwise = scanBlocks (curIdx + 1) 0 bs

-- Calculate the Shannon-entropy-based spectrum fragmentation index (0.0 = clean, 1.0 = severely fragmented)
calculateFragmentationRatio :: LinkSpectrum -> Float
calculateFragmentationRatio spec =
  let freeRuns = extractFreeRuns spec
      totalFree = sum freeRuns
  in if totalFree <= 0
     then 0.0
     else let maxRun = fromIntegral (maximum (0 : freeRuns))
              freeTot = fromIntegral totalFree
          in 1.0 - (maxRun / freeTot)
  where
    extractFreeRuns [] = []
    extractFreeRuns (True:bs) =
      let (trues, rest) = span (== True) (True:bs)
      in length trues : extractFreeRuns rest
    extractFreeRuns (False:bs) =
      extractFreeRuns (dropWhile (== False) bs)
