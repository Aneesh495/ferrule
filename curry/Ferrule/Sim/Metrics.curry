-- Module: Ferrule.Sim.Metrics
-- Performance metrics, Erlang traffic load, and blocking probability telemetry.

module Ferrule.Sim.Metrics where

-- Real-time telemetry recorded during discrete-event optical network simulation
data NetworkMetrics = NetworkMetrics
  { metricDemandsOffered  :: Int
  , metricDemandsAccepted :: Int
  , metricDemandsBlocked  :: Int
  , metricTotalBitsServed :: Float  -- Terabits
  , metricActiveLightpaths :: Int
  , metricFiberCutEvents  :: Int
  , metricFailoverEvents  :: Int
  }
  deriving (Eq, Show)

-- Initialize fresh metric counters
initNetworkMetrics :: NetworkMetrics
initNetworkMetrics = NetworkMetrics
  { metricDemandsOffered   = 0
  , metricDemandsAccepted  = 0
  , metricDemandsBlocked   = 0
  , metricTotalBitsServed  = 0.0
  , metricActiveLightpaths = 0
  , metricFiberCutEvents   = 0
  , metricFailoverEvents   = 0
  }

-- Compute optical blocking probability: P_block = DemandsBlocked / DemandsOffered
calculateBlockingProbability :: NetworkMetrics -> Float
calculateBlockingProbability metrics =
  let offered = metricDemandsOffered metrics
      blocked = metricDemandsBlocked metrics
  in if offered <= 0
     then 0.0
     else fromIntegral blocked / fromIntegral offered

-- Compute network traffic load in Erlangs: Load = ArrivalRate * MeanHoldingTime
computeTrafficLoadErlangs :: Float -> Float -> Float
computeTrafficLoadErlangs arrivalRatePerSec meanHoldingTimeSec =
  arrivalRatePerSec * meanHoldingTimeSec

-- Record an accepted demand
recordDemandAccepted :: Float -> NetworkMetrics -> NetworkMetrics
recordDemandAccepted bitrateGbps metrics =
  metrics
    { metricDemandsOffered   = metricDemandsOffered metrics + 1
    , metricDemandsAccepted  = metricDemandsAccepted metrics + 1
    , metricActiveLightpaths = metricActiveLightpaths metrics + 1
    , metricTotalBitsServed  = metricTotalBitsServed metrics + (bitrateGbps * 1.0e-3)
    }

-- Record a blocked demand (insufficient optical reach or spectral slots)
recordDemandBlocked :: NetworkMetrics -> NetworkMetrics
recordDemandBlocked metrics =
  metrics
    { metricDemandsOffered = metricDemandsOffered metrics + 1
    , metricDemandsBlocked = metricDemandsBlocked metrics + 1
    }

-- Record a lightpath teardown event
recordLightpathTeardown :: NetworkMetrics -> NetworkMetrics
recordLightpathTeardown metrics =
  metrics
    { metricActiveLightpaths = max 0 (metricActiveLightpaths metrics - 1) }
