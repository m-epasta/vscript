// Bytecode compiler - compiles AST to bytecode
module main

enum FunctionType {
	type_script
	type_function
}

enum ClassType {
	type_none
	type_class
}

struct UpvalueMetadata {
mut:
	index    int
	is_local bool
}

struct Compiler {
mut:
	enclosing     ?&Compiler
	function_type FunctionType
	upvalues      []UpvalueMetadata
	chunk         &Chunk
	locals        []Local
	local_count   int
	scope_depth   int
	class_type    ClassType
}

struct Local {
	name  string
	depth int
}

fn new_compiler(enclosing ?&Compiler, type_ FunctionType) Compiler {
	// Allocate chunk on heap to ensure pointer remains valid
	unsafe {
		chunk := &Chunk{
			code:      []u8{cap: 256}
			constants: []Value{cap: 64}
			lines:     []int{cap: 256}
		}
		return Compiler{
			enclosing:     enclosing
			function_type: type_
			upvalues:      []UpvalueMetadata{cap: 64}
			chunk:         chunk
			locals:        []Local{len: 256}
			local_count:   0
			scope_depth:   0
			class_type:    if enclosing != none { enclosing.class_type } else { .type_none }
		}
	}
}

fn (mut c Compiler) compile(stmts []Stmt) !FunctionValue {
	for stmt in stmts {
		c.compile_stmt(stmt)!
	}

	c.emit_byte(u8(OpCode.op_nil))
	c.emit_byte(u8(OpCode.op_return))

	$if debug ? {
		c.chunk.disassemble('script')
	}

	return FunctionValue{
		arity: 0
		chunk: c.chunk
		name:  'script'
	}
}

fn (mut c Compiler) compile_stmt(stmt Stmt) ! {
	match stmt {
		FunctionStmt {
			c.function(stmt)!
		}
		ExprStmt {
			c.compile_expr(stmt.expression)!
			c.emit_byte(u8(OpCode.op_pop))
		}
		VarStmt {
			c.compile_expr(stmt.initializer)!

			if c.scope_depth > 0 {
				c.add_local(stmt.name.lexeme)
			} else {
				name_const := c.make_constant(Value(stmt.name.lexeme))
				c.emit_bytes(u8(OpCode.op_set_global), name_const)
			}
		}
		IfStmt {
			c.compile_expr(stmt.condition)!

			then_jump := c.emit_jump(u8(OpCode.op_jump_if_false))
			c.emit_byte(u8(OpCode.op_pop))
			c.compile_stmt(stmt.then_branch)!

			else_jump := c.emit_jump(u8(OpCode.op_jump))
			c.patch_jump(then_jump)
			c.emit_byte(u8(OpCode.op_pop))

			if else_branch := stmt.else_branch {
				c.compile_stmt(else_branch)!
			}
			c.patch_jump(else_jump)
		}
		WhileStmt {
			loop_start := c.chunk.code.len
			c.compile_expr(stmt.condition)!

			exit_jump := c.emit_jump(u8(OpCode.op_jump_if_false))
			c.emit_byte(u8(OpCode.op_pop))
			c.compile_stmt(stmt.body)!
			c.emit_loop(loop_start)

			c.patch_jump(exit_jump)
			c.emit_byte(u8(OpCode.op_pop))
		}
		ForStmt {
			c.begin_scope()

			if initializer := stmt.initializer {
				c.compile_stmt(initializer)!
			}

			loop_start := c.chunk.code.len
			mut exit_jump := -1

			if condition := stmt.condition {
				c.compile_expr(condition)!
				exit_jump = c.emit_jump(u8(OpCode.op_jump_if_false))
				c.emit_byte(u8(OpCode.op_pop))
			}

			if increment := stmt.increment {
				body_jump := c.emit_jump(u8(OpCode.op_jump))
				_ := c.chunk.code.len // increment start position (not needed for simple loop)
				c.compile_expr(increment)!
				c.emit_byte(u8(OpCode.op_pop))
				c.emit_loop(loop_start)
				c.patch_jump(body_jump)
			}

			c.compile_stmt(stmt.body)!
			c.emit_loop(loop_start)

			if exit_jump != -1 {
				c.patch_jump(exit_jump)
				c.emit_byte(u8(OpCode.op_pop))
			}

			c.end_scope()
		}
		ReturnStmt {
			if value := stmt.value {
				c.compile_expr(value)!
			} else {
				c.emit_byte(u8(OpCode.op_nil))
			}
			c.emit_byte(u8(OpCode.op_return))
		}
		BlockStmt {
			c.begin_scope()
			for s in stmt.statements {
				c.compile_stmt(s)!
			}
			c.end_scope()
		}
		ClassStmt {
			name_const := c.make_constant(Value(stmt.name.lexeme))
			c.emit_bytes(u8(OpCode.op_class), name_const)
			c.emit_bytes(u8(OpCode.op_set_global), name_const)

			c.named_variable(stmt.name, false)!

			old_class_type := c.class_type
			c.class_type = .type_class

			for method in stmt.methods {
				meth_name_const := c.make_constant(Value(method.name.lexeme))

				// Prepare method decorators
				for attr in method.attributes {
					if attr.name.lexeme in ['memoize', 'lru_cache'] {
						idx := c.make_constant(Value(attr.name.lexeme))
						c.emit_bytes(u8(OpCode.op_get_global), idx)
					}
				}

				c.compile_function(method.name.lexeme, method.params, method.body, .type_function)!

				// Wrap method
				for i := method.attributes.len - 1; i >= 0; i-- {
					attr := method.attributes[i]
					if attr.name.lexeme in ['memoize', 'lru_cache'] {
						mut arg_count := 1
						if val := attr.value {
							c.compile_expr(val)!
							arg_count++
						}
						c.emit_bytes(u8(OpCode.op_call), u8(arg_count))
					}
				}

				c.emit_bytes(u8(OpCode.op_method), meth_name_const)
			}

			c.emit_byte(u8(OpCode.op_pop))
			c.class_type = old_class_type
		}
		StructStmt {
			// Evaluated defaults must be on stack before op_struct
			for field in stmt.fields {
				if init := field.initializer {
					c.compile_expr(init)!
				} else {
					c.emit_byte(u8(OpCode.op_nil))
				}
			}

			name_const := c.make_constant(Value(stmt.name.lexeme))
			c.emit_bytes(u8(OpCode.op_struct), name_const)
			c.emit_byte(u8(stmt.fields.len))
			for field in stmt.fields {
				f_name_const := c.make_constant(Value(field.name.lexeme))
				f_type_const := c.make_constant(Value(field.type_name.lexeme))
				c.emit_byte(f_name_const)
				c.emit_byte(f_type_const)
			}
			// Set global
			c.emit_bytes(u8(OpCode.op_set_global), name_const)
		}
		EnumStmt {
			name_const := c.make_constant(Value(stmt.name.lexeme))
			c.emit_bytes(u8(OpCode.op_enum), name_const)
			c.emit_byte(u8(stmt.variants.len))
			for variant in stmt.variants {
				v_name_const := c.make_constant(Value(variant.name.lexeme))
				c.emit_byte(v_name_const)
			}
			// Set global
			c.emit_bytes(u8(OpCode.op_set_global), name_const)
		}
	}
}

