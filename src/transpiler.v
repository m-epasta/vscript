// JavaScript transpiler for vscript
module main

import strings

struct Transpiler {
mut:
	output       strings.Builder
	indent_level int
}

fn new_transpiler() Transpiler {
	return Transpiler{
		output:       strings.new_builder(1024)
		indent_level: 0
	}
}

fn (mut t Transpiler) transpile_stmts(stmts []Stmt) string {
	for stmt in stmts {
		t.visit_stmt(stmt)
	}
	return t.output.str()
}

fn (mut t Transpiler) visit_stmt(stmt Stmt) {
	match stmt {
		EmptyStmt {}
		TryStmt {
			t.indent()
			t.output.write_string('try {\n')
			t.indent_level++
			t.visit_stmt(stmt.try_body)
			t.indent_level--
			t.indent()
			t.output.write_string('} catch (')
			t.output.write_string(stmt.catch_var.lexeme)
			t.output.write_string(') {\n')
			t.indent_level++
			t.visit_stmt(stmt.catch_body)
			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
		}
		ExprStmt {
			t.indent()
			t.visit_expr(stmt.expression)
			t.output.write_string(';\n')
		}
		VarStmt {
			t.indent()
			t.output.write_string('let ')
			t.output.write_string(stmt.name.lexeme)
			t.output.write_string(' = ')
			t.visit_expr(stmt.initializer)
			t.output.write_string(';\n')
		}
		FunctionStmt {
			t.indent()
			if stmt.is_async {
				t.output.write_string('async ')
			}
			t.output.write_string('function ')
			t.output.write_string(stmt.name.lexeme)
			t.output.write_string('(')
			for i, param in stmt.params {
				if i > 0 {
					t.output.write_string(', ')
				}
				t.output.write_string(param.lexeme)
			}
			t.output.write_string(') {\n')
			t.indent_level++
			for s in stmt.body {
				t.visit_stmt(s)
			}
			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
		}
		IfStmt {
			t.indent()
			t.output.write_string('if (')
			t.visit_expr(stmt.condition)
			t.output.write_string(') {\n')
			t.indent_level++
			t.visit_stmt(stmt.then_branch)
			t.indent_level--
			if else_branch := stmt.else_branch {
				t.indent()
				t.output.write_string('} else {\n')
				t.indent_level++
				t.visit_stmt(else_branch)
				t.indent_level--
			}
			t.indent()
			t.output.write_string('}\n')
		}
		WhileStmt {
			t.indent()
			t.output.write_string('while (')
			t.visit_expr(stmt.condition)
			t.output.write_string(') {\n')
			t.indent_level++
			t.visit_stmt(stmt.body)
			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
		}
		ForStmt {
			t.indent()
			t.output.write_string('for (')
			if initializer := stmt.initializer {
				match initializer {
					VarStmt {
						t.output.write_string('let ')
						t.output.write_string(initializer.name.lexeme)
						t.output.write_string(' = ')
						t.visit_expr(initializer.initializer)
					}
					ExprStmt {
						t.visit_expr(initializer.expression)
					}
					else {}
				}
			}
			t.output.write_string('; ')
			if condition := stmt.condition {
				t.visit_expr(condition)
			}
			t.output.write_string('; ')
			if increment := stmt.increment {
				t.visit_expr(increment)
			}
			t.output.write_string(') {\n')
			t.indent_level++
			t.visit_stmt(stmt.body)
			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
		}
		ReturnStmt {
			t.indent()
			t.output.write_string('return')
			if value := stmt.value {
				t.output.write_string(' ')
				t.visit_expr(value)
			}
			t.output.write_string(';\n')
		}
		BlockStmt {
			t.indent()
			t.output.write_string('{\n')
			t.indent_level++
			for s in stmt.statements {
				t.visit_stmt(s)
			}
			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
		}
		ClassStmt {
			t.indent()
			t.output.write_string('class ')
			t.output.write_string(stmt.name.lexeme)
			t.output.write_string(' {\n')
			t.indent_level++

			for method in stmt.methods {
				t.indent()
				name := if method.name.lexeme == 'init' { 'constructor' } else { method.name.lexeme }
				t.output.write_string(name)
				t.output.write_string('(')
				for i, param in method.params {
					if i > 0 {
						t.output.write_string(', ')
					}
					t.output.write_string(param.lexeme)
				}
				t.output.write_string(') {\n')
				t.indent_level++
				for s in method.body {
					t.visit_stmt(s)
				}
				t.indent_level--
				t.indent()
				t.output.write_string('}\n')
			}

			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
		}
		StructStmt {
			t.indent()
			t.output.write_string('class ')
			t.output.write_string(stmt.name.lexeme)
			t.output.write_string(' {\n')
			t.indent_level++
			t.indent()
			t.output.write_string('constructor(init = {}) {\n')
			t.indent_level++
			for field in stmt.fields {
				t.indent()
				t.output.write_string('this.')
				t.output.write_string(field.name.lexeme)
				t.output.write_string(' = init.')
				t.output.write_string(field.name.lexeme)
				t.output.write_string(' !== undefined ? init.')
				t.output.write_string(field.name.lexeme)
				t.output.write_string(' : ')
				if init := field.initializer {
					t.visit_expr(init)
				} else {
					t.output.write_string('null')
				}
				t.output.write_string(';\n')
			}
			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
		}
		EnumStmt {
			t.indent()
			t.output.write_string('const ')
			t.output.write_string(stmt.name.lexeme)
			t.output.write_string(' = {\n')
			t.indent_level++
			for variant in stmt.variants {
				t.indent()
				t.output.write_string(variant.name.lexeme)
				t.output.write_string(': "')
				t.output.write_string(variant.name.lexeme)
				t.output.write_string('",\n')
			}
			t.indent_level--
			t.indent()
			t.output.write_string('};\n')
		}
		ImportStmt {
			// Generate CommonJS require or ES import
			// Importing 'path' as 'alias'
			t.indent()
			if alias := stmt.alias {
				t.output.write_string('const ')
				t.output.write_string(alias.lexeme)
				t.output.write_string(' = ')
			} else {
				// No alias, side effect only? Or default name?
				// JS require is usually const X = require...
				// For now just require
			}
			if stmt.path.literal == 'core/json.vs' {
				// Special case for native JSON
				// Parent block already printed 'const alias = ' if alias existed
				// Wait, parent block lines 246-250 print 'const alias = '
				// So here we should just print 'JSON;\n'?
				// No, the parent block logic logic prints "const alias = " THEN prints require.
				// My previous edit inserted the check AFTER the parent printing.

				// Currently:
				// t.indent()
				// if alias { print "const alias = " }
				// if path == json { print "const alias = JSON;" return }

				// Fix: Just print "JSON;\n" if alias was present, otherwise handle weird case.
				// Actually cleaner to rewrite the whole ImportStmt block to be aware of special paths first.
				t.output.write_string('JSON;\n')
				return
			}

			t.output.write_string('require("')
			t.output.write_string(stmt.path.literal)
			t.output.write_string('");\n')
		}
	}
}

