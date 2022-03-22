-- Module: Ferrule.Types
-- Core algebraic data types and domain models for optical transport networks.

module Ferrule.Types where

-- Physical frequency slot index representing 12.5 GHz slices on the flexible grid
type SlotIndex = Int

-- Contiguous window of spectral slots
data SpectralWindow = SpectralWindow
  { windowStart :: SlotIndex
  , windowCount :: Int
  }
  deriving (Eq, Show)

-- Standard optical fiber physical profiles
data FiberProfile
  = StandardSMF    -- Standard single mode fiber (ITU-T G.652)
  | NZDSF          -- Non-zero dispersion shifted fiber (ITU-T G.655)
  | LargeEffective -- Large effective area fiber (ITU-T G.656)
  deriving (Eq, Show)

-- Physical fiber span parameters
data Span = Span
  { spanLengthKm    :: Float
  , spanAttenuation :: Float  -- dB per km
  , spanDispersion   :: Float  -- ps / (nm * km)
  , spanNonlinear    :: Float  -- 1 / (W * km)
  , spanProfile      :: FiberProfile
  }
  deriving (Eq, Show)

-- In-line optical amplifier parameters
data Amplifier = Amplifier
  { ampGainDb       :: Float
  , ampNoiseFigureDb :: Float
  , ampMaxPowerDbm  :: Float
  }
  deriving (Eq, Show)

-- Reconfigurable Optical Add-Drop Multiplexer node
data RoadmNode = RoadmNode
  { nodeId          :: String
  , nodeDegree      :: Int
  , nodeSwitchLossDb :: Float
  }
  deriving (Eq, Show)

-- Coherent modulation formats
data ModulationScheme
  = DpBpsk     -- Dual Polarization BPSK: 1 bit per symbol per pol (100G)
  | DpQpsk     -- Dual Polarization QPSK: 2 bits per symbol per pol (200G)
  | Dp8Qam     -- Dual Polarization 8-QAM: 3 bits per symbol per pol (300G)
  | Dp16Qam    -- Dual Polarization 16-QAM: 4 bits per symbol per pol (400G)
  | Dp32Qam    -- Dual Polarization 32-QAM: 5 bits per symbol per pol (600G)
  | Dp64Qam    -- Dual Polarization 64-QAM: 6 bits per symbol per pol (800G)
  deriving (Eq, Show)

-- Transmission quality metrics computed along a lightpath
data SignalQuality = SignalQuality
  { osnrAseDb   :: Float  -- Optical SNR from amplified spontaneous emission
  , snrNliDb    :: Float  -- Non-linear interference SNR from Kerr nonlinearity
  , gsnrDb      :: Float  -- Generalized SNR combining ASE and NLI
  , qFactorDb   :: Float  -- Q-factor derived from effective SNR
  , berEstimate :: Float  -- Estimated pre-FEC bit error rate
  }
  deriving (Eq, Show)

-- Client traffic demand to be routed across the optical network
data OpticalDemand = OpticalDemand
  { demandId        :: String
  , demandSource    :: String
  , demandTarget    :: String
  , demandBitrate   :: Float  -- Required bitrate in Gbps
  , demandLatencyMax :: Float -- Maximum allowable latency in milliseconds
  }
  deriving (Eq, Show)

-- Active or planned lightpath circuit
data Lightpath = Lightpath
  { lightpathId      :: String
  , lightpathDemand  :: String
  , lightpathRoute   :: [String]          -- Ordered sequence of node identifiers
  , lightpathSlots   :: SpectralWindow    -- Allocated flexible grid slots
  , lightpathMod     :: ModulationScheme  -- Selected modulation scheme
  , lightpathQuality :: SignalQuality     -- Evaluated optical signal quality
  , lightpathBackup  :: Maybe [String]    -- Optional SRLG-disjoint backup route
  }
  deriving (Eq, Show)