fn (mut c Compiler) compile_expr(expr Expr) ! {
	match expr {
		BinaryExpr {
			c.compile_expr(expr.left)!
			c.compile_expr(expr.right)!

			match expr.operator.type_ {
				.plus { c.emit_byte(u8(OpCode.op_add)) }
				.minus { c.emit_byte(u8(OpCode.op_subtract)) }
				.star { c.emit_byte(u8(OpCode.op_multiply)) }
				.slash { c.emit_byte(u8(OpCode.op_divide)) }
				.percent { c.emit_byte(u8(OpCode.op_modulo)) }
				.equal_equal { c.emit_byte(u8(OpCode.op_equal)) }
				.bang_equal { c.emit_bytes(u8(OpCode.op_equal), u8(OpCode.op_not)) }
				.greater { c.emit_byte(u8(OpCode.op_greater)) }
				.greater_equal { c.emit_bytes(u8(OpCode.op_less), u8(OpCode.op_not)) }
				.less { c.emit_byte(u8(OpCode.op_less)) }
				.less_equal { c.emit_bytes(u8(OpCode.op_greater), u8(OpCode.op_not)) }
				else {}
			}
		}
		UnaryExpr {
			c.compile_expr(expr.right)!

			match expr.operator.type_ {
				.minus { c.emit_byte(u8(OpCode.op_negate)) }
				.bang { c.emit_byte(u8(OpCode.op_not)) }
				else {}
			}
		}
		LiteralExpr {
			match expr.type_ {
				.number {
					value := expr.value.f64()
					c.emit_constant(Value(value))
				}
				.string {
					c.emit_constant(Value(expr.value))
				}
				.true_keyword {
					c.emit_byte(u8(OpCode.op_true))
				}
				.false_keyword {
					c.emit_byte(u8(OpCode.op_false))
				}
				.nil_keyword {
					c.emit_byte(u8(OpCode.op_nil))
				}
				else {}
			}
		}
		GroupingExpr {
			c.compile_expr(expr.expression)!
		}
		VariableExpr {
			c.named_variable(expr.name, false)!
		}
		AssignExpr {
			c.named_variable(expr.name, true)!
			c.compile_expr(expr.value)!

			arg := c.resolve_local(expr.name.lexeme)
			if arg != -1 {
				c.emit_bytes(u8(OpCode.op_set_local), u8(arg))
			} else {
				upvalue := c.resolve_upvalue(expr.name.lexeme)
				if upvalue != -1 {
					c.emit_bytes(u8(OpCode.op_set_upvalue), u8(upvalue))
				} else {
					name_const := c.make_constant(Value(expr.name.lexeme))
					c.emit_bytes(u8(OpCode.op_set_global), name_const)
				}
			}
		}
		CallExpr {
			// Handle standard calls
			c.compile_expr(expr.callee)!
			for arg in expr.arguments {
				c.compile_expr(arg)!
			}
			c.emit_bytes(u8(OpCode.op_call), u8(expr.arguments.len))
		}
		ArrayExpr {
			for element in expr.elements {
				c.compile_expr(element)!
			}
			c.emit_bytes(u8(OpCode.op_build_array), u8(expr.elements.len))
		}
		IndexExpr {
			c.compile_expr(expr.object)!
			c.compile_expr(expr.index)!
			c.emit_byte(u8(OpCode.op_index_get))
		}
		AssignIndexExpr {
			c.compile_expr(expr.object)!
			c.compile_expr(expr.index)!
			c.compile_expr(expr.value)!
			c.emit_byte(u8(OpCode.op_index_set))
		}
		FunctionExpr {
			c.compile_function('(anonymous)', expr.params, expr.body, .type_function)!
		}
		MapExpr {
			for i in 0 .. expr.keys.len {
				c.compile_expr(expr.keys[i])!
				c.compile_expr(expr.values[i])!
			}
			c.emit_bytes(u8(OpCode.op_build_map), u8(expr.keys.len))
		}
		GetExpr {
			c.compile_expr(expr.object)!
			name_const := c.make_constant(Value(expr.name.lexeme))
			c.emit_bytes(u8(OpCode.op_get_property), name_const)
		}
		SetExpr {
			c.compile_expr(expr.object)!
			c.compile_expr(expr.value)!
			name_const := c.make_constant(Value(expr.name.lexeme))
			c.emit_bytes(u8(OpCode.op_set_property), name_const)
		}
		ThisExpr {
			if c.class_type == .type_none {
				return error("Cannot use 'this' outside of a class")
			}
			c.named_variable(Token{ type_: .this_keyword, lexeme: 'this', line: expr.keyword.line },
				false)!
		}
	}
}

