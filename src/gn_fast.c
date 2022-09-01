/*
 * File: gn_fast.c
 * High-performance C99 implementation of analytical Gaussian Noise (GN) calculations.
 */

#include "gn_fast.h"
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define C_LIGHT_MPS 299792458.0
#define PLANCK_H_JS 6.62607015e-34

double ferrule_gn_nli_psd(
    double length_km,
    double attenuation_db_per_km,
    double dispersion_ps_nm_km,
    double nonlinear_1_w_km,
    double launch_power_watts,
    double channel_bw_ghz,
    double center_wavelength_nm
) {
    double gamma = nonlinear_1_w_km * 1.0e-3;
    double alpha = (attenuation_db_per_km / 10.0) * log(10.0) * 1.0e-3;
    double lambda_m = center_wavelength_nm * 1.0e-9;
    double disp_m = dispersion_ps_nm_km * 1.0e-6;
    double beta2_m = fabs(((lambda_m * lambda_m) / (2.0 * M_PI * C_LIGHT_MPS)) * disp_m);

    double bw_hz = channel_bw_ghz * 1.0e9;
    double psd_tx = launch_power_watts / bw_hz;

    double alpha_km = (attenuation_db_per_km / 10.0) * log(10.0);
    double leff_km = (1.0 - exp(-alpha_km * length_km)) / alpha_km;
    double leff_m = leff_km * 1000.0;

    double prefactor = (8.0 / 27.0) * (gamma * gamma) * (psd_tx * psd_tx * psd_tx) * (leff_m * leff_m);
    double denom = 2.0 * M_PI * alpha * beta2_m;

    if (denom <= 0.0) {
        return 0.0;
    }

    double arg = (M_PI * M_PI / 2.0) * (beta2_m / alpha) * (bw_hz * bw_hz);
    double asinh_term = asinh(arg);

    return (prefactor / denom) * asinh_term;
}

double ferrule_cascaded_osnr_db(
    double launch_power_dbm,
    double span_length_km,
    int num_spans,
    double noise_figure_db,
    double attenuation_db_per_km
) {
    if (num_spans <= 0) {
        num_spans = 1;
    }

    double span_loss_db = span_length_km * attenuation_db_per_km;
    double sig_watts = (pow(10.0, launch_power_dbm / 10.0)) / 1000.0;
    double g_lin = pow(10.0, span_loss_db / 10.0);
    double nf_lin = pow(10.0, noise_figure_db / 10.0);

    double nsp = 0.5 * nf_lin * (g_lin / fmax(g_lin - 1.0, 1e-6));
    double h_nu = PLANCK_H_JS * 193.41449e12;
    double ref_bw_hz = 12.5e9;

    double single_ase_watts = 2.0 * (h_nu * nsp * (g_lin - 1.0)) * ref_bw_hz;
    double single_osnr_lin = sig_watts / fmax(single_ase_watts, 1e-30);
    double total_osnr_lin = single_osnr_lin / (double)num_spans;

    return 10.0 * log10(fmax(total_osnr_lin, 1e-30));
}
