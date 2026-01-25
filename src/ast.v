// AST node definitions for vscript
module main

// Expression types
type Expr = BinaryExpr
	| UnaryExpr
	| LiteralExpr
	| GroupingExpr
	| VariableExpr
	| AssignExpr
	| CallExpr
	| ArrayExpr
	| MapExpr
	| IndexExpr
	| AssignIndexExpr
	| FunctionExpr

struct BinaryExpr {
	left     Expr
	operator Token
	right    Expr
}

struct UnaryExpr {
	operator Token
	right    Expr
}

struct LiteralExpr {
	value string
	type_ TokenType
}

struct GroupingExpr {
	expression Expr
}

struct VariableExpr {
	name Token
}

struct AssignExpr {
	name  Token
	value Expr
}

struct CallExpr {
	callee    Expr
	paren     Token
	arguments []Expr
}

struct ArrayExpr {
	elements []Expr
}

struct IndexExpr {
	object Expr
	index  Expr
}

struct AssignIndexExpr {
	object Expr
	index  Expr
	value  Expr
}

struct MapExpr {
	keys   []Expr
	values []Expr
}

struct FunctionExpr {
	params []Token
	body   []Stmt
}

// Statement types
type Stmt = ExprStmt
	| VarStmt
	| FunctionStmt
	| IfStmt
	| WhileStmt
	| ForStmt
	| ReturnStmt
	| BlockStmt

struct ExprStmt {
	expression Expr
}

struct VarStmt {
	name        Token
	initializer Expr
}

struct FunctionStmt {
	name   Token
	params []Token
	body   []Stmt
}

struct IfStmt {
	condition   Expr
	then_branch Stmt
	else_branch ?Stmt
}

struct WhileStmt {
	condition Expr
	body      Stmt
}

struct ForStmt {
	initializer ?Stmt
	condition   ?Expr
	increment   ?Expr
	body        Stmt
}

struct ReturnStmt {
	keyword Token
	value   ?Expr
}

struct BlockStmt {
	statements []Stmt
}
