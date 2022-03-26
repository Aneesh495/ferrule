-- Module: Ferrule.Physics.Units
-- Physical constants, unit conversions, and optical spectrum mathematics.

module Ferrule.Physics.Units where

-- Fundamental physical constants
speedOfLightMps :: Float
speedOfLightMps = 299792458.0

planckConstantJs :: Float
planckConstantJs = 6.62607015e-34

-- Standard reference wavelength and frequency
referenceWavelengthNm :: Float
referenceWavelengthNm = 1550.0

referenceFrequencyThz :: Float
referenceFrequencyThz = 193.41449

-- Convert optical frequency (THz) to wavelength (nm)
frequencyThzToWavelengthNm :: Float -> Float
frequencyThzToWavelengthNm freqThz =
  (speedOfLightMps / (freqThz * 1.0e12)) * 1.0e9

-- Convert wavelength (nm) to optical frequency (THz)
wavelengthNmToFrequencyThz :: Float -> Float
wavelengthNmToFrequencyThz waveNm =
  (speedOfLightMps / (waveNm * 1.0e-9)) * 1.0e-12

-- Convert linear power (Watts) to decibels relative to milliwatt (dBm)
wattsToDbm :: Float -> Float
wattsToDbm watts =
  10.0 * (log (watts * 1000.0) / log 10.0)

-- Convert dBm to linear power (Watts)
dbmToWatts :: Float -> Float
dbmToWatts dbm =
  (10.0 ** (dbm / 10.0)) / 1000.0

-- Convert linear ratio to decibels (dB)
linearToDb :: Float -> Float
linearToDb ratio =
  10.0 * (log ratio / log 10.0)

-- Convert decibels (dB) to linear ratio
dbToLinear :: Float -> Float
dbToLinear db =
  10.0 ** (db / 10.0)

-- Combine two independent noise powers in linear domain and return total in dB
sumNoiseDb :: Float -> Float -> Float
sumNoiseDb noiseDb1 noiseDb2 =
  let p1 = dbToLinear noiseDb1
      p2 = dbToLinear noiseDb2
  in linearToDb (p1 + p2)

-- Combine signal to noise ratios (Harmonic sum: 1/SNR_total = 1/SNR_1 + 1/SNR_2)
combineSnrDb :: Float -> Float -> Float
combineSnrDb snrDb1 snrDb2 =
  let snrLin1 = dbToLinear snrDb1
      snrLin2 = dbToLinear snrDb2
      invTotal = (1.0 / snrLin1) + (1.0 / snrLin2)
  in linearToDb (1.0 / invTotal)
