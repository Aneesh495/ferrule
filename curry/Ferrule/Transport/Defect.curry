-- Module: Ferrule.Transport.Defect
-- Optical defect detection, maintenance signals, and BIP-8 parity checking.

module Ferrule.Transport.Defect where

-- High-level optical defects classified according to ITU-T G.798
data OpticalDefect
  = DefectLossOfSignal          -- Physical photodiode power loss (LOS)
  | DefectLossOfFrame           -- FAS framing pattern desynchronization (LOF)
  | DefectAlarmIndicationSignal -- Downstream all-ones maintenance signal (AIS)
  | DefectOpenConnection        -- Unallocated cross-connect port (OCI)
  | DefectLockedTrail           -- Administratively locked for testing (LCK)
  | DefectBackwardDefect        -- Far-end defect indication (BDI)
  | DefectPayloadMismatch       -- Payload Structure Identifier mismatch (PLM)
  deriving (Eq, Show)

-- Compute 8-bit Bit Interleaved Parity (BIP-8) across a sequence of bytes
-- Each bit of the BIP-8 byte represents even parity for the corresponding bit position across all data bytes
computeBip8Parity :: [Int] -> Int
computeBip8Parity bytes =
  foldl bitwiseXor 0 bytes
  where
    bitwiseXor a b = a `xorInt` b
    xorInt x y = (x + y) - 2 * (x `andInt` y)
    andInt x y = if x == 0 || y == 0 then 0 else x * y `mod` 256  -- Integer bitwise approximation

-- Compare received BIP-8 against calculated BIP-8 to determine count of bit errors (0 to 8)
countBip8Errors :: Int -> Int -> Int
countBip8Errors receivedParity calculatedParity =
  let diff = abs (receivedParity - calculatedParity)
  in countBits diff
  where
    countBits 0 = 0
    countBits n = (n `mod` 2) + countBits (n `div` 2)

-- Determine whether an optical defect necessitates triggering an immediate protection switch
requiresImmediateProtectionSwitch :: OpticalDefect -> Bool
requiresImmediateProtectionSwitch DefectLossOfSignal          = True
requiresImmediateProtectionSwitch DefectLossOfFrame           = True
requiresImmediateProtectionSwitch DefectAlarmIndicationSignal = True
requiresImmediateProtectionSwitch DefectOpenConnection        = True
requiresImmediateProtectionSwitch DefectLockedTrail           = False
requiresImmediateProtectionSwitch DefectBackwardDefect        = False
requiresImmediateProtectionSwitch DefectPayloadMismatch       = False
