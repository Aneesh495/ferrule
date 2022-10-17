"""Unit tests for optical topology datasets and graph invariants.
"""

import unittest
import json
import os

class TestTopologies(unittest.TestCase):
    def setUp(self):
        self.base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    def test_nsfnet_structure(self):
        path = os.path.join(self.base_dir, "data", "nsfnet.json")
        with open(path, "r") as f:
            data = json.load(f)
        
        self.assertEqual(data["name"], "NSFNET-14")
        self.assertEqual(len(data["nodes"]), 14)
        self.assertEqual(len(data["links"]), 21)

        # Verify all link endpoints exist in node set
        node_ids = {n["id"] for n in data["nodes"]}
        for l in data["links"]:
            self.assertIn(l["src"], node_ids)
            self.assertIn(l["tgt"], node_ids)
            self.assertGreater(l["length_km"], 0.0)

    def test_cost239_structure(self):
        path = os.path.join(self.base_dir, "data", "cost239.json")
        with open(path, "r") as f:
            data = json.load(f)
        
        self.assertEqual(data["name"], "COST-239")
        self.assertEqual(len(data["nodes"]), 11)
        self.assertEqual(len(data["links"]), 18)

        node_ids = {n["id"] for n in data["nodes"]}
        for l in data["links"]:
            self.assertIn(l["src"], node_ids)
            self.assertIn(l["tgt"], node_ids)

if __name__ == "__main__":
    unittest.main()