fn (mut t Transpiler) visit_expr(expr Expr) {
	match expr {
		BinaryExpr {
			t.output.write_string('(')
			t.visit_expr(expr.left)
			t.output.write_string(' ${expr.operator.lexeme} ')
			t.visit_expr(expr.right)
			t.output.write_string(')')
		}
		UnaryExpr {
			t.output.write_string('(')
			t.output.write_string(expr.operator.lexeme)
			t.visit_expr(expr.right)
			t.output.write_string(')')
		}
		PostfixExpr {
			t.visit_expr(expr.left)
			t.output.write_string(expr.operator.lexeme)
		}
		LiteralExpr {
			if expr.type_ == .string {
				t.output.write_string('"')
				t.output.write_string(expr.value)
				t.output.write_string('"')
			} else {
				t.output.write_string(expr.value)
			}
		}
		GroupingExpr {
			t.output.write_string('(')
			t.visit_expr(expr.expression)
			t.output.write_string(')')
		}
		VariableExpr {
			t.output.write_string(expr.name.lexeme)
		}
		AssignExpr {
			t.output.write_string(expr.name.lexeme)
			t.output.write_string(' = ')
			t.visit_expr(expr.value)
		}
		CallExpr {
			// Handle method intercepts
			if expr.callee is GetExpr {
				if expr.callee.name.lexeme == 'keys' {
					t.output.write_string('Object.keys(')
					t.visit_expr(expr.callee.object)
					t.output.write_string(')')
					return
				}
			}

			// Handle built-ins
			if expr.callee is VariableExpr {
				if expr.callee.name.lexeme == 'println' || expr.callee.name.lexeme == 'print' {
					t.output.write_string('console.log(')
					for i, arg in expr.arguments {
						if i > 0 {
							t.output.write_string(', ')
						}
						t.visit_expr(arg)
					}
					t.output.write_string(')')
					return
				}
			}

			t.visit_expr(expr.callee)
			t.output.write_string('(')
			for i, arg in expr.arguments {
				if i > 0 {
					t.output.write_string(', ')
				}
				t.visit_expr(arg)
			}
			t.output.write_string(')')
		}
		ArrayExpr {
			t.output.write_string('[')
			for i, element in expr.elements {
				if i > 0 {
					t.output.write_string(', ')
				}
				t.visit_expr(element)
			}
			t.output.write_string(']')
		}
		MapExpr {
			t.output.write_string('{')
			for i in 0 .. expr.keys.len {
				if i > 0 {
					t.output.write_string(', ')
				}
				t.visit_expr(expr.keys[i])
				t.output.write_string(': ')
				t.visit_expr(expr.values[i])
			}
			t.output.write_string('}')
		}
		IndexExpr {
			t.visit_expr(expr.object)
			t.output.write_string('[')
			t.visit_expr(expr.index)
			t.output.write_string(']')
		}
		AssignIndexExpr {
			t.visit_expr(expr.object)
			t.output.write_string('[')
			t.visit_expr(expr.index)
			t.output.write_string('] = ')
			t.visit_expr(expr.value)
		}
		FunctionExpr {
			if expr.is_async {
				t.output.write_string('async ')
			}
			t.output.write_string('function(')
			for i, param in expr.params {
				if i > 0 {
					t.output.write_string(', ')
				}
				t.output.write_string(param.lexeme)
			}
			t.output.write_string(') {\n')
			t.indent_level++
			for s in expr.body {
				t.visit_stmt(s)
			}
			t.indent_level--
			t.indent()
			t.output.write_string('}')
		}
		GetExpr {
			t.visit_expr(expr.object)
			if expr.name.lexeme == 'len' {
				t.output.write_string('.length')
			} else {
				t.output.write_string('.')
				t.output.write_string(expr.name.lexeme)
			}
		}
		SetExpr {
			t.visit_expr(expr.object)
			t.output.write_string('.')
			t.output.write_string(expr.name.lexeme)
			t.output.write_string(' = ')
			t.visit_expr(expr.value)
		}
		ThisExpr {
			t.output.write_string('this')
		}
		MatchExpr {
			// Transpile match expression as an IIFE with switch
			// (() => { switch(target) { case ... return ... } })()
			t.output.write_string('(() => {\n')
			t.indent_level++
			t.indent()
			t.output.write_string('switch (')
			t.visit_expr(expr.target)
			t.output.write_string(') {\n')
			t.indent_level++

			for arm in expr.arms {
				t.indent()
				match arm.pattern {
					LiteralPattern {
						t.output.write_string('case ')
						t.visit_expr(arm.pattern.value)
						t.output.write_string(': ')
					}
					VariantPattern {
						// For now assuming enums are strings or objects with toString/value
						// In JS output for simple string enums:
						t.output.write_string('case ')
						if enum_name := arm.pattern.enum_name {
							t.output.write_string(enum_name.lexeme)
							t.output.write_string('.')
						}
						t.output.write_string(arm.pattern.variant.lexeme)
						t.output.write_string(': ')
					}
					IdentifierPattern {
						// Catch-all/Default
						t.output.write_string('default: ')
					}
				}

				t.output.write_string('return ')
				t.visit_expr(arm.body)
				t.output.write_string(';\n')
			}

			t.indent_level--
			t.indent()
			t.output.write_string('}\n')
			t.indent_level--
			t.indent()
			t.output.write_string('})()')
		}
		AwaitExpr {
			t.output.write_string('(await ')
			t.visit_expr(expr.value)
			t.output.write_string(')')
		}
		InterpolatedStringExpr {
			t.output.write_string('`')
			for i, part in expr.parts {
				if i % 2 == 0 {
					// Literal string part
					if part is LiteralExpr {
						t.output.write_string((part as LiteralExpr).value)
					}
				} else {
					// Expression part
					t.output.write_string('${')
					t.visit_expr(part)
					t.output.write_string('}')
				}
			}
			t.output.write_string('`')
		}
		LogicalExpr {
			t.output.write_string('(')
			t.visit_expr(expr.left)
			op := if expr.operator.type_ in [.and_keyword, .ampersand_ampersand] {
				'&&'
			} else {
				'||'
			}
			t.output.write_string(' ${op} ')
			t.visit_expr(expr.right)
			t.output.write_string(')')
		}
	}
}

fn (mut t Transpiler) indent() {
	for _ in 0 .. t.indent_level {
		t.output.write_string('  ')
	}
}
