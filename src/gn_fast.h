/*
 * File: gn_fast.h
 * High-performance C acceleration header for analytical Gaussian Noise (GN) calculations.
 */

#ifndef FERRULE_GN_FAST_H
#define FERRULE_GN_FAST_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Evaluates single-span nonlinear interference power spectral density G_NLI (Watts / Hz).
 * Parameters:
 *   length_km             - Span physical length in km
 *   attenuation_db_per_km - Attenuation in dB/km (typically 0.20 for SMF-28)
 *   dispersion_ps_nm_km   - Chromatic dispersion parameter in ps/(nm*km)
 *   nonlinear_1_w_km      - Nonlinear parameter gamma in 1/(W*km)
 *   launch_power_watts    - Total channel optical launch power in Watts
 *   channel_bw_ghz        - Optical channel bandwidth in GHz
 *   center_wavelength_nm  - Carrier center wavelength in nm (default 1550.0)
 */
double ferrule_gn_nli_psd(
    double length_km,
    double attenuation_db_per_km,
    double dispersion_ps_nm_km,
    double nonlinear_1_w_km,
    double launch_power_watts,
    double channel_bw_ghz,
    double center_wavelength_nm
);

/*
 * Evaluates cascaded OSNR in dB across num_spans identical amplified spans.
 */
double ferrule_cascaded_osnr_db(
    double launch_power_dbm,
    double span_length_km,
    int num_spans,
    double noise_figure_db,
    double attenuation_db_per_km
);

#ifdef __cplusplus
}
#endif

#endif /* FERRULE_GN_FAST_H */
