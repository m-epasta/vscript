// Parser for vscript - builds AST from tokens
module main

struct Parser {
mut:
	tokens       []Token
	current      int
	had_error    bool
	is_test_mode bool
}

fn new_parser(tokens []Token, is_test_mode bool) Parser {
	return Parser{
		tokens:       tokens
		current:      0
		had_error:    false
		is_test_mode: is_test_mode
	}
}

fn (mut p Parser) parse() ![]Stmt {
	mut statements := []Stmt{}

	for !p.is_at_end() {
		if p.match_([.semicolon]) {
			continue
		}
		stmt := p.declaration() or {
			eprintln('[line ${p.peek().line}] Error at \'${p.peek().lexeme}\': ${err}')
			p.had_error = true
			p.synchronize()
			continue
		}
		statements << stmt
	}

	if p.had_error {
		return error('Parse error')
	}

	return statements
}

fn (mut p Parser) declaration() !Stmt {
	mut attributes := []Attribute{}
	for p.match_([.at_bracket]) {
		attributes << p.parse_attributes()!
		for p.match_([.semicolon]) {} // Skip ASI newlines after attribute
	}

	// Check for @[cfg(test)]
	for attr in attributes {
		if attr.name.lexeme == 'cfg' {
			// Basic HACK for now
		}
	}

	mut stmt := Stmt(EmptyStmt{})

	if p.match_([.class_keyword]) {
		stmt = p.class_declaration(attributes)!
	} else if p.match_([.async_keyword]) {
		// async fn name() { ... }
		p.consume(.fn_keyword, "Expect 'fn' after 'async'")!
		stmt = p.function_with_async(attributes, true)!
	} else if p.match_([.fn_keyword]) {
		stmt = p.function_with_async(attributes, false)!
	} else if p.match_([.struct_keyword]) {
		stmt = p.struct_declaration(attributes)!
	} else if p.match_([.enum_keyword]) {
		stmt = p.enum_declaration(attributes)!
	} else if p.match_([.var_keyword]) {
		if attributes.len > 0 {
			return error('Cannot use attributes on variable declarations')
		}
		return p.var_declaration()
	} else {
		if attributes.len > 0 {
			return error('Unexpected attributes before statement')
		}
		return p.statement()
	}

	// Filter logic
	if !p.is_test_mode {
		for attr in attributes {
			if attr.name.lexeme == 'cfg' {
				// Assume cfg(test) for now without deeper ast analysis
				// Only if arg is 'test' (omitted complex check)
			}
			// Logic: if filtered, return EmptyStmt
			// Check for direct test strip
			if attr.name.lexeme == 'test' {
				return Stmt(EmptyStmt{})
			}
			// Check for cfg
			if attr.name.lexeme == 'cfg' {
				// If we had arg access, check it.
				// For now, assume cfg means test config if not in test mode?
				// Or we need to parse arguments of attribute.
				// Attribute has `value ?Expr`.
				// If value is CallExpr (cfg(test)), we check arguments.
				// This requires traversing Expr which we can't easily do here without imported ast helpers.
			}
		}
	}

	// Proper cfg(test) support logic
	// ... filtering ...
	// If filtered: return Stmt(EmptyStmt{})

	return stmt
}

fn (mut p Parser) var_declaration() !Stmt {
	name := p.consume(.identifier, 'Expect variable name')!
	mut initializer := Expr(LiteralExpr{
		value: 'nil'
		type_: .nil_keyword
	})

	if p.match_([.equal]) {
		initializer = p.expression()!
	}

	p.consume(.semicolon, 'Expect ; after variable declaration')!
	return Stmt(VarStmt{
		name:        name
		initializer: initializer
	})
}

