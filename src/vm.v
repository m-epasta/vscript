// Light-speed Bytecode VM with Closure Support
module main

import math

const stack_max = 256

enum InterpretResult {
	ok
	compile_error
	runtime_error
}

struct CallFrame {
mut:
	closure ClosureValue
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

fn new_vm() VM {
	unsafe {
		dummy_chunk := &Chunk{
			code:      []u8{cap: 1}
			constants: []Value{cap: 1}
			lines:     []int{cap: 1}
		}
		dummy_fn := FunctionValue{
			arity:          0
			upvalues_count: 0
			chunk:          dummy_chunk
			name:           'dummy'
		}
		dummy_closure := ClosureValue{
			function: dummy_fn
			upvalues: []&Upvalue{}
		}

		mut frames := []CallFrame{cap: 64}
		for _ in 0 .. 64 {
			frames << CallFrame{
				closure: dummy_closure
				ip:      0
				slots:   0
			}
		}

		mut vm := VM{
			frames:        frames
			frame_count:   0
			stack:         []Value{len: stack_max, init: NilValue{}}
			stack_top:     0
			globals:       map[string]Value{}
			open_upvalues: []&Upvalue{}
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
	function := compiler.compile(stmts) or { return .compile_error }

	closure := ClosureValue{
		function: function
		upvalues: []&Upvalue{}
	}

	vm.push(Value(closure))
	vm.call_closure(closure, 0) or { return .runtime_error }

	return vm.run(0)
}

fn (mut vm VM) run(target_frame_count int) InterpretResult {
	for vm.frame_count > target_frame_count {
		f_idx := vm.frame_count - 1

		instruction := unsafe { OpCode(vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]) }
		vm.frames[f_idx].ip++

		match instruction {
			.op_constant {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				constant := vm.frames[f_idx].closure.function.chunk.constants[byte]
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
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				val := vm.stack[vm.frames[f_idx].slots + int(byte)]
				vm.push(val)
			}
			.op_set_local {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				vm.stack[vm.frames[f_idx].slots + int(byte)] = vm.peek(0)
			}
			.op_get_global {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name := vm.frames[f_idx].closure.function.chunk.constants[byte]
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
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name := vm.frames[f_idx].closure.function.chunk.constants[byte]
				if name is string {
					vm.globals[name] = vm.peek(0)
					vm.pop()
				}
			}
			.op_equal {
				b := vm.pop()
				a := vm.pop()
				vm.push(values_equal(a, b))
			}
			.op_greater {
				v_b := vm.pop()
				v_a := vm.pop()
				if v_a is f64 && v_b is f64 {
					vm.push(v_a > v_b)
				} else {
					vm.runtime_error('Operands must be numbers')
					return .runtime_error
				}
			}
			.op_less {
				v_b := vm.pop()
				v_a := vm.pop()
				if v_a is f64 && v_b is f64 {
					vm.push(v_a < v_b)
				} else {
					vm.runtime_error('Operands must be numbers')
					return .runtime_error
				}
			}
			.op_add {
				v_b := vm.pop()
				v_a := vm.pop()
				if v_a is f64 && v_b is f64 {
					vm.push(v_a + v_b)
				} else if v_a is string || v_b is string {
					vm.push(value_to_string(v_a) + value_to_string(v_b))
				} else {
					vm.runtime_error('Operands must be two numbers or two strings')
					return .runtime_error
				}
			}
			.op_subtract {
				v_b := vm.pop()
				v_a := vm.pop()
				if v_a is f64 && v_b is f64 {
					vm.push(v_a - v_b)
				} else {
					vm.runtime_error('Operands must be numbers')
					return .runtime_error
				}
			}
			.op_multiply {
				v_b := vm.pop()
				v_a := vm.pop()
				if v_a is f64 && v_b is f64 {
					vm.push(v_a * v_b)
				} else {
					vm.runtime_error('Operands must be numbers')
					return .runtime_error
				}
			}
			.op_divide {
				v_b := vm.pop()
				v_a := vm.pop()
				if v_a is f64 && v_b is f64 {
					vm.push(v_a / v_b)
				} else {
					vm.runtime_error('Operands must be numbers')
					return .runtime_error
				}
			}
			.op_modulo {
				v_b := vm.pop()
				v_a := vm.pop()
				if v_a is f64 && v_b is f64 {
					vm.push(math.fmod(v_a, v_b))
				} else {
					vm.runtime_error('Operands must be numbers')
					return .runtime_error
				}
			}
			.op_not {
				vm.push(is_falsey(vm.pop()))
			}
			.op_negate {
				v := vm.pop()
				if v is f64 {
					res := -v
					vm.push(res)
				} else {
					vm.runtime_error('Operand must be a number')
					return .runtime_error
				}
			}
			.op_jump {
				b1 := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				b2 := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip + 1]
				vm.frames[f_idx].ip += 2
				offset := (u16(b1) << 8) | u16(b2)
				vm.frames[f_idx].ip += int(offset)
			}
			.op_jump_if_false {
				b1 := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				b2 := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip + 1]
				vm.frames[f_idx].ip += 2
				offset := (u16(b1) << 8) | u16(b2)
				if is_falsey(vm.peek(0)) {
					vm.frames[f_idx].ip += int(offset)
				}
			}
			.op_loop {
				b1 := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				b2 := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip + 1]
				vm.frames[f_idx].ip += 2
				offset := (u16(b1) << 8) | u16(b2)
				vm.frames[f_idx].ip -= int(offset)
			}
			.op_call {
				arg_count := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				if !vm.call_value(vm.peek(int(arg_count)), int(arg_count)) {
					return .runtime_error
				}
			}
			.op_closure {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				constant := vm.frames[f_idx].closure.function.chunk.constants[byte]
				if constant is FunctionValue {
					func_val := constant as FunctionValue
					mut cl := ClosureValue{
						function: func_val
						upvalues: []&Upvalue{}
					}
					for _ in 0 .. func_val.upvalues_count {
						is_local := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip] == 1
						vm.frames[f_idx].ip++
						index := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
						vm.frames[f_idx].ip++
						if is_local {
							cl.upvalues << vm.capture_upvalue(vm.frames[f_idx].slots + int(index))
						} else {
							cl.upvalues << vm.frames[f_idx].closure.upvalues[index]
						}
					}
					vm.push(Value(cl))
				}
			}
			.op_get_upvalue {
				slot := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				vm.push(*vm.frames[f_idx].closure.upvalues[slot].value)
			}
			.op_set_upvalue {
				slot := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				unsafe {
					*vm.frames[f_idx].closure.upvalues[slot].value = vm.peek(0)
				}
			}
			.op_close_upvalue {
				vm.close_upvalues(vm.stack_top - 1)
				vm.pop()
			}
			.op_return {
				result := vm.pop()
				slots := vm.frames[f_idx].slots
				vm.close_upvalues(slots)
				vm.frame_count--
				if vm.frame_count <= target_frame_count {
					vm.stack_top = slots
					vm.push(result)
					return .ok
				}
				vm.stack_top = slots
				vm.push(result)
			}
			.op_build_array {
				arg_count := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				mut elements := []Value{cap: int(arg_count)}
				for i := 0; i < int(arg_count); i++ {
					elements << vm.peek(int(arg_count) - 1 - i)
				}
				for _ in 0 .. int(arg_count) {
					vm.pop()
				}
				vm.push(ArrayValue{ elements: elements })
			}
			.op_build_map {
				pair_count := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				mut items := map[string]Value{}
				for i := 0; i < int(pair_count); i++ {
					val := vm.pop()
					key_val := vm.pop()
					if key_val is string {
						items[key_val as string] = val
					}
				}
				vm.push(MapValue{ items: items })
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
							vm.push(NilValue{})
						}
					} else {
						vm.runtime_error('Array index must be a number')
						return .runtime_error
					}
				} else if object is MapValue {
					if index is string {
						key := index as string
						vm.push(object.items[key] or { NilValue{} })
					} else {
						vm.runtime_error('Map index must be a string')
						return .runtime_error
					}
				} else if object is InstanceValue {
					if index is string {
						key := index as string
						if key in object.fields {
							vm.push(object.fields[key] or { NilValue{} })
						} else if method := object.class.methods[key] {
							vm.push(BoundMethodValue{ receiver: object, method: method })
						} else {
							vm.push(NilValue{})
						}
					} else {
						vm.runtime_error('Property index must be a string')
						return .runtime_error
					}
				} else {
					vm.runtime_error('Can only index arrays, maps or instances')
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
				} else if mut object is InstanceValue {
					if index is string {
						key := index as string
						object.fields[key] = value
						vm.push(value)
					} else {
						vm.runtime_error('Property index must be a string')
						return .runtime_error
					}
				} else {
					vm.runtime_error('Can only index arrays, maps or instances')
					return .runtime_error
				}
			}
			.op_class {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name := vm.frames[f_idx].closure.function.chunk.constants[byte]
				if name is string {
					vm.push(ClassValue{
						name:    name
						methods: map[string]Value{}
					})
				}
			}
			.op_method {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name_val := vm.frames[f_idx].closure.function.chunk.constants[byte]
				if name_val is string {
					name := name_val as string
					method := vm.pop()
					// Method can be a Closure or a Native wrapper (from decorators)
					mut klass := vm.peek(0)
					if mut klass is ClassValue {
						klass.methods[name] = method
					}
				}
			}
			.op_get_property {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name_val := vm.frames[f_idx].closure.function.chunk.constants[byte]
				if name_val is string {
					name := name_val as string
					instance := vm.pop()
					if instance is InstanceValue {
						if name in instance.fields {
							vm.push(instance.fields[name] or { NilValue{} })
						} else {
							if method := instance.class.methods[name] {
								vm.push(BoundMethodValue{
									receiver: instance
									method:   method
								})
							} else {
								vm.runtime_error('Undefined property "${name}"')
								return .runtime_error
							}
						}
					} else if instance is StructInstanceValue {
						if name in instance.fields {
							vm.push(instance.fields[name] or { NilValue{} })
						} else {
							vm.runtime_error('Undefined struct field "${name}"')
							return .runtime_error
						}
					} else if instance is EnumValue {
						if name in instance.variants {
							vm.push(EnumVariantValue{
								enum_name: instance.name
								variant:   name
							})
						} else {
							vm.runtime_error('Undefined enum variant "${name}"')
							return .runtime_error
						}
					} else {
						vm.runtime_error('Only instances, structs and enums have properties. Got ${vm.typeof(instance)}')
						return .runtime_error
					}
				}
			}
			.op_set_property {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name_val := vm.frames[f_idx].closure.function.chunk.constants[byte]
				if name_val is string {
					name := name_val as string
					value := vm.pop()
					mut instance := vm.pop()
					if mut instance is InstanceValue {
						instance.fields[name] = value
						vm.push(value)
					} else if mut instance is StructInstanceValue {
						instance.fields[name] = value
						vm.push(value)
					} else {
						vm.runtime_error('Only instances and structs have fields')
						return .runtime_error
					}
				}
			}
			.op_struct {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name_val := vm.frames[f_idx].closure.function.chunk.constants[byte]
				name := if name_val is string { name_val } else { 'unknown' }
				field_count := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++

				mut sv := StructValue{
					name:           name
					field_names:    []string{cap: int(field_count)}
					field_types:    map[string]string{}
					field_defaults: map[string]Value{}
				}

				for _ in 0 .. field_count {
					f_name_idx := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
					vm.frames[f_idx].ip++
					f_type_idx := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
					vm.frames[f_idx].ip++

					f_name_val := vm.frames[f_idx].closure.function.chunk.constants[f_name_idx]
					f_type_val := vm.frames[f_idx].closure.function.chunk.constants[f_type_idx]
					f_name := if f_name_val is string { f_name_val } else { 'unknown' }
					f_type := if f_type_val is string { f_type_val } else { 'unknown' }

					sv.field_names << f_name
					sv.field_types[f_name] = f_type

					// Default value on stack
					// VM for advanced types should ideally not rely on op_nil for defaults
					// if we want to support complex expressions, but for now we'll take what's on stack
					// wait, the compiler pushes the default value!
				}

				// Fields are pushed in reverse for defaults
				for i := sv.field_names.len - 1; i >= 0; i-- {
					f_name := sv.field_names[i]
					sv.field_defaults[f_name] = vm.pop()
				}

				vm.push(sv)
			}
			.op_enum {
				byte := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++
				name_val := vm.frames[f_idx].closure.function.chunk.constants[byte]
				name := if name_val is string { name_val } else { 'unknown' }
				variant_count := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
				vm.frames[f_idx].ip++

				mut ev := EnumValue{
					name:     name
					variants: []string{cap: int(variant_count)}
				}

				for _ in 0 .. variant_count {
					v_name_idx := vm.frames[f_idx].closure.function.chunk.code[vm.frames[f_idx].ip]
					vm.frames[f_idx].ip++
					v_name_val := vm.frames[f_idx].closure.function.chunk.constants[v_name_idx]
					v_name := if v_name_val is string { v_name_val } else { 'unknown' }
					ev.variants << v_name
				}
				vm.push(ev)
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
			vm.call_closure(callee, arg_count) or { return false }
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

			for _ in 0 .. arg_count + 1 {
				vm.pop()
			}

			vm.push(result)
			return true
		}
		FunctionValue {
			closure := ClosureValue{
				function: callee
				upvalues: []&Upvalue{}
			}
			vm.call_closure(closure, arg_count) or { return false }
			return true
		}
		ClassValue {
			slot := vm.stack_top - arg_count - 1
			vm.stack[slot] = InstanceValue{
				class:  callee
				fields: map[string]Value{}
			}

			if initializer := callee.methods['init'] {
				return vm.call_value(initializer, arg_count)
			} else if arg_count != 0 {
				vm.runtime_error('Expected 0 arguments but got ${arg_count}')
				return false
			}
			return true
		}
		StructValue {
			if arg_count != 0 {
				vm.runtime_error('Struct constructors take 0 arguments for now (use fields)')
				return false
			}
			slot := vm.stack_top - 1
			mut fields := map[string]Value{}
			for k, v in callee.field_defaults {
				fields[k] = v
			}
			vm.stack[slot] = StructInstanceValue{
				struct_type: callee
				fields:      fields
			}
			return true
		}
		BoundMethodValue {
			vm.stack[vm.stack_top - arg_count - 1] = callee.receiver
			return vm.call_value(callee.method, arg_count)
		}
		else {
			vm.runtime_error('Can only call functions and classes')
			return false
		}
	}
}

