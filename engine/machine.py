"""Needed-narrowing abstract machine for Curry evaluation.
Executes non-deterministic choices, equational narrowing, and encapsulated search.
"""

from typing import Any, List, Optional, Callable, Generator
from .solver import LogicVariable, Substitution, ConstraintSolver

class ChoiceBranch:
    """Represents a non-deterministic branch in the Curry search space."""
    def __init__(self, alternatives: List[Callable[[], Any]]):
        self.alternatives = alternatives

class AbstractMachine:
    def __init__(self):
        self.max_depth = 1000

    def evaluate_first(self, compute_fn: Callable[[], Any]) -> Optional[Any]:
        """Find first solution using depth-first search."""
        for sol in self.evaluate_all(compute_fn):
            return sol
        return None

    def evaluate_all(self, compute_fn: Callable[[], Any]) -> List[Any]:
        """Collect all successful solutions using encapsulated search (allValues)."""
        results = []
        stack = [(compute_fn, Substitution(), 0)]

        while stack:
            fn, subst, depth = stack.pop()
            if depth > self.max_depth:
                continue

            try:
                val = fn()
                if isinstance(val, ChoiceBranch):
                    for alt in reversed(val.alternatives):
                        stack.append((alt, subst, depth + 1))
                else:
                    results.append(subst.apply(val))
            except Exception:
                # Failure in this search branch; backtrack
                continue

        return results

    def non_deterministic_choice(self, *options: Any) -> ChoiceBranch:
        """Implements Curry's (?) non-deterministic choice operator."""
        return ChoiceBranch([lambda opt=o: opt for o in options])

    def equate(self, left: Any, right: Any, subst: Optional[Substitution] = None) -> bool:
        """Implements Curry's (=:=) equational constraint."""
        s = ConstraintSolver.unify(left, right, subst)
        return s is not None
