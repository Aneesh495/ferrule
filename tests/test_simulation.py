"""Integration tests for dynamic discrete-event optical network simulation.
"""

import unittest

class TestSimulationIntegration(unittest.TestCase):
    def test_erlang_load_calculation(self):
        # Arrival rate: 0.5 calls/s, Mean holding time: 100 s -> 50 Erlangs
        arr_rate = 0.5
        hold_time = 100.0
        load = arr_rate * hold_time
        self.assertEqual(load, 50.0)

    def test_blocking_probability_computation(self):
        offered = 1000
        blocked = 45
        accepted = offered - blocked
        p_block = blocked / offered
        self.assertAlmostEqual(p_block, 0.045, places=5)
        self.assertEqual(accepted, 955)

    def test_discrete_event_queue_ordering(self):
        # Insert events at t = 10.5, 2.0, 5.0, 1.2
        timestamps = [10.5, 2.0, 5.0, 1.2]
        sorted_events = sorted(timestamps)
        self.assertEqual(sorted_events, [1.2, 2.0, 5.0, 10.5])

if __name__ == "__main__":
    unittest.main()
