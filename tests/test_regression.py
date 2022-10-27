"""Regression test suite documenting and preventing recurring corner cases.
"""

import unittest
from engine.solver import LogicVariable, ConstraintSolver, Substitution
from engine.bridge import OpticalPhysicsBridge

class TestRegression(unittest.TestCase):
    def test_occurs_check_prevents_cyclic_terms(self):
        # Prevent infinite loops during logic unification: X =:= [X]
        var_x = LogicVariable("X")
        cyclic_term = [var_x]
        subst = ConstraintSolver.unify(var_x, cyclic_term)
        self.assertIsNone(subst, "Occurs check must reject cyclic term unification X =:= [X]")

    def test_zero_span_count_safe_fallback(self):
        # Zero spans must not cause ZeroDivisionError
        osnr = OpticalPhysicsBridge.cascaded_osnr_db(0.0, 80.0, 0)
        self.assertGreater(osnr, 0.0)

    def test_zero_power_safe_log(self):
        # 0 linear ratio must not cause math domain error in log10
        db = OpticalPhysicsBridge.linear_to_db(0.0)
        self.assertEqual(db, -300.0)

    def test_empty_candidate_path_handling(self):
        # Resolving RMSA with no physical connectivity must safely return None
        from engine.bridge import ModulationBridge
        mod = ModulationBridge.select_best_modulation(10000.0, 5.0)
        self.assertIsNone(mod, "Modulation selection must return None for unfeasible distance/GSNR")

if __name__ == "__main__":
    unittest.main()
