"""Curry Abstract Syntax Tree (AST) definitions for Ferrule engine.
Defines nodes for declarative functional-logic programming constructs.
"""

from dataclasses import dataclass, field
from typing import List, Optional, Any, Dict, Union

@dataclass
class AstNode:
    line: int = 1
    col: int = 1

@dataclass
class TypeExpr(AstNode):
    name: str = ""
    args: List['TypeExpr'] = field(default_factory=list)

@dataclass
class DataConstructor(AstNode):
    name: str = ""
    fields: List[TypeExpr] = field(default_factory=list)

@dataclass
class DataDecl(AstNode):
    name: str = ""
    type_params: List[str] = field(default_factory=list)
    constructors: List[DataConstructor] = field(default_factory=list)

@dataclass
class TypeDecl(AstNode):
    name: str = ""
    target: TypeExpr = field(default_factory=TypeExpr)

@dataclass
class Pattern(AstNode):
    pass

@dataclass
class VarPattern(Pattern):
    name: str = ""

@dataclass
class WildcardPattern(Pattern):
    pass

@dataclass
class LitPattern(Pattern):
    value: Any = None

@dataclass
class ConstrPattern(Pattern):
    name: str = ""
    sub_patterns: List[Pattern] = field(default_factory=list)

@dataclass
class Expr(AstNode):
    pass

@dataclass
class VarExpr(Expr):
    name: str = ""

@dataclass
class LitExpr(Expr):
    value: Any = None

@dataclass
class AppExpr(Expr):
    func: Expr = field(default_factory=Expr)
    arg: Expr = field(default_factory=Expr)

@dataclass
class ChoiceExpr(Expr):
    """Non-deterministic choice operator (?) in Curry."""
    left: Expr = field(default_factory=Expr)
    right: Expr = field(default_factory=Expr)

@dataclass
class ConstraintExpr(Expr):
    """Equational constraint (=:=) in Curry."""
    left: Expr = field(default_factory=Expr)
    right: Expr = field(default_factory=Expr)

@dataclass
class FreeVarDecl(AstNode):
    """Free/logic variable declaration in Curry."""
    names: List[str] = field(default_factory=list)
    body: Expr = field(default_factory=Expr)

@dataclass
class FuncEquation(AstNode):
    patterns: List[Pattern] = field(default_factory=list)
    rhs: Expr = field(default_factory=Expr)
    guard: Optional[Expr] = None

@dataclass
class FunctionDecl(AstNode):
    name: str = ""
    type_sig: Optional[TypeExpr] = None
    equations: List[FuncEquation] = field(default_factory=list)

@dataclass
class Module(AstNode):
    name: str = ""
    imports: List[str] = field(default_factory=list)
    decls: List[Union[DataDecl, TypeDecl, FunctionDecl]] = field(default_factory=list)
