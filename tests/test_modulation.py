"""Unit tests for coherent modulation schemes and spectral slot calculation.
"""

import unittest
from engine.bridge import ModulationBridge

class TestModulation(unittest.TestCase):
    def test_spectral_efficiency_ordering(self):
        formats = ['DP-BPSK', 'DP-QPSK', 'DP-8QAM', 'DP-16QAM', 'DP-32QAM', 'DP-64QAM']
        bits = [ModulationBridge.FORMATS[f]['bits'] for f in formats]
        self.assertEqual(bits, sorted(bits))
        self.assertEqual(len(bits), len(set(bits)))  # Strictly increasing

    def test_required_gsnr_ordering(self):
        formats = ['DP-BPSK', 'DP-QPSK', 'DP-8QAM', 'DP-16QAM', 'DP-32QAM', 'DP-64QAM']
        gsnrs = [ModulationBridge.FORMATS[f]['min_gsnr'] for f in formats]
        self.assertEqual(gsnrs, sorted(gsnrs))

    def test_modulation_selection_short_reach(self):
        # 100 km path with high SNR (25 dB) should support DP-64QAM
        mod = ModulationBridge.select_best_modulation(100.0, 25.0)
        self.assertEqual(mod, 'DP-64QAM')

    def test_modulation_selection_long_reach(self):
        # 4000 km path should fall back to DP-BPSK
        mod = ModulationBridge.select_best_modulation(4000.0, 9.0)
        self.assertEqual(mod, 'DP-BPSK')

    def test_required_slots_scaling(self):
        # 400G on DP-16QAM (8 bits/sym) should require fewer slots than on DP-QPSK (4 bits/sym)
        slots_16qam = ModulationBridge.required_slots(400.0, 'DP-16QAM')
        slots_qpsk = ModulationBridge.required_slots(400.0, 'DP-QPSK')
        self.assertLess(slots_16qam, slots_qpsk)

if __name__ == "__main__":
    unittest.main()