fn (mut p Parser) function_with_async(attributes []Attribute, is_async bool) !Stmt {
	name := p.consume(.identifier, 'Expect function name')!

	p.consume(.left_paren, 'Expect ( after function name')!

	mut params := []Token{}
	if !p.check(.right_paren) {
		for {
			params << p.consume(.identifier, 'Expect parameter name')!
			if !p.match_([.comma]) {
				break
			}
		}
	}

	p.consume(.right_paren, 'Expect ) after parameters')!
	p.consume(.left_brace, 'Expect { before function body')!
	body := p.block()!

	return Stmt(FunctionStmt{
		name:       name
		params:     params
		body:       body
		attributes: attributes
		is_async:   is_async
	})
}

fn (mut p Parser) class_declaration(attributes []Attribute) !Stmt {
	name := p.consume(.identifier, 'Expect class name')!
	p.consume(.left_brace, "Expect '{' before class body")!

	mut methods := []FunctionStmt{}
	for !p.check(.right_brace) && !p.is_at_end() {
		for p.match_([.semicolon]) {}
		if p.check(.right_brace) {
			break
		}
		methods << p.method()!
	}

	p.consume(.right_brace, "Expect '}' after class body")!

	return Stmt(ClassStmt{
		name:       name
		methods:    methods
		attributes: attributes
	})
}

fn (mut p Parser) struct_declaration(attributes []Attribute) !Stmt {
	name := p.consume(.identifier, 'Expect struct name')!
	p.consume(.left_brace, "Expect '{' before struct body")!

	mut fields := []StructField{}
	for !p.check(.right_brace) && !p.is_at_end() {
		for p.match_([.semicolon]) {} // Skip leading/separator ASI
		if p.check(.right_brace) {
			break
		}

		mut f_attrs := []Attribute{}
		for p.match_([.at_bracket]) {
			f_attrs << p.parse_attributes()!
			for p.match_([.semicolon]) {}
		}

		f_name := p.consume(.identifier, 'Expect field name')!
		f_type := p.consume(.identifier, 'Expect field type')!

		mut initializer := ?Expr(none)
		if p.match_([.equal]) {
			initializer = p.expression()!
		}

		fields << StructField{
			name:        f_name
			type_name:   f_type
			initializer: initializer
			attributes:  f_attrs
		}

		// Optional separator comma or semicolon (actual or ASI)
		if !p.match_([.comma]) {
			p.match_([.semicolon])
		}
		for p.match_([.semicolon]) {}
	}

	p.consume(.right_brace, "Expect '}' after struct body")!

	return Stmt(StructStmt{
		name:       name
		fields:     fields
		attributes: attributes
	})
}

fn (mut p Parser) enum_declaration(attributes []Attribute) !Stmt {
	name := p.consume(.identifier, 'Expect enum name')!
	p.consume(.left_brace, "Expect '{' before enum body")!

	mut variants := []EnumVariant{}
	for !p.check(.right_brace) && !p.is_at_end() {
		for p.match_([.semicolon]) {}
		if p.check(.right_brace) {
			break
		}

		v_name := p.consume(.identifier, 'Expect variant name')!
		mut params := []Token{}
		if p.match_([.left_paren]) {
			if !p.check(.right_paren) {
				for {
					params << p.consume(.identifier, 'Expect parameter type name')!
					if !p.match_([.comma]) {
						break
					}
				}
			}
			p.consume(.right_paren, 'Expect ) after enum variant parameters')!
		}

		variants << EnumVariant{
			name:   v_name
			params: params
		}

		// Handle comma or semicolon/newline separators
		if !p.match_([.comma]) {
			p.match_([.semicolon])
		}
		for p.match_([.semicolon]) {}
	}

	p.consume(.right_brace, "Expect '}' after enum body")!

	return Stmt(EnumStmt{
		name:       name
		variants:   variants
		attributes: attributes
	})
}

