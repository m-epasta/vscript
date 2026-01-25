// Light-speed Bytecode VM with Closure Support
module main

import math

const stack_max = 256

struct CallFrame {
mut:
	closure &ClosureValue
	ip      int
	slots   int
}

struct VM {
mut:
	frames        []CallFrame
	frame_count   int
	stack         []Value
	stack_top     int
	globals       map[string]Value
	open_upvalues []&Upvalue
}

enum InterpretResult {
	ok
	compile_error
	runtime_error
}

fn new_vm() VM {
	unsafe {
		dummy_chunk := &Chunk{
			code:      []u8{cap: 32}
			constants: []Value{cap: 8}
			lines:     []int{cap: 32}
		}
		dummy_fn := &FunctionValue{
			arity:          0
			upvalues_count: 0
			chunk:          dummy_chunk
			name:           'dummy'
		}
		dummy_closure := &ClosureValue{
			function: dummy_fn
			upvalues: []&Upvalue{}
		}

		mut vm := VM{
			frames:        []CallFrame{len: 64, init: CallFrame{
				closure: dummy_closure
			}}
			frame_count:   0
			stack:         []Value{len: stack_max, init: NilValue{}}
			stack_top:     0
			globals:       map[string]Value{}
			open_upvalues: []&Upvalue{}
		}
		for i in 0 .. 64 {
			vm.frames[i].closure = dummy_closure
		}
		vm.register_stdlib()
		return vm
	}
}

fn (mut vm VM) interpret(source string) InterpretResult {
	mut scanner := new_scanner(source)
	tokens := scanner.scan_tokens()

	mut parser := new_parser(tokens)
	stmts := parser.parse() or {
		eprintln('Parse error: ${err}')
		return .compile_error
	}

	mut compiler := new_compiler(none, .type_script)
	mut function := compiler.compile(stmts) or { return .compile_error }

	// Wrap script in a closure
	mut fn_ptr := &function
	mut closure := &ClosureValue{
		function: fn_ptr
		upvalues: []&Upvalue{}
	}

	vm.push(Value(*closure))
	vm.call_closure(closure, 0) or { return .runtime_error }

	return vm.run(0)
}

