// AST node definitions for vscript
module main

// Attributes (Decorators) metadata
struct Attribute {
	name  Token
	value ?Expr
}

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
	| GetExpr
	| SetExpr
	| ThisExpr
	| MatchExpr
	| AwaitExpr
	| InterpolatedStringExpr

struct AwaitExpr {
	keyword Token
	value   Expr
}

struct InterpolatedStringExpr {
	parts []Expr
}

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
	params     []Token
	body       []Stmt
	attributes []Attribute
	is_async   bool
}

struct GetExpr {
	object Expr
	name   Token
}

struct SetExpr {
	object Expr
	name   Token
	value  Expr
}

struct ThisExpr {
	keyword Token
}

struct MatchExpr {
	target Expr
	arms   []MatchArm
}

struct MatchArm {
	pattern Pattern
	body    Expr // Match arms in vscript return values
}

// Patterns for match
type Pattern = VariantPattern | LiteralPattern | IdentifierPattern

struct VariantPattern {
	enum_name ?Token // Optional (e.g. Color.red or just red)
	variant   Token
	params    []Token // Bound variables
}

struct LiteralPattern {
	value LiteralExpr
}

struct IdentifierPattern {
	name Token // Default/catch-all
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
	| ClassStmt
	| StructStmt
	| EnumStmt
	| EmptyStmt
	| TryStmt
	| ImportStmt

struct ImportStmt {
	path  Token
	alias ?Token
}

struct TryStmt {
	try_body   Stmt
	catch_var  Token
	catch_body Stmt
}

struct EmptyStmt {}

struct ExprStmt {
	expression Expr
}

struct VarStmt {
	name        Token
	initializer Expr
}

struct FunctionStmt {
	name       Token
	params     []Token
	body       []Stmt
	attributes []Attribute
	is_async   bool
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

struct ClassStmt {
	name       Token
	methods    []FunctionStmt
	attributes []Attribute
}

struct StructStmt {
	name       Token
	fields     []StructField
	attributes []Attribute
}

struct StructField {
	name        Token
	type_name   Token // static type
	initializer ?Expr // optional default value
	attributes  []Attribute
}

struct EnumStmt {
	name       Token
	variants   []EnumVariant
	attributes []Attribute
}

struct EnumVariant {
	name   Token
	params []Token // Associated data types
}