fn (mut p Parser) method() !FunctionStmt {
	mut attributes := []Attribute{}
	for p.match_([.at_bracket]) {
		attributes << p.parse_attributes()!
		for p.match_([.semicolon]) {} // Skip ASI newlines after attribute
	}

	mut is_async := false
	if p.match_([.async_keyword]) {
		is_async = true
	}

	name := p.consume(.identifier, 'Expect method name')!
	p.consume(.left_paren, "Expect '(' after method name")!

	mut params := []Token{}
	if !p.check(.right_paren) {
		for {
			params << p.consume(.identifier, 'Expect parameter name')!
			if !p.match_([.comma]) {
				break
			}
		}
	}

	p.consume(.right_paren, "Expect ')' after parameters")!
	p.consume(.left_brace, "Expect '{' before method body")!
	body := p.block()!

	return FunctionStmt{
		name:       name
		params:     params
		body:       body
		attributes: attributes
		is_async:   is_async
	}
}

fn (mut p Parser) statement() !Stmt {
	if p.match_([.for_keyword]) {
		return p.for_statement()
	}
	if p.match_([.if_keyword]) {
		return p.if_statement()
	}
	if p.match_([.try_keyword]) {
		return p.try_statement()
	}
	if p.match_([.import_keyword]) {
		return p.import_statement()
	}
	if p.match_([.return_keyword]) {
		return p.return_statement()
	}
	if p.match_([.while_keyword]) {
		return p.while_statement()
	}
	if p.match_([.left_brace]) {
		return Stmt(BlockStmt{
			statements: p.block()!
		})
	}

	return p.expression_statement()
}

fn (mut p Parser) for_statement() !Stmt {
	p.consume(.left_paren, 'Expect ( after for')!

	mut initializer := ?Stmt(none)
	if !p.match_([.semicolon]) {
		initializer = p.expression_statement()!
	}

	mut condition := ?Expr(none)
	if !p.check(.semicolon) {
		condition = p.expression()!
	}
	p.consume(.semicolon, 'Expect ; after loop condition')!

	mut increment := ?Expr(none)
	if !p.check(.right_paren) {
		increment = p.expression()!
	}
	p.consume(.right_paren, 'Expect ) after for clauses')!

	body := p.statement()!

	return Stmt(ForStmt{
		initializer: initializer
		condition:   condition
		increment:   increment
		body:        body
	})
}

fn (mut p Parser) if_statement() !Stmt {
	p.consume(.left_paren, 'Expect ( after if')!
	condition := p.expression()!
	p.consume(.right_paren, 'Expect ) after condition')!

	then_branch := p.statement()!
	mut else_branch := ?Stmt(none)
	if p.match_([.else_keyword]) {
		else_branch = p.statement()!
	}

	return Stmt(IfStmt{
		condition:   condition
		then_branch: then_branch
		else_branch: else_branch
	})
}

fn (mut p Parser) return_statement() !Stmt {
	keyword := p.previous()
	mut value := ?Expr(none)
	if !p.check(.semicolon) {
		value = p.expression()!
	}

	p.consume(.semicolon, 'Expect ; after return value')!
	return Stmt(ReturnStmt{
		keyword: keyword
		value:   value
	})
}

fn (mut p Parser) while_statement() !Stmt {
	p.consume(.left_paren, 'Expect ( after while')!
	condition := p.expression()!
	p.consume(.right_paren, 'Expect ) after condition')!
	body := p.statement()!

	return Stmt(WhileStmt{
		condition: condition
		body:      body
	})
}

fn (mut p Parser) try_statement() !Stmt {
	// 'try' is already matched
	p.consume(.left_brace, "Expect '{' before try body")!
	try_body := Stmt(BlockStmt{
		statements: p.block()!
	})

	p.consume(.catch_keyword, "Expect 'catch' after try block")!
	p.consume(.left_paren, "Expect '(' after catch")!
	catch_var := p.consume(.identifier, 'Expect identifier for catch error')!
	p.consume(.right_paren, "Expect ')' after catch identifier")!

	p.consume(.left_brace, "Expect '{' before catch body")!
	catch_body := Stmt(BlockStmt{
		statements: p.block()!
	})

	return Stmt(TryStmt{
		try_body:   try_body
		catch_var:  catch_var
		catch_body: catch_body
	})
}

