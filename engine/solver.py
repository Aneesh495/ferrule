"""Constraint logic unification engine for Curry programs.
Solves equational constraints (=:=), free logical variables, and finite domains.
"""

from typing import Dict, Any, Optional, Set, List

class LogicVariable:
    _counter = 0

    def __init__(self, name: Optional[str] = None):
        LogicVariable._counter += 1
        self.id = LogicVariable._counter
        self.name = name or f"_v{self.id}"

    def __repr__(self):
        return f"${self.name}"

    def __eq__(self, other):
        return isinstance(other, LogicVariable) and self.id == other.id

    def __hash__(self):
        return hash(self.id)

class Substitution:
    def __init__(self, mapping: Optional[Dict[LogicVariable, Any]] = None):
        self.mapping: Dict[LogicVariable, Any] = mapping or {}

    def apply(self, term: Any) -> Any:
        if isinstance(term, LogicVariable):
            if term in self.mapping:
                return self.apply(self.mapping[term])
            return term
        elif isinstance(term, list):
            return [self.apply(item) for item in term]
        elif isinstance(term, tuple):
            return tuple(self.apply(item) for item in term)
        elif isinstance(term, dict):
            return {k: self.apply(v) for k, v in term.items()}
        return term

    def extend(self, var: LogicVariable, val: Any) -> 'Substitution':
        new_map = dict(self.mapping)
        new_map[var] = val
        return Substitution(new_map)

class ConstraintSolver:
    @staticmethod
    def occurs_check(var: LogicVariable, term: Any, subst: Substitution) -> bool:
        term = subst.apply(term)
        if var == term:
            return True
        elif isinstance(term, (list, tuple)):
            return any(ConstraintSolver.occurs_check(var, item, subst) for item in term)
        elif isinstance(term, dict):
            return any(ConstraintSolver.occurs_check(var, item, subst) for item in term.values())
        return False

    @staticmethod
    def unify(term1: Any, term2: Any, subst: Optional[Substitution] = None) -> Optional[Substitution]:
        subst = subst or Substitution()
        t1 = subst.apply(term1)
        t2 = subst.apply(term2)

        if t1 == t2:
            return subst
        elif isinstance(t1, LogicVariable):
            if ConstraintSolver.occurs_check(t1, t2, subst):
                return None  # Occurs check failure
            return subst.extend(t1, t2)
        elif isinstance(t2, LogicVariable):
            if ConstraintSolver.occurs_check(t2, t1, subst):
                return None
            return subst.extend(t2, t1)
        elif isinstance(t1, (list, tuple)) and isinstance(t2, (list, tuple)):
            if len(t1) != len(t2):
                return None
            cur_subst = subst
            for x, y in zip(t1, t2):
                cur_subst = ConstraintSolver.unify(x, y, cur_subst)
                if cur_subst is None:
                    return None
            return cur_subst
        elif isinstance(t1, dict) and isinstance(t2, dict):
            if set(t1.keys()) != set(t2.keys()):
                return None
            cur_subst = subst
            for k in t1:
                cur_subst = ConstraintSolver.unify(t1[k], t2[k], cur_subst)
                if cur_subst is None:
                    return None
            return cur_subst
        return None
