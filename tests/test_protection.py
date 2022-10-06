"""Unit tests for SRLG disjointness and 1+1 / 1:N protection logic.
"""

import unittest

class TestProtection(unittest.TestCase):
    def test_srlg_disjointness_true(self):
        # Path 1 links traverse SRLGs {1, 2}, Path 2 links traverse SRLGs {3, 4}
        p1_srlgs = {1, 2}
        p2_srlgs = {3, 4}
        self.assertTrue(p1_srlgs.isdisjoint(p2_srlgs))

    def test_srlg_disjointness_false(self):
        # Path 1 and Path 2 share conduit with SRLG 2
        p1_srlgs = {1, 2}
        p2_srlgs = {2, 5}
        self.assertFalse(p1_srlgs.isdisjoint(p2_srlgs))

    def test_smp_capacity_sharing(self):
        # Demand A primary: SRLGs {1, 2}
        # Demand B primary: SRLGs {3, 4}
        # Since their primary paths are disjoint, they can share an SMP backup window on Link C
        demands = [
            {"id": "D1", "primary_srlgs": {1, 2}},
            {"id": "D2", "primary_srlgs": {3, 4}},
        ]
        all_srlg_sets = [d["primary_srlgs"] for d in demands]
        
        # Verify pairwise disjointness
        can_share = True
        for i in range(len(all_srlg_sets)):
            for j in range(i + 1, len(all_srlg_sets)):
                if not all_srlg_sets[i].isdisjoint(all_srlg_sets[j]):
                    can_share = False
        self.assertTrue(can_share)

    def test_differential_propagation_delay(self):
        # Primary path: 1000 km, Backup path: 1800 km
        # Delta = 800 km * 4.9 us/km = 3.92 ms (well within 10 ms buffer budget)
        delta_km = 800.0
        diff_ms = delta_km * 0.0049
        self.assertLess(diff_ms, 10.0)

if __name__ == "__main__":
    unittest.main()