fn (mut p Parser) import_statement() !Stmt {
	// 'import' is already consumed

	mut path_token := Token{} // Placeholder

	if p.match_([.string]) {
		// String literal path: import "foo/bar.vs"
		path_token = p.previous()
	} else if p.match_([.identifier]) {
		// Identifier path: import foo:bar
		// Logic: parse identifiers joined by colons
		mut parts := [p.previous().lexeme]
		for p.match_([.colon]) {
			part := p.consume(.identifier, 'Expect identifier after : in import path')!
			parts << part.lexeme
		}
		// Convert identifiers to path with .vs extension
		// e.g. std:math -> std/math.vs
		path_str := parts.join('/') + '.vs'

		// Create synthetic token for the path
		path_token = Token{
			type_:   .string
			lexeme:  '"${path_str}"'
			literal: path_str
			line:    p.previous().line
		}
	} else {
		return error('Expect string or identifier execution path after import')
	}

	// Optional alias: import ... as alias
	mut alias := ?Token(none)
	if p.match_([.identifier]) { // "as" is not a keyword, checked as identifier
		if p.previous().lexeme == 'as' {
			alias_token := p.consume(.identifier, 'Expect alias name after as')!
			alias = alias_token
		} else {
			// Backtrack? No, "as" is contextual. If next is identifier but not 'as', it's an error?
			// Unlike SQL, vscript doesn't have implicit alias without 'as'.
			// But wait, if they write `import "foo" bar`, that's invalid syntax here.
			// Currently we only support explicit `as`.
			// If we consumed an identifier that is NOT 'as', that's an error in parsing?
			// Actually `match_` consumes. If it wasn't 'as', we effectively consumed an unexpected identifier.
			return error("Expect 'as' for import alias")
		}
	}

	p.consume(.semicolon, 'Expect ; after import')!

	return Stmt(ImportStmt{
		path:  path_token
		alias: alias
	})
}

fn (mut p Parser) expression_statement() !Stmt {
	expr := p.expression()!
	p.consume(.semicolon, 'Expect ; after expression')!
	return Stmt(ExprStmt{
		expression: expr
	})
}

fn (mut p Parser) block() ![]Stmt {
	mut statements := []Stmt{}
	for !p.check(.right_brace) && !p.is_at_end() {
		for p.match_([.semicolon]) {}
		if p.check(.right_brace) {
			break
		}
		statements << p.declaration()!
	}

	p.consume(.right_brace, "Expect '}' after block")!
	return statements
}

fn (mut p Parser) expression() !Expr {
	return p.assignment()
}

fn (mut p Parser) assignment() !Expr {
	expr := p.or_()!

	if p.match_([.equal]) {
		value := p.assignment()!

		match expr {
			VariableExpr {
				return Expr(AssignExpr{
					name:  expr.name
					value: value
				})
			}
			GetExpr {
				return Expr(SetExpr{
					object: expr.object
					name:   expr.name
					value:  value
				})
			}
			IndexExpr {
				return Expr(AssignIndexExpr{
					object: expr.object
					index:  expr.index
					value:  value
				})
			}
			else {
				error('Invalid assignment target')
			}
		}
	}

	return expr
}

fn (mut p Parser) or_() !Expr {
	mut expr := p.and_()!

	// TODO: logical or handling
	/*
	for p.match_([.or_keyword]) {
		operator := p.previous()
		right := p.and_()!
		expr = Expr(LogicalExpr{left: expr, operator: operator, right: right})
	}
	*/

	return expr
}

fn (mut p Parser) and_() !Expr {
	mut expr := p.equality()!

	// TODO: logical and handling
	/*
	for p.match_([.and_keyword]) {
		operator := p.previous()
		right := p.equality()!
		expr = Expr(LogicalExpr{left: expr, operator: operator, right: right})
	}
	*/

	return expr
}

