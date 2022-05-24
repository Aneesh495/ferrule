-- Module: Ferrule.Transport.TCM
-- Tandem Connection Monitoring (TCM) sublayer for multi-operator administrative domains.

module Ferrule.Transport.TCM where

-- G.709 defines 6 independent TCM levels (TCM1 through TCM6) in the ODU overhead.
-- Each TCM level contains:
-- - TTI (Trail Trace Identifier: 64 bytes)
-- - BIP-8 (Bit Interleaved Parity 8)
-- - BEI / BDI (Backward Error / Backward Defect Indication)
-- - STAT (Status bits: 001=Normal, 010=BDI, 101=LCK, 110=OCI, 111=AIS)

data TcmLevel = TCM1 | TCM2 | TCM3 | TCM4 | TCM5 | TCM6
  deriving (Eq, Show, Enum)

data TcmStatus
  = TcmNormal
  | TcmBdi
  | TcmLck
  | TcmOci
  | TcmAis
  | TcmUnassigned
  deriving (Eq, Show)

data TcmSublayerState = TcmSublayerState
  { tcmLevelNumber     :: TcmLevel
  , tcmOperatorDomain  :: String
  , tcmCurrentStatus   :: TcmStatus
  , tcmBip8ErrorCount  :: Int
  , tcmFarEndBeiCount  :: Int
  }
  deriving (Eq, Show)

-- Initialize a clean TCM sublayer for an administrative domain
initTcmSublayer :: TcmLevel -> String -> TcmSublayerState
initTcmSublayer level domain = TcmSublayerState
  { tcmLevelNumber     = level
  , tcmOperatorDomain  = domain
  , tcmCurrentStatus   = TcmNormal
  , tcmBip8ErrorCount  = 0
  , tcmFarEndBeiCount  = 0
  }

-- Process incoming TCM status code bits (3-bit STAT field)
decodeTcmStatusBits :: Int -> TcmStatus
decodeTcmStatusBits 1 = TcmNormal
decodeTcmStatusBits 2 = TcmBdi
decodeTcmStatusBits 5 = TcmLck
decodeTcmStatusBits 6 = TcmOci
decodeTcmStatusBits 7 = TcmAis
decodeTcmStatusBits _ = TcmUnassigned

-- Encode TCM status to G.709 3-bit code
encodeTcmStatusBits :: TcmStatus -> Int
encodeTcmStatusBits TcmNormal     = 1
encodeTcmStatusBits TcmBdi        = 2
encodeTcmStatusBits TcmLck        = 5
encodeTcmStatusBits TcmOci        = 6
encodeTcmStatusBits TcmAis        = 7
encodeTcmStatusBits TcmUnassigned = 0

-- Record parity error in TCM sublayer state
recordTcmParityErrors :: Int -> TcmSublayerState -> TcmSublayerState
recordTcmParityErrors errors state =
  state { tcmBip8ErrorCount = tcmBip8ErrorCount state + errors }
