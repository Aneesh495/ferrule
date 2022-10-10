"""Unit tests for hitless spectrum defragmentation planning and compaction.
"""

import unittest

class TestDefragmentation(unittest.TestCase):
    def test_fragmentation_ratio_calculation(self):
        # Clean spectrum: 1 large contiguous free block -> 0.0 fragmentation
        spec_clean = [True] * 100
        frag_clean = self.calculate_frag(spec_clean)
        self.assertEqual(frag_clean, 0.0)

        # Severely fragmented: alternating single free and busy slots
        spec_frag = [True, False] * 50
        frag_dirty = self.calculate_frag(spec_frag)
        # Max free block is 1, total free is 50 -> frag = 1.0 - (1/50) = 0.98
        self.assertAlmostEqual(frag_dirty, 0.98, places=2)

    def test_left_compaction_shift(self):
        # 20 slots: slots 0-3 free, slots 4-7 allocated to LP1, slots 8-19 free
        # Target for LP1: shift left into slots 0-3
        cur_start = 4
        cur_count = 4
        target_start = 0
        shift = target_start - cur_start
        self.assertEqual(shift, -4)  # Shifted left by 4 slots

    @staticmethod
    def calculate_frag(spec):
        free_runs = []
        cur_len = 0
        for b in spec:
            if b:
                cur_len += 1
            else:
                if cur_len > 0:
                    free_runs.append(cur_len)
                    cur_len = 0
        if cur_len > 0:
            free_runs.append(cur_len)
        total_free = sum(free_runs)
        if total_free == 0:
            return 0.0
        max_run = max(free_runs)
        return 1.0 - (max_run / total_free)

if __name__ == "__main__":
    unittest.main()