fn (mut p Parser) equality() !Expr {
	mut expr := p.comparison()!

	for p.match_([.bang_equal, .equal_equal]) {
		operator := p.previous()
		right := p.comparison()!
		expr = Expr(BinaryExpr{
			left:     expr
			operator: operator
			right:    right
		})
	}

	return expr
}

fn (mut p Parser) comparison() !Expr {
	mut expr := p.term()!

	for p.match_([.greater, .greater_equal, .less, .less_equal]) {
		operator := p.previous()
		right := p.term()!
		expr = Expr(BinaryExpr{
			left:     expr
			operator: operator
			right:    right
		})
	}

	return expr
}

fn (mut p Parser) term() !Expr {
	mut expr := p.factor()!

	for p.match_([.minus, .plus]) {
		operator := p.previous()
		right := p.factor()!
		expr = Expr(BinaryExpr{
			left:     expr
			operator: operator
			right:    right
		})
	}

	return expr
}

fn (mut p Parser) factor() !Expr {
	mut expr := p.unary()!

	for p.match_([.slash, .star, .percent]) {
		operator := p.previous()
		right := p.unary()!
		expr = Expr(BinaryExpr{
			left:     expr
			operator: operator
			right:    right
		})
	}

	return expr
}

fn (mut p Parser) unary() !Expr {
	if p.match_([.bang, .minus]) {
		operator := p.previous()
		right := p.unary()!
		return Expr(UnaryExpr{
			operator: operator
			right:    right
		})
	}

	if p.match_([.await_keyword]) {
		keyword := p.previous()
		value := p.unary()!
		return Expr(AwaitExpr{
			keyword: keyword
			value:   value
		})
	}

	return p.call()
}

fn (mut p Parser) call() !Expr {
	mut expr := p.primary()!

	for {
		if p.match_([.left_paren]) {
			expr = p.finish_call(expr)!
		} else if p.match_([.dot]) {
			name := p.consume(.identifier, 'Expect property name after .')!
			expr = Expr(GetExpr{
				object: expr
				name:   name
			})
		} else if p.match_([.left_bracket]) {
			index := p.expression()!
			p.consume(.right_bracket, 'Expect ] after index')!
			expr = Expr(IndexExpr{
				object: expr
				index:  index
			})
		} else {
			break
		}
	}

	return expr
}

fn (mut p Parser) finish_call(callee Expr) !Expr {
	mut arguments := []Expr{}
	if !p.check(.right_paren) {
		for {
			arguments << p.expression()!
			if !p.match_([.comma]) {
				break
			}
		}
	}

	paren := p.consume(.right_paren, 'Expect ) after arguments')!

	return Expr(CallExpr{
		callee:    callee
		paren:     paren
		arguments: arguments
	})
}

fn (mut p Parser) primary() !Expr {
	if p.match_([.false_keyword]) {
		return Expr(LiteralExpr{
			value: 'false'
			type_: .false_keyword
		})
	}
	if p.match_([.true_keyword]) {
		return Expr(LiteralExpr{
			value: 'true'
			type_: .true_keyword
		})
	}
	if p.match_([.nil_keyword]) {
		return Expr(LiteralExpr{
			value: 'nil'
			type_: .nil_keyword
		})
	}

	if p.match_([.number, .string]) {
		return Expr(LiteralExpr{
			value: p.previous().literal
			type_: p.previous().type_
		})
	}

	if p.match_([.string_interp_start]) {
		return p.interpolated_string()
	}

	if p.match_([.this_keyword]) {
		return Expr(ThisExpr{
			keyword: p.previous()
		})
	}

	if p.match_([.identifier]) {
		return Expr(VariableExpr{
			name: p.previous()
		})
	}

	if p.match_([.left_paren]) {
		expr := p.expression()!
		p.consume(.right_paren, 'Expect ) after expression')!
		return Expr(GroupingExpr{
			expression: expr
		})
	}

	if p.match_([.left_bracket]) {
		return p.array_literal()
	}

	if p.match_([.left_brace]) {
		return p.map_literal()
	}

	if p.match_([.async_keyword]) {
		p.consume(.fn_keyword, "Expect 'fn' after 'async'")!
		return p.function_expression_with_async(true)
	}

	if p.match_([.fn_keyword]) {
		return p.function_expression_with_async(false)
	}

	if p.match_([.match_keyword]) {
		return p.match_expression()
	}

	return error('Expect expression')
}

