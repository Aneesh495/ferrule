-- Module: Ferrule.Routing.Defrag
-- Hitless push-pull optical spectrum defragmentation and carrier retuning.

module Ferrule.Routing.Defrag where

import Ferrule.Types
import Ferrule.Grid.Frequency
import Ferrule.Grid.Spectrum

-- A Defragmentation Step represents retuning one lightpath from its current window to a target window
data DefragStep = DefragStep
  { defragLightpathId :: String
  , currentWindow     :: SpectralWindow
  , targetWindow      :: SpectralWindow
  , retuningShiftSlots :: Int           -- Signed shift in 12.5 GHz slot units
  }
  deriving (Eq, Show)

-- Verify that a defragmentation retuning step is hitless
-- (The shift must move into adjacent or immediately free spectrum without colliding with active lightpaths)
isDefragStepHitless :: DefragStep -> LinkSpectrum -> Bool
isDefragStepHitless step currentSpec =
  let curWin = currentWindow step
      tgtWin = targetWindow step
      -- Free the current window temporarily to inspect if target window is available
      specWithoutCur = releaseWindow curWin currentSpec
  in isWindowFree tgtWin specWithoutCur

-- Compact spectrum by shifting a lightpath towards the base of the C-band (left compaction)
computeLeftCompactionStep :: Lightpath -> LinkSpectrum -> Maybe DefragStep
computeLeftCompactionStep lightpath spec =
  let curWin = lightpathSlots lightpath
      start = windowStart curWin
      count = windowCount curWin
      specWithoutCur = releaseWindow curWin spec
      candidateStarts = [0 .. (start - 1)]
      validStarts = filter (\s -> isWindowFree (SpectralWindow s count) specWithoutCur) candidateStarts
  in case validStarts of
       []        -> Nothing
       (firstValid:_) ->
         let target = SpectralWindow firstValid count
             shift = firstValid - start
         in Just DefragStep
              { defragLightpathId  = lightpathId lightpath
              , currentWindow      = curWin
              , targetWindow       = target
              , retuningShiftSlots = shift
              }

-- Plan a sequence of defragmentation steps across an active set of lightpaths on a link
planSpectrumDefragmentation :: [Lightpath] -> LinkSpectrum -> [DefragStep]
planSpectrumDefragmentation [] _ = []
planSpectrumDefragmentation (lp:lps) spec =
  case computeLeftCompactionStep lp spec of
    Nothing   -> planSpectrumDefragmentation lps spec
    Just step ->
      let updatedSpec = allocateWindow (targetWindow step) (releaseWindow (currentWindow step) spec)
      in step : planSpectrumDefragmentation lps updatedSpec
