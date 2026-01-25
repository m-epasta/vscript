// Parser for vscript - builds AST from tokens
module main

struct Parser {
mut:
	tokens    []Token
	current   int
	had_error bool
}

fn new_parser(tokens []Token) Parser {
	return Parser{
		tokens:    tokens
		current:   0
		had_error: false
	}
}

fn (mut p Parser) parse() ![]Stmt {
	mut statements := []Stmt{}

	for !p.is_at_end() {
		if p.match_([.semicolon]) {
			continue
		}
		stmt := p.declaration() or {
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
	// println('Declaration check: ${p.peek().type_}')
	if p.match_([.fn_keyword]) {
		stmt := p.function()!
		return stmt
	}
	if p.match_([.var_keyword]) {
		return p.var_declaration()
	}

	return p.statement()
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

	return Stmt(VarStmt{
		name:        name
		initializer: initializer
	})
}

fn (mut p Parser) function() !Stmt {
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
		name:   name
		params: params
		body:   body
	})
}

fn (mut p Parser) statement() !Stmt {
	if p.match_([.for_keyword]) {
		return p.for_statement()
	}
	if p.match_([.if_keyword]) {
		return p.if_statement()
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

	if !p.check(.semicolon) && !p.check(.right_brace) {
		value = p.expression()!
	}

	p.match_([.semicolon])

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

fn (mut p Parser) block() ![]Stmt {
	mut statements := []Stmt{}

	for !p.check(.right_brace) && !p.is_at_end() {
		if p.match_([.semicolon]) {
			continue
		}
		statements << p.declaration()!
	}

	p.consume(.right_brace, 'Expect } after block')!
	return statements
}

fn (mut p Parser) expression_statement() !Stmt {
	expr := p.expression()!
	p.match_([.semicolon])
	return Stmt(ExprStmt{
		expression: expr
	})
}

fn (mut p Parser) expression() !Expr {
	return p.assignment()
}

fn (mut p Parser) assignment() !Expr {
	expr := p.or_()!

	if p.match_([.equal]) {
		value := p.assignment()!

		if expr is VariableExpr {
			return Expr(AssignExpr{
				name:  expr.name
				value: value
			})
		} else if expr is IndexExpr {
			return Expr(AssignIndexExpr{
				object: expr.object
				index:  expr.index
				value:  value
			})
		}

		return error('Invalid assignment target')
	}

	return expr
}

fn (mut p Parser) or_() !Expr {
	mut expr := p.and_()!

	for p.match_([.identifier]) && p.previous().lexeme == 'or' {
		operator := p.previous()
		right := p.and_()!
		expr = Expr(BinaryExpr{
			left:     expr
			operator: operator
			right:    right
		})
	}

	return expr
}

fn (mut p Parser) and_() !Expr {
	mut expr := p.equality()!

	for p.match_([.identifier]) && p.previous().lexeme == 'and' {
		operator := p.previous()
		right := p.equality()!
		expr = Expr(BinaryExpr{
			left:     expr
			operator: operator
			right:    right
		})
	}

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

	return p.call()
}

fn (mut p Parser) call() !Expr {
	mut expr := p.primary()!

	for {
		if p.match_([.left_paren]) {
			expr = p.finish_call(expr)!
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
		prev := p.previous()
		return Expr(LiteralExpr{
			value: prev.literal
			type_: prev.type_
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
		mut elements := []Expr{}
		if !p.check(.right_bracket) {
			for {
				elements << p.expression()!
				if !p.match_([.comma]) {
					break
				}
			}
		}
		p.consume(.right_bracket, 'Expect ] after array elements')!
		return Expr(ArrayExpr{
			elements: elements
		})
	}

	if p.match_([.left_bracket]) {
		return p.array()
	}

	if p.match_([.fn_keyword]) {
		return p.anonymous_function()
	}

	return error('Expect expression')
}

fn (mut p Parser) anonymous_function() !Expr {
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
		params: params
		body:   body
	})
}

fn (mut p Parser) array() !Expr {
	mut elements := []Expr{}
	if !p.check(.right_bracket) {
		for {
			elements << p.expression()!
			if !p.match_([.comma]) {
				break
			}
		}
	}
	p.consume(.right_bracket, 'Expect ] after array elements')!
	return Expr(ArrayExpr{
		elements: elements
	})
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
