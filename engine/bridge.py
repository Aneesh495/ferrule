"""High-performance execution bridge for Ferrule.
Exposes Curry domain logic, physical simulation, and RMSA optimization
directly to CLI tools, visualization components, and unit test suites.
"""

import math
from typing import List, Dict, Optional, Tuple, Any

SPEED_OF_LIGHT_MPS = 299792458.0
PLANCK_CONSTANT_JS = 6.62607015e-34
CBAND_SLOTS = 384
SLOT_WIDTH_GHZ = 12.5

class OpticalPhysicsBridge:
    @staticmethod
    def db_to_linear(db: float) -> float:
        return 10.0 ** (db / 10.0)

    @staticmethod
    def linear_to_db(linear: float) -> float:
        return 10.0 * math.log10(max(linear, 1e-30))

    @staticmethod
    def dbm_to_watts(dbm: float) -> float:
        return (10.0 ** (dbm / 10.0)) / 1000.0

    @staticmethod
    def watts_to_dbm(watts: float) -> float:
        return 10.0 * math.log10(max(watts * 1000.0, 1e-30))

    @staticmethod
    def thz_to_wavelength_nm(thz: float) -> float:
        return (SPEED_OF_LIGHT_MPS / (thz * 1e12)) * 1e9

    @staticmethod
    def wavelength_nm_to_thz(wavelength_nm: float) -> float:
        return (SPEED_OF_LIGHT_MPS / (wavelength_nm * 1e-9)) * 1e-12

    @staticmethod
    def span_effective_length_km(length_km: float, attenuation_db_per_km: float) -> float:
        alpha = (attenuation_db_per_km / 10.0) * math.log(10.0)
        return (1.0 - math.exp(-alpha * length_km)) / alpha

    @staticmethod
    def gn_model_nli_power_watts(
        length_km: float,
        attenuation_db_per_km: float,
        dispersion_ps_nm_km: float,
        nonlinear_1_w_km: float,
        launch_power_watts: float,
        channel_bw_ghz: float,
        wavelength_nm: float = 1550.0
    ) -> float:
        """Evaluates single-span nonlinear interference power P_NLI (Watts) via analytical GN model."""
        gamma = nonlinear_1_w_km * 1e-3                         # 1 / (W * m)
        alpha = (attenuation_db_per_km / 10.0) * math.log(10.0) * 1e-3  # 1 / m
        c_mps = SPEED_OF_LIGHT_MPS
        lambda_m = wavelength_nm * 1e-9
        disp_m = dispersion_ps_nm_km * 1e-6                     # s / m^2
        beta2_m = abs(((lambda_m * lambda_m) / (2.0 * math.pi * c_mps)) * disp_m)  # s^2 / m

        bw_hz = channel_bw_ghz * 1e9
        arg = (math.pi * math.pi / 2.0) * (beta2_m / alpha) * (bw_hz * bw_hz)
        asinh_term = math.asinh(max(arg, 1e-12))

        denom = math.pi * alpha * beta2_m * (bw_hz * bw_hz)
        if denom <= 0:
            return 0.0

        eta = (8.0 / 27.0) * (gamma * gamma / denom) * asinh_term
        return eta * (launch_power_watts ** 3)

    @staticmethod
    def cascaded_osnr_db(
        launch_power_dbm: float,
        span_length_km: float,
        num_spans: int,
        noise_figure_db: float = 5.5,
        attenuation_db_per_km: float = 0.20
    ) -> float:
        span_loss_db = span_length_km * attenuation_db_per_km
        sig_watts = OpticalPhysicsBridge.dbm_to_watts(launch_power_dbm)
        g_lin = OpticalPhysicsBridge.db_to_linear(span_loss_db)
        nf_lin = OpticalPhysicsBridge.db_to_linear(noise_figure_db)
        nsp = 0.5 * nf_lin * (g_lin / max(g_lin - 1.0, 1e-6))
        h_nu = PLANCK_CONSTANT_JS * 193.41449e12
        ref_bw_hz = 12.5e9
        single_ase_watts = 2.0 * (h_nu * nsp * (g_lin - 1.0)) * ref_bw_hz
        single_osnr_lin = sig_watts / max(single_ase_watts, 1e-30)
        total_osnr_lin = single_osnr_lin / max(num_spans, 1)
        return OpticalPhysicsBridge.linear_to_db(total_osnr_lin)

    @staticmethod
    def evaluate_gsnr_db(
        path_length_km: float,
        num_spans: int,
        num_roadms: int,
        launch_power_dbm: float = 0.0
    ) -> float:
        avg_span_len = path_length_km / max(num_spans, 1)
        osnr_ase = OpticalPhysicsBridge.cascaded_osnr_db(launch_power_dbm, avg_span_len, num_spans)
        
        launch_watts = OpticalPhysicsBridge.dbm_to_watts(launch_power_dbm)
        single_nli_watts = OpticalPhysicsBridge.gn_model_nli_power_watts(
            avg_span_len, 0.20, 16.7, 1.3, launch_watts, 50.0
        )
        total_nli_watts = (num_spans ** 1.05) * single_nli_watts
        snr_nli = OpticalPhysicsBridge.linear_to_db(launch_watts / max(total_nli_watts, 1e-30))

        inv_gsnr = (1.0 / OpticalPhysicsBridge.db_to_linear(osnr_ase)) + (1.0 / OpticalPhysicsBridge.db_to_linear(snr_nli))
        raw_gsnr = OpticalPhysicsBridge.linear_to_db(1.0 / max(inv_gsnr, 1e-30))
        roadm_penalty = num_roadms * 0.15
        return max(raw_gsnr - roadm_penalty, 0.0)

class ModulationBridge:
    FORMATS = {
        'DP-BPSK':  {'bits': 2,  'min_gsnr': 7.0,  'max_reach': 5000.0, 'rate': 100.0},
        'DP-QPSK':  {'bits': 4,  'min_gsnr': 10.5, 'max_reach': 3000.0, 'rate': 200.0},
        'DP-8QAM':  {'bits': 6,  'min_gsnr': 14.5, 'max_reach': 1800.0, 'rate': 300.0},
        'DP-16QAM': {'bits': 8,  'min_gsnr': 17.0, 'max_reach': 1000.0, 'rate': 400.0},
        'DP-32QAM': {'bits': 10, 'min_gsnr': 20.5, 'max_reach': 500.0,  'rate': 600.0},
        'DP-64QAM': {'bits': 12, 'min_gsnr': 24.0, 'max_reach': 200.0,  'rate': 800.0},
    }

    @staticmethod
    def select_best_modulation(path_km: float, gsnr_db: float) -> Optional[str]:
        for scheme in ['DP-64QAM', 'DP-32QAM', 'DP-16QAM', 'DP-8QAM', 'DP-QPSK', 'DP-BPSK']:
            attrs = ModulationBridge.FORMATS[scheme]
            if path_km <= attrs['max_reach'] and gsnr_db >= attrs['min_gsnr']:
                return scheme
        return None

    @staticmethod
    def required_slots(bitrate_gbps: float, mod_scheme: str) -> int:
        bits_per_sym = ModulationBridge.FORMATS[mod_scheme]['bits']
        symbol_rate = bitrate_gbps / bits_per_sym
        required_bw_ghz = symbol_rate * 1.15 + 5.0
        return max(2, math.ceil(required_bw_ghz / SLOT_WIDTH_GHZ))
