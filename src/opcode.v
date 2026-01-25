// Bytecode operation codes for vscript VM
module main

enum OpCode {
	// Constants
	op_constant
	op_nil
	op_true
	op_false

	// Arithmetic
	op_add
	op_subtract
	op_multiply
	op_divide
	op_modulo
	op_negate

	// Comparison
	op_equal
	op_greater
	op_less
	op_not

	// Variables
	op_get_global
	op_set_global
	op_get_local
	op_set_local

	// Control flow
	op_jump
	op_jump_if_false
	op_loop
	op_call
	op_return

	// Stack
	op_pop
	op_print

	// Arrays
	op_build_array
	op_index_get
	op_index_set

	// Closures
	op_closure
	op_get_upvalue
	op_set_upvalue
	op_close_upvalue
}

fn (op OpCode) str() string {
	return match op {
		.op_constant { 'OP_CONSTANT' }
		.op_nil { 'OP_NIL' }
		.op_true { 'OP_TRUE' }
		.op_false { 'OP_FALSE' }
		.op_add { 'OP_ADD' }
		.op_subtract { 'OP_SUBTRACT' }
		.op_multiply { 'OP_MULTIPLY' }
		.op_divide { 'OP_DIVIDE' }
		.op_modulo { 'OP_MODULO' }
		.op_negate { 'OP_NEGATE' }
		.op_equal { 'OP_EQUAL' }
		.op_greater { 'OP_GREATER' }
		.op_less { 'OP_LESS' }
		.op_not { 'OP_NOT' }
		.op_get_global { 'OP_GET_GLOBAL' }
		.op_set_global { 'OP_SET_GLOBAL' }
		.op_get_local { 'OP_GET_LOCAL' }
		.op_set_local { 'OP_SET_LOCAL' }
		.op_jump { 'OP_JUMP' }
		.op_jump_if_false { 'OP_JUMP_IF_FALSE' }
		.op_loop { 'OP_LOOP' }
		.op_call { 'OP_CALL' }
		.op_return { 'OP_RETURN' }
		.op_pop { 'OP_POP' }
		.op_print { 'OP_PRINT' }
		.op_build_array { 'OP_BUILD_ARRAY' }
		.op_index_get { 'OP_INDEX_GET' }
		.op_index_set { 'OP_INDEX_SET' }
		.op_closure { 'OP_CLOSURE' }
		.op_get_upvalue { 'OP_GET_UPVALUE' }
		.op_set_upvalue { 'OP_SET_UPVALUE' }
		.op_close_upvalue { 'OP_CLOSE_UPVALUE' }
	}
}
