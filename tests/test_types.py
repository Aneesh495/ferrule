"""Unit tests for optical units, domain models, and decibel conversions.
"""

import unittest
import math
from engine.bridge import OpticalPhysicsBridge

class TestOpticalTypes(unittest.TestCase):
    def test_db_linear_conversion(self):
        self.assertAlmostEqual(OpticalPhysicsBridge.db_to_linear(0.0), 1.0, places=5)
        self.assertAlmostEqual(OpticalPhysicsBridge.db_to_linear(10.0), 10.0, places=5)
        self.assertAlmostEqual(OpticalPhysicsBridge.db_to_linear(20.0), 100.0, places=5)
        self.assertAlmostEqual(OpticalPhysicsBridge.db_to_linear(30.0), 1000.0, places=5)

    def test_linear_to_db_conversion(self):
        self.assertAlmostEqual(OpticalPhysicsBridge.linear_to_db(1.0), 0.0, places=5)
        self.assertAlmostEqual(OpticalPhysicsBridge.linear_to_db(10.0), 10.0, places=5)
        self.assertAlmostEqual(OpticalPhysicsBridge.linear_to_db(100.0), 20.0, places=5)

    def test_dbm_watts_conversion(self):
        # 0 dBm = 1 mW = 1e-3 W
        self.assertAlmostEqual(OpticalPhysicsBridge.dbm_to_watts(0.0), 1e-3, places=6)
        # +30 dBm = 1000 mW = 1 W
        self.assertAlmostEqual(OpticalPhysicsBridge.dbm_to_watts(30.0), 1.0, places=5)
        # -30 dBm = 0.001 mW = 1e-6 W
        self.assertAlmostEqual(OpticalPhysicsBridge.dbm_to_watts(-30.0), 1e-6, places=9)

    def test_frequency_wavelength_roundtrip(self):
        f_thz = 193.41449
        wl_nm = OpticalPhysicsBridge.thz_to_wavelength_nm(f_thz)
        self.assertAlmostEqual(wl_nm, 1550.0, delta=0.5)
        f_recovered = OpticalPhysicsBridge.wavelength_nm_to_thz(wl_nm)
        self.assertAlmostEqual(f_recovered, f_thz, places=3)

if __name__ == "__main__":
    unittest.main()
