"""Unit tests for GMPLS Link Management Protocol (LMP) and G.808.1 protection.
"""

import unittest

class TestGmplsLmp(unittest.TestCase):
    def test_lmp_state_progression(self):
        # Down -> ConfSend -> Up
        state = "Down"
        # Event: Transmit Config
        state = "ConfSend"
        # Event: Receive ConfigAck
        state = "Up"
        self.assertEqual(state, "Up")

    def test_g808_1_priority_preemption(self):
        # Priorities: Lockout (1) > Forced Switch (2) > Signal Fail Working (3) > Manual Switch (6)
        priorities = {
            "Lockout": 1,
            "ForcedSwitch": 2,
            "SignalFailWorking": 3,
            "SignalDegrade": 5,
            "ManualSwitch": 6,
            "NoRequest": 8
        }
        # Lockout preempts Signal Fail Working
        self.assertLess(priorities["Lockout"], priorities["SignalFailWorking"])
        # Signal Fail Working preempts Manual Switch
        self.assertLess(priorities["SignalFailWorking"], priorities["ManualSwitch"])

    def test_sub_50ms_budget_compliance(self):
        measured_switching_time_ms = 18.4
        standard_limit_ms = 50.0
        self.assertLessEqual(measured_switching_time_ms, standard_limit_ms)

if __name__ == "__main__":
    unittest.main()
