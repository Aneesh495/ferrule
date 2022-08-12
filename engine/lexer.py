"""Lexical scanner for Curry source code.
Tokenizes identifiers, keywords, non-deterministic operators, and literals.
"""

import re
from typing import List, NamedTuple

class Token(NamedTuple):
    type: str
    value: str
    line: int
    col: int

KEYWORDS = {
    'module', 'where', 'import', 'data', 'type', 'deriving',
    'let', 'in', 'case', 'of', 'free', 'if', 'then', 'else',
    'True', 'False', 'Nothing', 'Just'
}

OPERATORS = {
    '?': 'CHOICE',
    '=:=': 'EQUATIONAL_CONSTRAINT',
    '::': 'DOUBLE_COLON',
    '->': 'ARROW',
    '=': 'EQUALS',
    '|': 'PIPE',
    '\\': 'LAMBDA',
    '++': 'CONCAT',
    ':': 'CONS',
    '&&': 'AND',
    '||': 'OR',
    '==': 'EQ',
    '/=': 'NEQ',
    '<=': 'LTE',
    '>=': 'GTE',
    '<': 'LT',
    '>': 'GT',
    '+': 'PLUS',
    '-': 'MINUS',
    '*': 'STAR',
    '/': 'SLASH'
}

class Lexer:
    def __init__(self, source: str):
        self.source = source
        self.pos = 0
        self.line = 1
        self.col = 1
        self.length = len(source)

    def tokenize(self) -> List[Token]:
        tokens = []
        while self.pos < self.length:
            c = self.source[self.pos]

            # Whitespace
            if c == ' ' or c == '\t' or c == '\r':
                self.pos += 1
                self.col += 1
                continue
            elif c == '\n':
                self.pos += 1
                self.line += 1
                self.col = 1
                continue

            # Line comments
            if c == '-' and self.pos + 1 < self.length and self.source[self.pos + 1] == '-':
                while self.pos < self.length and self.source[self.pos] != '\n':
                    self.pos += 1
                continue

            # Delimiters
            if c in '()[]{},;':
                tokens.append(Token(c, c, self.line, self.col))
                self.pos += 1
                self.col += 1
                continue

            # String literal
            if c == '"':
                start_col = self.col
                self.pos += 1
                self.col += 1
                buf = []
                while self.pos < self.length and self.source[self.pos] != '"':
                    if self.source[self.pos] == '\\' and self.pos + 1 < self.length:
                        self.pos += 1
                        buf.append(self.source[self.pos])
                    else:
                        buf.append(self.source[self.pos])
                    self.pos += 1
                    self.col += 1
                if self.pos < self.length and self.source[self.pos] == '"':
                    self.pos += 1
                    self.col += 1
                tokens.append(Token('STRING', ''.join(buf), self.line, start_col))
                continue

            # Multi-character or single-character operators
            matched_op = None
            for op in sorted(OPERATORS.keys(), key=lambda x: -len(x)):
                if self.source.startswith(op, self.pos):
                    matched_op = op
                    break
            if matched_op:
                tokens.append(Token(OPERATORS[matched_op], matched_op, self.line, self.col))
                self.pos += len(matched_op)
                self.col += len(matched_op)
                continue

            # Number literal (int, float, scientific notation)
            if c.isdigit() or (c == '.' and self.pos + 1 < self.length and self.source[self.pos + 1].isdigit()):
                start_col = self.col
                num_match = re.match(r'0x[0-9a-fA-F]+|\d+(\.\d+)?([eE][+-]?\d+)?', self.source[self.pos:])
                if num_match:
                    num_str = num_match.group(0)
                    self.pos += len(num_str)
                    self.col += len(num_str)
                    tokens.append(Token('NUMBER', num_str, self.line, start_col))
                    continue

            # Identifiers and keywords
            if c.isalpha() or c == '_':
                start_col = self.col
                id_match = re.match(r'[A-Za-z_][A-Za-z0-9_\']*', self.source[self.pos:])
                if id_match:
                    id_str = id_match.group(0)
                    self.pos += len(id_str)
                    self.col += len(id_str)
                    tok_type = 'KEYWORD' if id_str in KEYWORDS else 'IDENT'
                    tokens.append(Token(tok_type, id_str, self.line, start_col))
                    continue

            # Unrecognized character fallback
            tokens.append(Token('CHAR', c, self.line, self.col))
            self.pos += 1
            self.col += 1

        tokens.append(Token('EOF', '', self.line, self.col))
        return tokens
