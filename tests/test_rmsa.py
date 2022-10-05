"""Unit tests for RMSA routing, spectrum continuity, and non-overlapping constraints.
"""

import unittest

class TestRmsaConstraints(unittest.TestCase):
    def test_non_overlapping_windows(self):
        # Window 1: slots 0-7, Window 2: slots 8-15 -> Non-overlapping
        w1 = (0, 8)
        w2 = (8, 8)
        self.assertTrue(self.is_disjoint(w1, w2))

        # Overlapping windows
        w3 = (4, 8)  # 4 to 11 overlaps with 0-7 and 8-15
        self.assertFalse(self.is_disjoint(w1, w3))
        self.assertFalse(self.is_disjoint(w2, w3))

    def test_spectrum_intersection(self):
        # 10 slots on Link A, 10 slots on Link B
        link_a = [True, True, True, False, False, True, True, True, True, True]
        link_b = [False, True, True, True, True, True, True, False, False, True]
        
        # Intersection: True only where BOTH are True
        common = [a and b for a, b in zip(link_a, link_b)]
        expected = [False, True, True, False, False, True, True, False, False, True]
        self.assertEqual(common, expected)

    def test_contiguous_window_search(self):
        spec = [False, True, True, True, False, True, True, False]
        # Search for block of 3 slots
        windows = self.find_free_blocks(spec, 3)
        self.assertEqual(windows, [(1, 3)])

    @staticmethod
    def is_disjoint(w1, w2):
        s1, c1 = w1
        s2, c2 = w2
        return (s1 + c1 <= s2) or (s2 + c2 <= s1)

    @staticmethod
    def find_free_blocks(spec, needed):
        blocks = []
        cur_start = -1
        cur_len = 0
        for i, free in enumerate(spec):
            if free:
                if cur_len == 0:
                    cur_start = i
                cur_len += 1
                if cur_len >= needed:
                    blocks.append((cur_start, needed))
                    cur_len = 0
            else:
                cur_len = 0
        return blocks

if __name__ == "__main__":
    unittest.main()
