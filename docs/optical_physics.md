# Optical Physical Layer and Analytical Impairment Modeling

In high-capacity coherent optical transmission systems, signal degradation accumulates along concatenated fiber spans through linear and nonlinear physical effects.

## 1. Linear Impairments

### Fiber Attenuation and Effective Length
Optical signal power attenuates exponentially according to the Beer-Lambert law:

```
P(z) = P(0) * exp(-alpha * z)
```

where `alpha` is the linear attenuation coefficient derived from attenuation in dB/km:

```
alpha = (alpha_db / 10.0) * ln(10)
```

Due to exponential power decay, nonlinear Kerr interactions are confined primarily to the beginning of each fiber span. The effective nonlinear interaction length is given by:

```
L_eff = (1 - exp(-alpha * L)) / alpha
```

For an 80 km SMF-28 span with 0.20 dB/km loss, `L_eff` approaches approximately 21.17 km.

### Amplified Spontaneous Emission (ASE) Noise
Optical amplifiers (EDFAs) compensate for span transmission loss but introduce ASE noise across both optical polarizations:

```
S_ase = 2 * h * nu * n_sp * (G - 1)
```

where:
- `h` is Planck's constant (6.626e-34 J*s)
- `nu` is optical carrier frequency (~193.414 THz)
- `n_sp` is spontaneous emission factor: `n_sp = 0.5 * 10^(NF_dB / 10) * (G / (G - 1))`
- `G` is amplifier linear gain matching span loss

For a cascade of `N` identical spans, the accumulated optical signal-to-noise ratio in decibels scales as:

```
OSNR_total_dB = OSNR_single_span_dB - 10 * log10(N)
```

## 2. Nonlinear Interference: The Analytical Gaussian Noise (GN) Model

Coherent optical transmission over dispersion-uncompensated single-mode fiber behaves as an additive Gaussian noise channel. Non-linear Kerr interactions (Self-Phase Modulation and Cross-Phase Modulation) can be modeled analytically via the GN model:

```
eta = (8 / 27) * (gamma^2 / (pi * alpha * |beta2| * B_ch^2)) * asinh((pi^2 / 2) * (|beta2| / alpha) * B_ch^2)
```

The resulting nonlinear interference noise power generated per span is:

```
P_nli = eta * (P_launch)^3
```

Accumulation over `N` spans incorporates slight coherent inter-span phase addition:

```
P_nli_total = N^(1 + epsilon) * P_nli
```

where `epsilon` is typically 0.05 for standard single-mode fiber.

## 3. Generalized Signal-to-Noise Ratio (GSNR)

The total transmission quality combines linear ASE noise, nonlinear NLI noise, and ROADM filter passband narrowing penalties:

```
GSNR^-1 = OSNR_ase^-1 + SNR_nli^-1
GSNR_effective_dB = GSNR_raw_dB - (num_roadms * 0.15 dB)
```
