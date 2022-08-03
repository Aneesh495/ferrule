-- Module: Ferrule.Sim.Engine
-- Discrete-event optical network simulation execution loop.

module Ferrule.Sim.Engine where

import Ferrule.Types
import Ferrule.Routing.Graph
import Ferrule.Routing.RMSA
import Ferrule.Sim.Events
import Ferrule.Sim.Metrics

-- Complete dynamic simulation state
data SimulationState = SimulationState
  { simTopology        :: OpticalTopology
  , simEventQueue      :: EventQueue
  , simMetrics         :: NetworkMetrics
  , simActiveLightpaths :: [Lightpath]
  , simCurrentTimeSec  :: Float
  }
  deriving (Eq, Show)

-- Initialize simulation state with a given topology and pre-loaded event schedule
initSimulationState :: OpticalTopology -> EventQueue -> SimulationState
initSimulationState topo queue = SimulationState
  { simTopology         = topo
  , simEventQueue       = queue
  , simMetrics          = initNetworkMetrics
  , simActiveLightpaths = []
  , simCurrentTimeSec   = 0.0
  }

-- Step one discrete simulation event
stepSimulation :: SimulationState -> Maybe SimulationState
stepSimulation state =
  case popNextSimEvent (simEventQueue state) of
    Nothing -> Nothing  -- Queue exhausted; simulation complete
    Just (ev, remainingQueue) ->
      let timeNow = eventTimestamp ev
          updatedState = state { simEventQueue = remainingQueue, simCurrentTimeSec = timeNow }
      in Just (handleEventPayload (eventPayload ev) timeNow updatedState)

-- Handle specific event types
handleEventPayload :: SimEventType -> Float -> SimulationState -> SimulationState
handleEventPayload (EventCallArrival demand durationSec) timeNow state =
  let topo = simTopology state
  in case solveRmsaDemand demand topo of
       Nothing ->
         -- Blocked demand
         state { simMetrics = recordDemandBlocked (simMetrics state) }
       Just lightpath ->
         -- Accepted demand: schedule teardown event
         let teardownTime = timeNow + durationSec
             teardownEv = SimEvent teardownTime (EventCallTeardown (lightpathId lightpath))
             newQueue = insertSimEvent teardownEv (simEventQueue state)
             newMetrics = recordDemandAccepted (demandBitrate demand) (simMetrics state)
         in state
              { simEventQueue       = newQueue
              , simMetrics          = newMetrics
              , simActiveLightpaths = lightpath : simActiveLightpaths state
              }

handleEventPayload (EventCallTeardown lpId) _ state =
  let remainingLps = filter (\lp -> lightpathId lp /= lpId) (simActiveLightpaths state)
      newMetrics = recordLightpathTeardown (simMetrics state)
  in state
       { simActiveLightpaths = remainingLps
       , simMetrics          = newMetrics
       }

handleEventPayload (EventFiberCut linkId') _ state =
  let metrics = simMetrics state
      updatedMetrics = metrics { metricFiberCutEvents = metricFiberCutEvents metrics + 1 }
  in state { simMetrics = updatedMetrics }

handleEventPayload (EventFiberRestore linkId') _ state =
  state

-- Run simulation until the event queue is empty or max event limit is reached
runSimulationLoop :: Int -> SimulationState -> SimulationState
runSimulationLoop 0 state = state
runSimulationLoop stepsLeft state =
  case stepSimulation state of
    Nothing        -> state
    Just nextState -> runSimulationLoop (stepsLeft - 1) nextState
