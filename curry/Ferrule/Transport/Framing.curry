-- Module: Ferrule.Transport.Framing
-- ITU-T G.709 Optical Transport Network (OTN) frame structure and digital wrapper.

module Ferrule.Transport.Framing where

-- The standard G.709 frame is structured as 4 rows by 4080 columns (16,320 bytes total).
-- Columns 1 to 14:   OTU/ODU overhead and FAS (Frame Alignment Signal)
-- Columns 15 to 16:  OPU (Optical Payload Unit) overhead
-- Columns 17 to 3824: OPU payload area (client data)
-- Columns 3825 to 4080: Reed-Solomon RS(255, 239) Forward Error Correction (FEC) parity

totalFrameRows :: Int
totalFrameRows = 4

totalFrameColumns :: Int
totalFrameColumns = 4080

totalFrameBytes :: Int
totalFrameBytes = totalFrameRows * totalFrameColumns  -- 16,320 bytes

overheadColumns :: Int
overheadColumns = 16

payloadColumns :: Int
payloadColumns = 3808  -- 3824 - 16

fecColumns :: Int
fecColumns = 256       -- 4080 - 3824

-- Frame Alignment Signal (FAS) fixed 6-byte pattern: 0xF6, 0xF6, 0xF6, 0x28, 0x28, 0x28
standardFasPattern :: [Int]
standardFasPattern = [0xF6, 0xF6, 0xF6, 0x28, 0x28, 0x28]

-- Frame Alignment status
data AlignmentStatus
  = InFrameState
  | OutOfFrameState
  | LossOfFrameState
  deriving (Eq, Show)

-- Optical Transport Unit (OTU) frame structure model
data OtnFrame = OtnFrame
  { frameIdentifier :: Int          -- Sequential frame number
  , frameMfas       :: Int          -- Multi-Frame Alignment Signal (0 to 255)
  , frameFasPattern :: [Int]        -- 6-byte FAS header
  , frameOverhead   :: [Int]        -- ODU overhead bytes (TCM, APS/PCC, GCC)
  , framePayloadLen :: Int          -- Number of active payload bytes
  , frameFecValid   :: Bool         -- True if RS(255, 239) syndrome is zero
  }
  deriving (Eq, Show)

-- Verify whether incoming bytes match the G.709 FAS pattern
checkFasAlignment :: [Int] -> Bool
checkFasAlignment bytes =
  take 6 bytes == standardFasPattern

-- Compute G.709 raw bit rates for OTU hierarchy in Gbps
otuNominalBitrateGbps :: Int -> Float
otuNominalBitrateGbps 1 = 2.666057     -- OTU1 (carrying STM-16 / ODU1)
otuNominalBitrateGbps 2 = 10.709225    -- OTU2 (carrying STM-64 / 10GbE / ODU2)
otuNominalBitrateGbps 3 = 43.018413    -- OTU3 (carrying STM-256 / 40GbE / ODU3)
otuNominalBitrateGbps 4 = 111.809973   -- OTU4 (carrying 100GbE / ODU4)
otuNominalBitrateGbps _ = 0.0

-- Create a pristine G.709 frame with valid FAS and MFAS counter
buildPristineFrame :: Int -> Int -> OtnFrame
buildPristineFrame frameSeq mfasCount = OtnFrame
  { frameIdentifier = frameSeq
  , frameMfas       = mfasCount `mod` 256
  , frameFasPattern = standardFasPattern
  , frameOverhead   = replicate 10 0
  , framePayloadLen = payloadColumns * totalFrameRows
  , frameFecValid   = True
  }