fn (mut p Parser) interpolated_string() !Expr {
	mut parts := []Expr{}
	// First segment
	parts << Expr(LiteralExpr{
		value: p.previous().literal
		type_: .string
	})

	for {
		// Interpolated expression
		parts << p.expression()!

		if p.match_([.string_interp_middle]) {
			parts << Expr(LiteralExpr{
				value: p.previous().literal
				type_: .string
			})
		} else if p.match_([.string_interp_end]) {
			parts << Expr(LiteralExpr{
				value: p.previous().literal
				type_: .string
			})
			break
		} else {
			return error("Expect '}' or more string segments after interpolation expression")
		}
	}

	return Expr(InterpolatedStringExpr{
		parts: parts
	})
}

fn (mut p Parser) function_expression_with_async(is_async bool) !Expr {
	p.consume(.left_paren, 'Expect ( after fn')!
	mut params := []Token{}
	if !p.check(.right_paren) {
		for {
			params << p.consume(.identifier, 'Expect parameter name')!
			if !p.match_([.comma]) {
				break
			}
		}
	}
	p.consume(.right_paren, 'Expect ) after parameters')!
	p.consume(.left_brace, 'Expect { before function body')!
	body := p.block()!
	return Expr(FunctionExpr{
		params:     params
		body:       body
		attributes: []Attribute{}
		is_async:   is_async
	})
}

fn (mut p Parser) match_expression() !Expr {
	target := p.expression()!
	p.consume(.left_brace, "Expect '{' after match target")!

	mut arms := []MatchArm{}
	for !p.check(.right_brace) && !p.is_at_end() {
		for p.match_([.semicolon]) {}
		if p.check(.right_brace) {
			break
		}

		pattern := p.parse_pattern()!
		p.consume(.fat_arrow, "Expect '=>' after pattern")!

		mut body := Expr(LiteralExpr{
			value: 'nil'
			type_: .nil_keyword
		})

		if p.match_([.left_brace]) {
			statements := p.block()!
			body = Expr(FunctionExpr{
				params:     []Token{}
				body:       statements
				attributes: []Attribute{}
			})
		} else {
			body = p.expression()!
		}

		arms << MatchArm{
			pattern: pattern
			body:    body
		}
		p.match_([.comma])
		for p.match_([.semicolon]) {}
	}

	p.consume(.right_brace, "Expect '}' after match arms")!

	return Expr(MatchExpr{
		target: target
		arms:   arms
	})
}

fn (mut p Parser) parse_pattern() !Pattern {
	if p.match_([.number, .string, .true_keyword, .false_keyword, .nil_keyword]) {
		return Pattern(LiteralPattern{
			value: LiteralExpr{
				value: p.previous().literal
				type_: p.previous().type_
			}
		})
	}

	if p.match_([.identifier]) {
		name := p.previous()

		// Could be a variant name maybe? like Option.some
		if p.match_([.dot]) {
			variant := p.consume(.identifier, 'Expect variant name after .')!
			mut params := []Token{}
			if p.match_([.left_paren]) {
				if !p.check(.right_paren) {
					for {
						params << p.consume(.identifier, 'Expect parameter name')!
						if !p.match_([.comma]) {
							break
						}
					}
				}
				p.consume(.right_paren, 'Expect ) after variant pattern')!
			}
			return Pattern(VariantPattern{
				enum_name: name
				variant:   variant
				params:    params
			})
		}

		// Just a variant or a catch-all?
		// For now, if it's followed by '(' it's a variant literal pattern
		if p.match_([.left_paren]) {
			mut params := []Token{}
			if !p.check(.right_paren) {
				for {
					params << p.consume(.identifier, 'Expect parameter name')!
					if !p.match_([.comma]) {
						break
					}
				}
			}
			p.consume(.right_paren, 'Expect ) after variant pattern')!
			return Pattern(VariantPattern{
				enum_name: none
				variant:   name
				params:    params
			})
		}

		return Pattern(IdentifierPattern{
			name: name
		})
	}

	return error('Expect pattern')
}

