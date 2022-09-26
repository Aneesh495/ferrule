"""Unit tests for optical physical layer calculations and GN model.
"""

import unittest
from engine.bridge import OpticalPhysicsBridge

class TestOpticalPhysics(unittest.TestCase):
    def test_effective_length(self):
        # For an 80 km span with 0.20 dB/km loss:
        # alpha = (0.2 / 10) * ln(10) = 0.04605 1/km
        # L_eff = (1 - exp(-0.04605 * 80)) / 0.04605 ~ 21.17 km
        leff = OpticalPhysicsBridge.span_effective_length_km(80.0, 0.20)
        self.assertGreater(leff, 20.0)
        self.assertLess(leff, 22.0)

    def test_cascaded_osnr_scaling(self):
        # 1 span vs 10 spans should show ~10 dB degradation in OSNR
        osnr_1 = OpticalPhysicsBridge.cascaded_osnr_db(0.0, 80.0, 1)
        osnr_10 = OpticalPhysicsBridge.cascaded_osnr_db(0.0, 80.0, 10)
        diff = osnr_1 - osnr_10
        self.assertAlmostEqual(diff, 10.0, delta=0.1)

    def test_gn_model_non_negative_power(self):
        launch_w = OpticalPhysicsBridge.dbm_to_watts(0.0)
        p_nli = OpticalPhysicsBridge.gn_model_nli_power_watts(80.0, 0.20, 16.7, 1.3, launch_w, 50.0)
        self.assertGreater(p_nli, 0.0)
        self.assertLess(p_nli, launch_w)

    def test_gsnr_evaluation(self):
        # 1000 km path across 12 spans
        gsnr = OpticalPhysicsBridge.evaluate_gsnr_db(1000.0, 12, 4, 0.0)
        self.assertGreater(gsnr, 15.0)
        self.assertLess(gsnr, 30.0)

if __name__ == "__main__":
    unittest.main()
