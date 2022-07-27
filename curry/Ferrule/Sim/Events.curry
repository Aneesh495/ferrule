-- Module: Ferrule.Sim.Events
-- Discrete-event optical traffic simulation event queue and timeline.

module Ferrule.Sim.Events where

import Ferrule.Types

-- Event classification in dynamic optical network simulation
data SimEventType
  = EventCallArrival OpticalDemand Float  -- New demand arrival with requested holding duration (seconds)
  | EventCallTeardown String              -- Teardown of established lightpath ID
  | EventFiberCut String                  -- Physical fiber cut event on link ID
  | EventFiberRestore String              -- Physical repair and restoration event on link ID
  deriving (Eq, Show)

-- Discrete simulation event scheduled at an absolute timestamp (in seconds)
data SimEvent = SimEvent
  { eventTimestamp :: Float
  , eventPayload   :: SimEventType
  }
  deriving (Eq, Show)

-- Priority event queue ordered by ascending timestamp
type EventQueue = [SimEvent]

-- Insert an event into the sorted event queue
insertSimEvent :: SimEvent -> EventQueue -> EventQueue
insertSimEvent ev [] = [ev]
insertSimEvent ev (e:es)
  | eventTimestamp ev <= eventTimestamp e = ev : e : es
  | otherwise                            = e : insertSimEvent ev es

-- Pop the earliest simulation event from the queue
popNextSimEvent :: EventQueue -> Maybe (SimEvent, EventQueue)
popNextSimEvent [] = Nothing
popNextSimEvent (e:es) = Just (e, es)