fn (mut vm VM) call_closure(closure ClosureValue, arg_count int) ! {
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
	frame.closure = closure
	frame.ip = 0
	frame.slots = vm.stack_top - arg_count - 1
}

fn (mut vm VM) push(val Value) {
	if vm.stack_top >= stack_max {
		vm.runtime_error('Stack overflow')
		return
	}
	vm.stack[vm.stack_top] = val
	vm.stack_top++
}

fn (mut vm VM) pop() Value {
	vm.stack_top--
	return vm.stack[vm.stack_top]
}

fn (vm &VM) peek(distance int) Value {
	return vm.stack[vm.stack_top - 1 - distance]
}

fn (mut vm VM) define_native(name string, arity int, func NativeFn) {
	vm.globals[name] = NativeFunctionValue{
		name:  name
		arity: arity
		func:  func
	}
}

fn (vm &VM) typeof(val Value) string {
	return match val {
		f64 { 'number' }
		bool { 'boolean' }
		string { 'string' }
		NilValue { 'nil' }
		FunctionValue, ClosureValue, NativeFunctionValue { 'function' }
		ArrayValue { 'array' }
		MapValue { 'map' }
		ClassValue { 'class' }
		InstanceValue { 'instance' }
		StructValue { 'struct_type' }
		StructInstanceValue { 'struct' }
		EnumValue { 'enum_type' }
		EnumVariantValue { 'enum_variant' }
		BoundMethodValue { 'function' }
	}
}

fn (vm &VM) runtime_error(message string) {
	eprintln('Runtime error: ${message}')
}