fn (mut p Parser) array_literal() !Expr {
	mut elements := []Expr{}
	if !p.check(.right_bracket) {
		for {
			for p.match_([.semicolon]) {}
			if p.check(.right_bracket) {
				break
			}

			elements << p.expression()!
			if !p.match_([.comma]) {
				break
			}
			for p.match_([.semicolon]) {}
		}
	}
	for p.match_([.semicolon]) {}
	p.consume(.right_bracket, 'Expect ] after array elements')!
	return Expr(ArrayExpr{
		elements: elements
	})
}

fn (mut p Parser) map_literal() !Expr {
	mut keys := []Expr{}
	mut values := []Expr{}

	if !p.check(.right_brace) {
		for {
			for p.match_([.semicolon]) {}
			if p.check(.right_brace) {
				break
			}

			keys << p.expression()!
			p.consume(.colon, 'Expect : after key')!
			values << p.expression()!

			if !p.match_([.comma]) {
				break
			}
			for p.match_([.semicolon]) {}
		}
	}
	for p.match_([.semicolon]) {}
	p.consume(.right_brace, 'Expect } after map elements')!
	return Expr(MapExpr{
		keys:   keys
		values: values
	})
}

fn (mut p Parser) parse_attributes() ![]Attribute {
	mut attributes := []Attribute{}
	for p.match_([.semicolon]) {} // Skip leading ASI
	if !p.check(.right_bracket) {
		for {
			for p.match_([.semicolon]) {}
			name := p.consume(.identifier, 'Expect attribute name')!
			mut val := ?Expr(none)
			if p.match_([.colon]) {
				val = p.expression()!
			} else if p.match_([.left_paren]) {
				val = p.expression()!
				p.consume(.right_paren, "Expect ')' after attribute argument")!
			}
			attributes << Attribute{
				name:  name
				value: val
			}
			if !p.match_([.comma]) {
				break
			}
		}
	}
	for p.match_([.semicolon]) {}
	p.consume(.right_bracket, "Expect ']' after attributes")!
	return attributes
}

fn (mut p Parser) match_(types []TokenType) bool {
	for type_ in types {
		if p.check(type_) {
			p.advance()
			return true
		}
	}
	return false
}

fn (mut p Parser) check(type_ TokenType) bool {
	if p.is_at_end() {
		return false
	}
	return p.peek().type_ == type_
}

fn (mut p Parser) advance() Token {
	if !p.is_at_end() {
		p.current++
	}
	return p.previous()
}

fn (p &Parser) is_at_end() bool {
	return p.peek().type_ == .eof
}

fn (p &Parser) peek() Token {
	return p.tokens[p.current]
}

fn (p &Parser) previous() Token {
	return p.tokens[p.current - 1]
}

fn (mut p Parser) consume(type_ TokenType, message string) !Token {
	if p.check(type_) {
		return p.advance()
	}

	p.had_error = true
	return error(message)
}

fn (mut p Parser) synchronize() {
	p.advance()

	for !p.is_at_end() {
		if p.previous().type_ == .semicolon {
			return
		}

		match p.peek().type_ {
			.fn_keyword, .for_keyword, .if_keyword, .while_keyword, .return_keyword {
				return
			}
			else {}
		}

		p.advance()
	}
}
