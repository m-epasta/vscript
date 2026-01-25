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
		StructStmt, EnumStmt {
			// TODO: Implement JS transpilation for static data
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
			t.output.write_string('.')
			t.output.write_string(expr.name.lexeme)
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
	}
}

fn (mut t Transpiler) indent() {
	for _ in 0 .. t.indent_level {
		t.output.write_string('  ')
	}
}
