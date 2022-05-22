-- Module: Ferrule.Transport.GMP
-- Generic Mapping Procedure (GMP) rate adaptation and justification algorithms.

module Ferrule.Transport.GMP where

-- Generic Mapping Procedure maps an arbitrary asynchronous client signal into an OPUk payload.
-- C_m represents the number of m-bit payload entities to transmit in a server frame.
-- B represents the total available payload byte positions in the server frame (e.g. 15,232 bytes for OPUk).

data GmpMappingState = GmpMappingState
  { gmpServerCapacityBytes :: Int    -- Total payload byte positions in server frame (B)
  , gmpClientRateBytes     :: Float  -- Nominal client byte rate per server frame
  , gmpAccumulatedDelta    :: Float  -- Fractional byte accumulator (sigma-delta)
  , gmpEntitySizeBits      :: Int    -- Entity size m (typically 8 for 1-byte, or 64 for 8-byte entities)
  }
  deriving (Eq, Show)

-- Initialize standard GMP state for OPUk mapping with 8-bit entity size
initGmpState :: Int -> Float -> GmpMappingState
initGmpState capacityBytes clientRateBytes = GmpMappingState
  { gmpServerCapacityBytes = capacityBytes
  , gmpClientRateBytes     = clientRateBytes
  , gmpAccumulatedDelta    = 0.0
  , gmpEntitySizeBits      = 8
  }

-- Compute C_m (integer number of entities to send this frame) and updated fractional accumulator
stepGmpFrame :: GmpMappingState -> (Int, GmpMappingState)
stepGmpFrame state =
  let rawCount = gmpClientRateBytes state + gmpAccumulatedDelta state
      cmInt = floor rawCount
      newDelta = rawCount - fromIntegral cmInt
      clampedCm = max 0 (min (gmpServerCapacityBytes state) cmInt)
      newState = state { gmpAccumulatedDelta = newDelta }
  in (clampedCm, newState)

-- Distribute C_m payload entities uniformly across B available positions using the Bresenham / Sigma-Delta algorithm
-- Returns a list of booleans of length B (True = Payload entity, False = Justification / Stuff byte)
distributePayloadEntities :: Int -> Int -> [Bool]
distributePayloadEntities capacityB countCm =
  if countCm <= 0
  then replicate capacityB False
  else if countCm >= capacityB
       then replicate capacityB True
       else generatePositions 0 0
  where
    generatePositions idx acc
      | idx >= capacityB = []
      | otherwise =
          let nextAcc = acc + countCm
              isPayload = nextAcc >= capacityB
              adjustedAcc = if isPayload then nextAcc - capacityB else nextAcc
          in isPayload : generatePositions (idx + 1) adjustedAcc

-- Count stuffing bytes generated for a given (B, C_m) pair
stuffingByteCount :: Int -> Int -> Int
stuffingByteCount capacityB countCm =
  max 0 (capacityB - countCm)