fn (mut vm VM) run(target_frame_count int) InterpretResult {
	for vm.frame_count > target_frame_count {
		frame_idx := vm.frame_count - 1
		mut frame := &vm.frames[frame_idx]

		$if debug ? {
			print('          ')
			for i := 0; i < vm.stack_top; i++ {
				print('[ ${value_to_string(vm.stack[i])} ]')
			}
			println('')
			frame.closure.function.chunk.disassemble_instruction(frame.ip)
		}

		instruction := unsafe { OpCode(frame.closure.function.chunk.code[frame.ip]) }
		frame.ip++

		match instruction {
			.op_constant {
				constant := vm.read_constant(frame_idx)
				vm.push(constant)
			}
			.op_nil {
				vm.push(NilValue{})
			}
			.op_true {
				vm.push(true)
			}
			.op_false {
				vm.push(false)
			}
			.op_pop {
				vm.pop()
			}
			.op_get_local {
				slot := vm.read_byte(frame_idx)
				vm.push(vm.stack[frame.slots + int(slot)])
			}
			.op_set_local {
				slot := vm.read_byte(frame_idx)
				vm.stack[frame.slots + int(slot)] = vm.peek(0)
			}
			.op_get_global {
				name := vm.read_constant(frame_idx)
				if name is string {
					if val := vm.globals[name] {
						vm.push(val)
					} else {
						vm.runtime_error('Undefined variable "${name}"')
						return .runtime_error
					}
				}
			}
			.op_set_global {
				name := vm.read_constant(frame_idx)
				if name is string {
					vm.globals[name] = vm.peek(0)
					vm.pop()
				}
			}
			.op_equal {
				b := vm.pop()
				a := vm.pop()
				vm.push(Value(values_equal(a, b)))
			}
			.op_greater {
				vm.binary_op_bool(fn (a f64, b f64) bool {
					return a > b
				}) or { return .runtime_error }
			}
			.op_less {
				vm.binary_op_bool(fn (a f64, b f64) bool {
					return a < b
				}) or { return .runtime_error }
			}
			.op_add {
				b := vm.pop()
				a := vm.pop()
				if a is f64 && b is f64 {
					vm.push(Value(a + b))
				} else if a is string && b is string {
					vm.push(Value(a + b))
				} else {
					vm.runtime_error('Operands must be two numbers or two strings')
					return .runtime_error
				}
			}
			.op_subtract {
				vm.binary_op(fn (a f64, b f64) f64 {
					return a - b
				}) or { return .runtime_error }
			}
			.op_multiply {
				vm.binary_op(fn (a f64, b f64) f64 {
					return a * b
				}) or { return .runtime_error }
			}
			.op_divide {
				vm.binary_op(fn (a f64, b f64) f64 {
					return a / b
				}) or { return .runtime_error }
			}
			.op_modulo {
				vm.binary_op(fn (a f64, b f64) f64 {
					return math.fmod(a, b)
				}) or { return .runtime_error }
			}
			.op_not {
				vm.push(Value(is_falsey(vm.pop())))
			}
			.op_negate {
				v := vm.pop()
				if v is f64 {
					res := -v
					vm.push(Value(res))
				} else {
					vm.runtime_error('Operand must be a number')
					return .runtime_error
				}
			}
			.op_jump {
				offset := vm.read_short(frame_idx)
				frame.ip += int(offset)
			}
			.op_jump_if_false {
				offset := vm.read_short(frame_idx)
				if is_falsey(vm.peek(0)) {
					frame.ip += int(offset)
				}
			}
			.op_loop {
				offset := vm.read_short(frame_idx)
				frame.ip -= int(offset)
			}
			.op_call {
				arg_count := vm.read_byte(frame_idx)
				if !vm.call_value(vm.peek(int(arg_count)), int(arg_count)) {
					return .runtime_error
				}
			}
			.op_closure {
				function := vm.read_constant(frame_idx)
				if function is FunctionValue {
					mut closure := &ClosureValue{
						function: &function
						upvalues: []&Upvalue{}
					}
					for _ in 0 .. function.upvalues_count {
						is_local := vm.read_byte(frame_idx) == 1
						index := vm.read_byte(frame_idx)
						if is_local {
							closure.upvalues << vm.capture_upvalue(frame.slots + int(index))
						} else {
							closure.upvalues << frame.closure.upvalues[index]
						}
					}
					vm.push(Value(*closure))
				}
			}
			.op_get_upvalue {
				slot := vm.read_byte(frame_idx)
				vm.push(*frame.closure.upvalues[slot].value)
			}
			.op_set_upvalue {
				slot := vm.read_byte(frame_idx)
				unsafe {
					*frame.closure.upvalues[slot].value = vm.peek(0)
				}
			}
			.op_close_upvalue {
				vm.close_upvalues(vm.stack_top - 1)
				vm.pop()
			}
			.op_return {
				result := vm.pop()
				vm.close_upvalues(frame.slots)
				vm.frame_count--
				if vm.frame_count <= target_frame_count {
					vm.stack_top = frame.slots
					vm.push(result)
					return .ok
				}
				vm.stack_top = frame.slots
				vm.push(result)
			}
			.op_print {
				println(value_to_string(vm.pop()))
			}
			.op_build_array {
				arg_count := vm.read_byte(frame_idx)
				mut elements := []Value{cap: int(arg_count)}
				for i := 0; i < int(arg_count); i++ {
					elements << vm.peek(int(arg_count) - 1 - i)
				}
				for _ in 0 .. int(arg_count) {
					vm.pop()
				}
				vm.push(Value(ArrayValue{ elements: elements }))
			}
			.op_build_map {
				pair_count := vm.read_byte(frame_idx)
				mut items := map[string]Value{}
				for i := 0; i < int(pair_count); i++ {
					val := vm.pop()
					key_val := vm.pop()
					if key_val is string {
						items[key_val as string] = val
					}
				}
				vm.push(Value(MapValue{ items: items }))
			}
			.op_index_get {
				index := vm.pop()
				object := vm.pop()
				if object is ArrayValue {
					if index is f64 {
						idx := int(index)
						if idx >= 0 && idx < object.elements.len {
							vm.push(object.elements[idx])
						} else {
							vm.runtime_error('Array index out of bounds')
							return .runtime_error
						}
					} else {
						vm.runtime_error('Array index must be a number')
						return .runtime_error
					}
				} else if object is MapValue {
					if index is string {
						key := index as string
						vm.push(object.items[key] or { Value(NilValue{}) })
					} else {
						vm.runtime_error('Map index must be a string')
						return .runtime_error
					}
				} else {
					vm.runtime_error('Can only index arrays or maps')
					return .runtime_error
				}
			}
			.op_index_set {
				value := vm.pop()
				index := vm.pop()
				mut object := vm.pop()
				if mut object is ArrayValue {
					if index is f64 {
						idx := int(index)
						if idx >= 0 && idx < object.elements.len {
							object.elements[idx] = value
							vm.push(value)
						} else {
							vm.runtime_error('Array index out of bounds')
							return .runtime_error
						}
					} else {
						vm.runtime_error('Array index must be a number')
						return .runtime_error
					}
				} else if mut object is MapValue {
					if index is string {
						key := index as string
						object.items[key] = value
						vm.push(value)
					} else {
						vm.runtime_error('Map index must be a string')
						return .runtime_error
					}
				} else {
					vm.runtime_error('Can only index arrays or maps')
					return .runtime_error
				}
			}
		}
	}
	return .ok
}