fn (mut c Compiler) function(stmt FunctionStmt) ! {
	// 1. Prepare decorator wrappers if any
	mut wrap_count := 0
	for attr in stmt.attributes {
		if attr.name.lexeme in ['memoize', 'lru_cache'] {
			idx := c.make_constant(Value(attr.name.lexeme))
			c.emit_bytes(u8(OpCode.op_get_global), idx)
			wrap_count++
		}
	}

	// 2. Compile the core closure
	c.compile_function(stmt.name.lexeme, stmt.params, stmt.body, .type_function)!

	// 3. Emit wrapper calls
	// We need to apply them in reverse order of how their globals were pushed (standard stack behavior)
	for i := stmt.attributes.len - 1; i >= 0; i-- {
		attr := stmt.attributes[i]
		if attr.name.lexeme in ['memoize', 'lru_cache'] {
			mut arg_count := 1
			if val := attr.value {
				c.compile_expr(val)!
				arg_count++
			}
			c.emit_bytes(u8(OpCode.op_call), u8(arg_count))
		}
	}

	name_const := c.make_constant(Value(stmt.name.lexeme))
	c.emit_bytes(u8(OpCode.op_set_global), name_const)
}

fn (mut c Compiler) compile_function(name string, params []Token, body []Stmt, type_ FunctionType) ! {
	mut compiler := new_compiler(c, type_)

	// Reserve slot 0 for the function itself or 'this'
	compiler.locals[0] = Local{
		name:  if type_ != .type_script && c.class_type != .type_none { 'this' } else { '' }
		depth: 0
	}
	compiler.local_count++

	for param in params {
		compiler.add_local(param.lexeme)
	}

	for s in body {
		compiler.compile_stmt(s)!
	}

	if name == 'init' {
		compiler.emit_bytes(u8(OpCode.op_get_local), 0)
		compiler.emit_byte(u8(OpCode.op_return))
	} else {
		compiler.emit_return()
	}

	function := FunctionValue{
		arity:          params.len
		upvalues_count: compiler.upvalues.len
		chunk:          compiler.chunk
		name:           name
	}

	const_idx := c.make_constant(Value(function))
	c.emit_bytes(u8(OpCode.op_closure), const_idx)

	for i := 0; i < compiler.upvalues.len; i++ {
		meta := compiler.upvalues[i]
		c.emit_byte(if meta.is_local { u8(1) } else { u8(0) })
		c.emit_byte(u8(meta.index))
	}
}

