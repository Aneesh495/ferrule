-- Module: Ferrule.Transport.Multiplex
-- Optical Data Unit (ODUk) hierarchy and Tributary Slot (TS) multiplexing trees.

module Ferrule.Transport.Multiplex where

-- Discrete standard ODUk container types
data OduContainer
  = Odu0      -- 1.244160 Gbps (Gigabit Ethernet mapping)
  | Odu1      -- 2.498775 Gbps (STM-16 / 2x ODU0)
  | Odu2      -- 9.995276 Gbps (STM-64 / 10GE LAN / 8x ODU0)
  | Odu2e     -- 10.356001 Gbps (Overclocked 10GE LAN without GFP)
  | Odu3      -- 40.150519 Gbps (STM-256 / 40GE / 32x ODU0)
  | Odu4      -- 104.355975 Gbps (100GE / 80x ODU0)
  | OduFlex   -- Variable bandwidth client container: n * 1.244160 Gbps
  deriving (Eq, Show)

-- Total number of 1.25 Gbps Tributary Slots (TS) available in higher-order ODUk containers
tributarySlotCapacity :: OduContainer -> Int
tributarySlotCapacity Odu1    = 2
tributarySlotCapacity Odu2    = 8
tributarySlotCapacity Odu3    = 32
tributarySlotCapacity Odu4    = 80
tributarySlotCapacity _       = 1

-- Number of 1.25 Gbps tributary slots consumed by a client container
slotsConsumedByContainer :: OduContainer -> Int
slotsConsumedByContainer Odu0    = 1
slotsConsumedByContainer Odu1    = 2
slotsConsumedByContainer Odu2    = 8
slotsConsumedByContainer Odu2e   = 9
slotsConsumedByContainer Odu3    = 32
slotsConsumedByContainer Odu4    = 80
slotsConsumedByContainer OduFlex = 1

-- Tributary Slot Allocation table mapping TS index to assigned client tributary port
type TributarySlotTable = [(Int, Maybe String)]

-- Initialize an empty tributary slot table for a higher-order container
initTributarySlotTable :: OduContainer -> TributarySlotTable
initTributarySlotTable container =
  let cap = tributarySlotCapacity container
  in [(tsIdx, Nothing) | tsIdx <- [1..cap]]

-- Check if sufficient free tributary slots exist to multiplex a child container
canMultiplexContainer :: OduContainer -> TributarySlotTable -> Bool
canMultiplexContainer child table =
  let needed = slotsConsumedByContainer child
      freeSlots = length (filter (\(_, assigned) -> assigned == Nothing) table)
  in freeSlots >= needed

-- Allocate tributary slots for a named client connection
allocateTributarySlots :: String -> Int -> TributarySlotTable -> Maybe TributarySlotTable
allocateTributarySlots clientName neededSlots table =
  let (freeEntries, busyEntries) = (filter (\(_, a) -> a == Nothing) table, filter (\(_, a) -> a /= Nothing) table)
  in if length freeEntries < neededSlots
     then Nothing
     else
       let allocated = [(ts, Just clientName) | (ts, _) <- take neededSlots freeEntries]
           remaining = drop neededSlots freeEntries
           newTable = busyEntries ++ allocated ++ remaining
       in Just newTable

-- Release tributary slots assigned to a client connection
releaseTributarySlots :: String -> TributarySlotTable -> TributarySlotTable
releaseTributarySlots clientName table =
  map (\(ts, assigned) -> if assigned == Just clientName then (ts, Nothing) else (ts, assigned)) table
