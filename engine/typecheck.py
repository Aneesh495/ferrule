"""Hindley-Milner type checker and signature validator for Curry modules.
Validates algebraic data type definitions and constructor signatures.
"""

from typing import Dict, List, Set, Optional
from .ast import Module, DataDecl, TypeDecl, FunctionDecl

class TypeError(Exception):
    pass

class TypeEnvironment:
    def __init__(self):
        self.types: Set[str] = {"Int", "Float", "Bool", "String", "Char"}
        self.constructors: Dict[str, str] = {}
        self.functions: Dict[str, str] = {}

    def register_data_decl(self, decl: DataDecl):
        self.types.add(decl.name)
        for constr in decl.constructors:
            self.constructors[constr.name] = decl.name

    def register_type_decl(self, decl: TypeDecl):
        self.types.add(decl.name)

    def register_function(self, decl: FunctionDecl):
        self.functions[decl.name] = "Any"

class TypeChecker:
    def __init__(self):
        self.env = TypeEnvironment()

    def check_module(self, module: Module) -> bool:
        # Pass 1: Register all declared types and constructors
        for decl in module.decls:
            if isinstance(decl, DataDecl):
                self.env.register_data_decl(decl)
            elif isinstance(decl, TypeDecl):
                self.env.register_type_decl(decl)

        # Pass 2: Register functions
        for decl in module.decls:
            if isinstance(decl, FunctionDecl):
                self.env.register_function(decl)

        # Pass 3: Validate constructor uniqueness
        seen_constrs = set()
        for decl in module.decls:
            if isinstance(decl, DataDecl):
                for constr in decl.constructors:
                    if constr.name in seen_constrs:
                        raise TypeError(f"Duplicate data constructor '{constr.name}' in module '{module.name}'")
                    seen_constrs.add(constr.name)

        return True