fn (mut c Compiler) resolve_upvalue(name string) int {
	if mut enclosing := c.enclosing {
		// Try resolving as a local in the outer scope
		local := enclosing.resolve_local(name)
		if local != -1 {
			return c.add_upvalue(local, true)
		}

		// Try resolving recursively as an upvalue in the outer scope
		upvalue := enclosing.resolve_upvalue(name)
		if upvalue != -1 {
			return c.add_upvalue(upvalue, false)
		}
	}

	return -1
}

fn (mut c Compiler) named_variable(name Token, is_assign bool) ! {
	arg := c.resolve_local(name.lexeme)
	if arg != -1 {
		if !is_assign {
			c.emit_bytes(u8(OpCode.op_get_local), u8(arg))
		}
	} else {
		upvalue := c.resolve_upvalue(name.lexeme)
		if upvalue != -1 {
			if !is_assign {
				c.emit_bytes(u8(OpCode.op_get_upvalue), u8(upvalue))
			}
		} else {
			name_const := c.make_constant(Value(name.lexeme))
			if !is_assign {
				c.emit_bytes(u8(OpCode.op_get_global), name_const)
			}
		}
	}
}

fn (mut c Compiler) add_upvalue(index int, is_local bool) int {
	// Check if already captured
	for i, meta in c.upvalues {
		if meta.index == index && meta.is_local == is_local {
			return i
		}
	}

	c.upvalues << UpvalueMetadata{
		index:    index
		is_local: is_local
	}

	return c.upvalues.len - 1
}

fn (mut c Compiler) resolve_local(name string) int {
	for i := c.local_count - 1; i >= 0; i-- {
		if c.locals[i].name == name {
			return i
		}
	}
	return -1
}

fn (mut c Compiler) add_local(name string) {
	c.locals[c.local_count] = Local{
		name:  name
		depth: c.scope_depth
	}
	c.local_count++
}

fn (mut c Compiler) begin_scope() {
	c.scope_depth++
}

fn (mut c Compiler) end_scope() {
	c.scope_depth--

	for c.local_count > 0 && c.locals[c.local_count - 1].depth > c.scope_depth {
		c.emit_byte(u8(OpCode.op_pop))
		c.local_count--
	}
}

fn (mut c Compiler) emit_byte(byte u8) {
	c.chunk.write(byte, 0)
}

fn (mut c Compiler) emit_bytes(byte1 u8, byte2 u8) {
	c.emit_byte(byte1)
	c.emit_byte(byte2)
}

fn (mut c Compiler) emit_return() {
	c.emit_byte(u8(OpCode.op_nil))
	c.emit_byte(u8(OpCode.op_return))
}

fn (mut c Compiler) emit_constant(value Value) {
	c.emit_bytes(u8(OpCode.op_constant), c.make_constant(value))
}

fn (mut c Compiler) make_constant(value Value) u8 {
	constant := c.chunk.add_constant(value)
	if constant > 255 {
		eprintln('Too many constants in one chunk')
		return 0
	}
	return constant
}

fn (mut c Compiler) emit_jump(instruction u8) int {
	c.emit_byte(instruction)
	c.emit_byte(0xff)
	c.emit_byte(0xff)
	return c.chunk.code.len - 2
}

fn (mut c Compiler) patch_jump(offset int) {
	jump := c.chunk.code.len - offset - 2
	c.chunk.code[offset] = u8((jump >> 8) & 0xff)
	c.chunk.code[offset + 1] = u8(jump & 0xff)
}

fn (mut c Compiler) emit_loop(loop_start int) {
	c.emit_byte(u8(OpCode.op_loop))

	offset := c.chunk.code.len - loop_start + 2
	c.emit_byte(u8((offset >> 8) & 0xff))
	c.emit_byte(u8(offset & 0xff))
}
