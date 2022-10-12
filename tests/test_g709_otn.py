"""Unit tests for ITU-T G.709 OTN framing, ODUk hierarchy, and GMP mapping.
"""

import unittest

class TestG709Otn(unittest.TestCase):
    def test_frame_geometry(self):
        # 4 rows by 4080 columns = 16,320 bytes total
        rows = 4
        cols = 4080
        total_bytes = rows * cols
        self.assertEqual(total_bytes, 16320)

    def test_fas_pattern_verification(self):
        standard_fas = [0xF6, 0xF6, 0xF6, 0x28, 0x28, 0x28]
        incoming_valid = [0xF6, 0xF6, 0xF6, 0x28, 0x28, 0x28, 0x00, 0x01]
        incoming_invalid = [0xF6, 0xF6, 0x00, 0x28, 0x28, 0x28, 0x00, 0x01]
        
        self.assertEqual(incoming_valid[:6], standard_fas)
        self.assertNotEqual(incoming_invalid[:6], standard_fas)

    def test_gmp_sigma_delta_distribution(self):
        # Capacity B = 10 positions, Count Cm = 7 entities
        # Should generate exactly 7 True and 3 False positions
        capacity_b = 10
        count_cm = 7
        positions = []
        acc = 0
        for _ in range(capacity_b):
            acc += count_cm
            is_payload = acc >= capacity_b
            if is_payload:
                acc -= capacity_b
            positions.append(is_payload)

        self.assertEqual(sum(positions), count_cm)
        self.assertEqual(len(positions) - sum(positions), 3)  # 3 stuff bytes

    def test_tributary_slot_capacity(self):
        # ODU1 = 2 TS, ODU2 = 8 TS, ODU3 = 32 TS, ODU4 = 80 TS
        caps = {'ODU1': 2, 'ODU2': 8, 'ODU3': 32, 'ODU4': 80}
        self.assertEqual(caps['ODU4'], 80)
        self.assertEqual(caps['ODU2'], 8)

if __name__ == "__main__":
    unittest.main()
