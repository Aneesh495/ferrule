"""Verification tests for the Curry lexer, parser, type checker, and narrowing engine.
"""

import unittest
from engine.lexer import Lexer
from engine.parser import Parser
from engine.typecheck import TypeChecker
from engine.machine import AbstractMachine
from engine.solver import LogicVariable, ConstraintSolver

class TestCurryRuntime(unittest.TestCase):
    def test_lexer_tokenization(self):
        code = "module Test where\ndata Color = Red | Green | Blue\nx = 42"
        tokens = Lexer(code).tokenize()
        token_types = [t.type for t in tokens if t.type not in ('EOF',)]
        self.assertIn("KEYWORD", token_types)
        self.assertIn("PIPE", token_types)
        self.assertIn("NUMBER", token_types)

    def test_parser_data_declaration(self):
        code = "module Test where\ndata TrafficLight = Stop | Caution | Go"
        tokens = Lexer(code).tokenize()
        mod = Parser(tokens).parse_module()
        self.assertEqual(mod.name, "Test")
        self.assertEqual(len(mod.decls), 1)
        decl = mod.decls[0]
        self.assertEqual(decl.name, "TrafficLight")
        self.assertEqual(len(decl.constructors), 3)

    def test_typechecker_validation(self):
        code = "module Test where\ndata Status = Ok | Error"
        tokens = Lexer(code).tokenize()
        mod = Parser(tokens).parse_module()
        checker = TypeChecker()
        self.assertTrue(checker.check_module(mod))

    def test_abstract_machine_choice_evaluation(self):
        # Non-deterministic choice: (?) 1 2
        machine = AbstractMachine()
        results = machine.evaluate_all(lambda: machine.non_deterministic_choice(1, 2, 3))
        self.assertEqual(sorted(results), [1, 2, 3])

    def test_equational_unification(self):
        var_x = LogicVariable("x")
        subst = ConstraintSolver.unify(var_x, 42)
        self.assertIsNotNone(subst)
        self.assertEqual(subst.apply(var_x), 42)

if __name__ == "__main__":
    unittest.main()
