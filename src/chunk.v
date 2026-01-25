// Bytecode chunk representation
module main

struct Chunk {
mut:
	code      []u8    // Bytecode instructions
	constants []Value // Constant pool
	lines     []int   // Line numbers for debugging
}

fn new_chunk() Chunk {
	return Chunk{
		code:      []u8{cap: 256}
		constants: []Value{cap: 64}
		lines:     []int{cap: 256}
	}
}

fn (mut c Chunk) write(byte u8, line int) {
	c.code << byte
	c.lines << line
}

fn (mut c Chunk) add_constant(value Value) u8 {
	c.constants << value
	return u8(c.constants.len - 1)
}

fn (c &Chunk) disassemble(name string) {
	println('== ${name} ==')
	for i := 0; i < c.code.len; {
		i = c.disassemble_instruction(i)
	}
}

fn (c &Chunk) disassemble_instruction(offset int) int {
	print('${offset:04} ')

	if offset > 0 && c.lines[offset] == c.lines[offset - 1] {
		print('   | ')
	} else {
		print('${c.lines[offset]:4} ')
	}

	instruction := unsafe { OpCode(c.code[offset]) }

	return match instruction {
		.op_constant {
			c.constant_instruction('OP_CONSTANT', offset)
		}
		.op_negate, .op_add, .op_subtract, .op_multiply, .op_divide, .op_modulo, .op_nil, .op_true,
		.op_false, .op_not, .op_equal, .op_greater, .op_less, .op_pop, .op_print,
		.op_close_upvalue, .op_return, .op_index_get, .op_index_set {
			c.simple_instruction(instruction.str(), offset)
		}
		.op_get_local, .op_set_local, .op_call, .op_build_array, .op_get_upvalue, .op_set_upvalue {
			c.byte_instruction(instruction.str(), offset)
		}
		.op_get_global, .op_set_global {
			c.constant_instruction(instruction.str(), offset)
		}
		.op_jump, .op_jump_if_false {
			c.jump_instruction(instruction.str(), 1, offset)
		}
		.op_loop {
			c.jump_instruction(instruction.str(), -1, offset)
		}
		.op_closure {
			mut o := offset + 1
			constant := c.code[o]
			o++
			print('${offset:04d} OP_CLOSURE      ${constant:4} ')
			println(value_to_string(c.constants[constant]))

			val := c.constants[constant]
			if val is FunctionValue {
				for _ in 0 .. val.upvalues_count {
					is_local := c.code[o] == 1
					o++
					index := c.code[o]
					o++
					println('${o - 2:04d}      |                     ${if is_local {
						'local'
					} else {
						'upvalue'
					}} ${index}')
				}
			}
			return o
		}
	}
}

fn (c &Chunk) simple_instruction(name string, offset int) int {
	println(name)
	return offset + 1
}

fn (c &Chunk) constant_instruction(name string, offset int) int {
	constant := c.code[offset + 1]
	print('${name:-16} ${constant:4} ')
	println(value_to_string(c.constants[constant]))
	return offset + 2
}

fn (c &Chunk) byte_instruction(name string, offset int) int {
	slot := c.code[offset + 1]
	println('${name:-16} ${slot:4}')
	return offset + 2
}

fn (c &Chunk) jump_instruction(name string, sign int, offset int) int {
	jump := (u16(c.code[offset + 1]) << 8) | u16(c.code[offset + 2])
	println('${name:-16} ${offset:4} -> ${offset + 3 + sign * jump}')
	return offset + 3
}
