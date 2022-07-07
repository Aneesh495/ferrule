-- Module: Ferrule.GMPLS.ProtectionSwitch
-- ITU-T G.808.1 sub-50ms linear protection switching state machine and APS protocol.

module Ferrule.GMPLS.ProtectionSwitch where

-- APS request priorities defined in ITU-T G.808.1 / G.873.1
data ApsRequestPriority
  = RequestLockout            -- Priority 1: Lockout of protection (LO)
  | RequestForcedSwitch       -- Priority 2: Forced switch to protection (FS)
  | RequestSignalFailWorking  -- Priority 3: Signal Fail on working entity (SF-W, e.g. fiber cut)
  | RequestSignalFailProtect  -- Priority 4: Signal Fail on protection entity (SF-P)
  | RequestSignalDegrade      -- Priority 5: Signal Degrade (SD, excessive BER)
  | RequestManualSwitch       -- Priority 6: Manual switch (MS)
  | RequestWaitToRestore      -- Priority 7: Wait To Restore timer active (WTR)
  | RequestNoRequest          -- Priority 8: Normal idle transmission (NR)
  deriving (Eq, Show, Ord)

-- Active optical selector state
data SelectorPosition
  = SelectWorkingPath
  | SelectProtectionPath
  deriving (Eq, Show)

-- Protection switching controller state
data ProtectionSwitchState = ProtectionSwitchState
  { switchSelectorPosition :: SelectorPosition
  , switchActivePriority   :: ApsRequestPriority
  , switchWtrTimerSeconds  :: Int               -- Wait-to-Restore timer (typically 300 seconds)
  , switchIsRevertive      :: Bool              -- Revert back to working when healed
  , switchTotalSwitchCount :: Int
  }
  deriving (Eq, Show)

-- Initialize a standard revertive 1+1 protection switch state
initProtectionSwitchState :: ProtectionSwitchState
initProtectionSwitchState = ProtectionSwitchState
  { switchSelectorPosition = SelectWorkingPath
  , switchActivePriority   = RequestNoRequest
  , switchWtrTimerSeconds  = 0
  , switchIsRevertive      = True
  , switchTotalSwitchCount = 0
  }

-- Handle incoming event priority and update selector position
processSwitchEvent :: ApsRequestPriority -> ProtectionSwitchState -> ProtectionSwitchState
processSwitchEvent RequestLockout state =
  state
    { switchSelectorPosition = SelectWorkingPath
    , switchActivePriority   = RequestLockout
    }
processSwitchEvent RequestForcedSwitch state =
  state
    { switchSelectorPosition = SelectProtectionPath
    , switchActivePriority   = RequestForcedSwitch
    , switchTotalSwitchCount = switchTotalSwitchCount state + 1
    }
processSwitchEvent RequestSignalFailWorking state =
  if switchActivePriority state <= RequestForcedSwitch
  then state  -- Higher priority override in effect
  else state
         { switchSelectorPosition = SelectProtectionPath
         , switchActivePriority   = RequestSignalFailWorking
         , switchTotalSwitchCount = switchTotalSwitchCount state + 1
         }
processSwitchEvent RequestSignalFailProtect state =
  state
    { switchSelectorPosition = SelectWorkingPath
    , switchActivePriority   = RequestSignalFailProtect
    }
processSwitchEvent RequestNoRequest state =
  if switchSelectorPosition state == SelectProtectionPath && switchIsRevertive state
  then state
         { switchSelectorPosition = SelectWorkingPath
         , switchActivePriority   = RequestNoRequest
         , switchWtrTimerSeconds  = 0
         }
  else state { switchActivePriority = RequestNoRequest }
processSwitchEvent other state =
  state { switchActivePriority = other }

-- Verify whether the system achieved sub-50ms protection switching time budget
isSwitchWithin50MsBudget :: Float -> Bool
isSwitchWithin50MsBudget measuredTimeMs =
  measuredTimeMs <= 50.0