fn (mut vm VM) capture_upvalue(local_idx int) &Upvalue {
	for uv in vm.open_upvalues {
		if uv.location_idx == local_idx {
			unsafe {
				return uv
			}
		}
	}

	mut created_upvalue := &Upvalue{
		value:        &vm.stack[local_idx]
		location_idx: local_idx
		is_closed:    false
	}
	vm.open_upvalues << created_upvalue
	return created_upvalue
}

fn (mut vm VM) close_upvalues(last_slot int) {
	for i := vm.open_upvalues.len - 1; i >= 0; i-- {
		mut uv := vm.open_upvalues[i]
		if uv.location_idx >= last_slot {
			unsafe {
				uv.closed = *uv.value
				uv.value = &uv.closed
				uv.is_closed = true
			}
			vm.open_upvalues.delete(i)
		}
	}
}

fn (mut vm VM) call_value(callee Value, arg_count int) bool {
	match callee {
		ClosureValue {
			vm.call_closure(&callee, arg_count) or { return false }
			return true
		}
		NativeFunctionValue {
			if callee.arity != -1 && arg_count != callee.arity {
				vm.runtime_error('Expected ${callee.arity} arguments but got ${arg_count}')
				return false
			}

			mut args := []Value{cap: arg_count}
			for i := 0; i < arg_count; i++ {
				args << vm.peek(arg_count - 1 - i)
			}

			result := callee.func(mut vm, args)

			// Pop the function and arguments
			for _ in 0 .. arg_count + 1 {
				vm.pop()
			}

			vm.push(result)
			return true
		}
		FunctionValue {
			mut closure := &ClosureValue{
				function: &callee
				upvalues: []&Upvalue{}
			}
			vm.call_closure(closure, arg_count) or { return false }
			return true
		}
		else {
			vm.runtime_error('Can only call functions')
			return false
		}
	}
}

fn (mut vm VM) call_closure(closure &ClosureValue, arg_count int) ! {
	if arg_count != closure.function.arity {
		vm.runtime_error('Expected ${closure.function.arity} arguments but got ${arg_count}')
		return error('Arity mismatch')
	}

	if vm.frame_count == 64 {
		vm.runtime_error('Stack overflow')
		return error('Stack overflow')
	}

	mut frame := &vm.frames[vm.frame_count]
	vm.frame_count++
	unsafe {
		frame.closure = closure
	}
	frame.ip = 0
	frame.slots = vm.stack_top - arg_count - 1
}

fn (mut vm VM) binary_op(op fn (f64, f64) f64) ! {
	b := vm.pop()
	a := vm.pop()
	if a is f64 && b is f64 {
		res := op(a, b)
		vm.push(Value(res))
		return
	}
	vm.runtime_error('Operands must be numbers')
	return error('Type mismatch')
}

fn (mut vm VM) binary_op_bool(op fn (f64, f64) bool) ! {
	b := vm.pop()
	a := vm.pop()
	if a is f64 && b is f64 {
		res := op(a, b)
		vm.push(Value(res))
		return
	}
	vm.runtime_error('Operands must be numbers')
	return error('Type mismatch')
}

@[inline]
fn (mut vm VM) read_byte(frame_idx int) u8 {
	mut frame := &vm.frames[frame_idx]
	byte := frame.closure.function.chunk.code[frame.ip]
	frame.ip++
	return byte
}

@[inline]
fn (mut vm VM) read_short(frame_idx int) u16 {
	mut frame := &vm.frames[frame_idx]
	high := u16(frame.closure.function.chunk.code[frame.ip])
	low := u16(frame.closure.function.chunk.code[frame.ip + 1])
	frame.ip += 2
	return (high << 8) | low
}

@[inline]
fn (mut vm VM) read_constant(frame_idx int) Value {
	return vm.frames[frame_idx].closure.function.chunk.constants[vm.read_byte(frame_idx)]
}

@[inline]
fn (mut vm VM) push(value Value) {
	vm.stack[vm.stack_top] = value
	vm.stack_top++
}

@[inline]
fn (mut vm VM) pop() Value {
	vm.stack_top--
	return vm.stack[vm.stack_top]
}

@[inline]
fn (vm &VM) peek(distance int) Value {
	return vm.stack[vm.stack_top - 1 - distance]
}

fn (mut vm VM) define_native(name string, arity int, func NativeFn) {
	vm.globals[name] = Value(NativeFunctionValue{
		name:  name
		arity: arity
		func:  func
	})
}

fn (vm &VM) runtime_error(message string) {
	eprintln('Runtime error: ${message}')
}
