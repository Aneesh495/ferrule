-- Module: Ferrule.GMPLS.LMP
-- Link Management Protocol (LMP - RFC 4204) state machine for optical control channels.

module Ferrule.GMPLS.LMP where

-- Control Channel (CC) operational state machine (RFC 4204 Section 3.1)
data ControlChannelState
  = CcStateDown
  | CcStateConfSend
  | CcStateConfRcvd
  | CcStateUp
  | CcStateGoingDown
  deriving (Eq, Show)

-- Link verification state
data LinkVerifyState
  = VerifyStateInactive
  | VerifyStateRunning
  | VerifyStateCompleted
  | VerifyStateFailed
  deriving (Eq, Show)

-- LMP Control Channel configuration record
data LmpControlChannel = LmpControlChannel
  { ccId             :: Int
  , ccLocalNodeId    :: String
  , ccRemoteNodeId   :: String
  , ccState          :: ControlChannelState
  , ccHelloSeqLocal  :: Int
  , ccHelloSeqRemote :: Int
  , ccHelloIntervalMs :: Int   -- Typical 150 ms
  , ccDeadIntervalMs  :: Int   -- Typical 600 ms (4x Hello interval)
  }
  deriving (Eq, Show)

-- Initialize a fresh control channel in Down state
initControlChannel :: Int -> String -> String -> LmpControlChannel
initControlChannel channelId localId remoteId = LmpControlChannel
  { ccId              = channelId
  , ccLocalNodeId     = localId
  , ccRemoteNodeId    = remoteId
  , ccState           = CcStateDown
  , ccHelloSeqLocal   = 0
  , ccHelloSeqRemote  = 0
  , ccHelloIntervalMs = 150
  , ccDeadIntervalMs  = 600
  }

-- Event trigger: Transmit Config message
onTransmitConfig :: LmpControlChannel -> LmpControlChannel
onTransmitConfig cc =
  cc { ccState = CcStateConfSend }

-- Event trigger: Receive valid Config message from peer
onReceiveConfig :: LmpControlChannel -> LmpControlChannel
onReceiveConfig cc =
  case ccState cc of
    CcStateDown     -> cc { ccState = CcStateConfRcvd }
    CcStateConfSend -> cc { ccState = CcStateUp }
    _               -> cc

-- Event trigger: Receive ConfigAck message
onReceiveConfigAck :: LmpControlChannel -> LmpControlChannel
onReceiveConfigAck cc =
  case ccState cc of
    CcStateConfSend -> cc { ccState = CcStateUp }
    CcStateConfRcvd -> cc { ccState = CcStateUp }
    _               -> cc

-- Step Hello protocol sequence counter
stepHelloSequence :: LmpControlChannel -> Int -> LmpControlChannel
stepHelloSequence cc remoteSeq =
  cc
    { ccHelloSeqLocal  = ccHelloSeqLocal cc + 1
    , ccHelloSeqRemote = remoteSeq
    }

-- Check whether the control channel is currently established and capable of routing signaling messages
isControlChannelOperational :: LmpControlChannel -> Bool
isControlChannelOperational cc =
  ccState cc == CcStateUp
