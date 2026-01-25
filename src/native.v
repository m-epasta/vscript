// Native functions for vscript standard library
module main

import time
import math
import x.json2

fn native_clock(mut vm VM, args []Value) Value {
	return Value(f64(time.sys_mono_now()) / 1000000000.0)
}

fn native_len(mut vm VM, args []Value) Value {
	val := args[0]
	return match val {
		string { Value(f64(val.len)) }
		ArrayValue { Value(f64(val.elements.len)) }
		MapValue { Value(f64(val.items.len)) }
		else { Value(f64(0)) }
	}
}

fn native_push(mut vm VM, args []Value) Value {
	mut arr := args[0]
	if mut arr is ArrayValue {
		arr.elements << args[1]
		return args[1]
	}
	return Value(NilValue{})
}

fn native_slice(mut vm VM, args []Value) Value {
	val := args[0]
	start := if args.len > 1 && args[1] is f64 { int(args[1] as f64) } else { 0 }

	return match val {
		string {
			end := if args.len > 2 && args[2] is f64 { int(args[2] as f64) } else { val.len }
			if start < 0 || start > val.len {
				return Value('')
			}
			e := if end > val.len {
				val.len
			} else if end < start {
				start
			} else {
				end
			}
			res := val[start..e]
			return Value(res)
		}
		ArrayValue {
			end := if args.len > 2 && args[2] is f64 {
				int(args[2] as f64)
			} else {
				val.elements.len
			}
			if start < 0 || start > val.elements.len {
				return Value(ArrayValue{
					elements: []Value{}
				})
			}
			e := if end > val.elements.len {
				val.elements.len
			} else if end < start {
				start
			} else {
				end
			}
			res := val.elements[start..e].clone()
			return Value(ArrayValue{
				elements: res
			})
		}
		else {
			Value(NilValue{})
		}
	}
}

fn native_sqrt(mut vm VM, args []Value) Value {
	if args[0] is f64 {
		res := math.sqrt(args[0] as f64)
		return Value(res)
	}
	return Value(f64(0))
}

fn native_floor(mut vm VM, args []Value) Value {
	if args[0] is f64 {
		res := math.floor(args[0] as f64)
		return Value(res)
	}
	return Value(f64(0))
}

fn native_printf(mut vm VM, args []Value) Value {
	if args.len == 0 {
		return Value(NilValue{})
	}
	fmt := value_to_string(args[0])
	mut res := fmt
	for i := 1; i < args.len; i++ {
		val_str := value_to_string(args[i])
		if res.contains('%') {
			idx := res.index('%') or { -1 }
			if idx != -1 && idx + 1 < res.len {
				res = res[..idx] + val_str + res[idx + 2..]
			}
		} else {
			res += ' ' + val_str
		}
	}
	print(res)
	return Value(NilValue{})
}

fn native_print(mut vm VM, args []Value) Value {
	for i, arg in args {
		print(value_to_string(arg))
		if i < args.len - 1 {
			print(' ')
		}
	}
	return Value(NilValue{})
}

fn native_println(mut vm VM, args []Value) Value {
	for i, arg in args {
		print(value_to_string(arg))
		if i < args.len - 1 {
			print(' ')
		}
	}
	println('')
	return Value(NilValue{})
}

fn native_eprint(mut vm VM, args []Value) Value {
	for arg in args {
		eprint(value_to_string(arg))
		eprint(' ')
	}
	eprintln('')
	return Value(NilValue{})
}

fn native_abs(mut vm VM, args []Value) Value {
	if args[0] is f64 {
		v := args[0] as f64
		if v < 0 {
			res := -v
			return Value(res)
		}
		return Value(v)
	}
	return args[0]
}

fn native_min(mut vm VM, args []Value) Value {
	if args.len == 0 {
		return Value(NilValue{})
	}
	mut m := if args[0] is f64 { args[0] as f64 } else { 0.0 }
	for i in 1 .. args.len {
		if args[i] is f64 {
			v := args[i] as f64
			if v < m {
				m = v
			}
		}
	}
	return Value(m)
}

fn native_max(mut vm VM, args []Value) Value {
	if args.len == 0 {
		return Value(NilValue{})
	}
	mut m := if args[0] is f64 { args[0] as f64 } else { 0.0 }
	for i in 1 .. args.len {
		if args[i] is f64 {
			v := args[i] as f64
			if v > m {
				m = v
			}
		}
	}
	return Value(m)
}

fn native_round(mut vm VM, args []Value) Value {
	if args[0] is f64 {
		res := math.round(args[0] as f64)
		return Value(res)
	}
	return args[0]
}

fn native_pow(mut vm VM, args []Value) Value {
	if args[0] is f64 && args[1] is f64 {
		res := math.pow(args[0] as f64, args[1] as f64)
		return Value(res)
	}
	return Value(f64(0))
}

fn native_apply(mut vm VM, args []Value) Value {
	callee := args[0]
	mut func_args := []Value{}
	if args[1] is ArrayValue {
		func_args = (args[1] as ArrayValue).elements.clone()
	}
	vm.push(callee)
	for arg in func_args {
		vm.push(arg)
	}
	initial_frames := vm.frame_count
	if !vm.call_value(callee, func_args.len) {
		return Value(NilValue{})
	}
	vm.run(initial_frames)
	return vm.pop()
}

fn native_map(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		callee := args[1]
		mut new_elements := []Value{cap: arr.elements.len}
		for elem in arr.elements {
			vm.push(callee)
			vm.push(elem)
			initial_frames := vm.frame_count
			if vm.call_value(callee, 1) {
				vm.run(initial_frames)
				new_elements << vm.pop()
			}
		}
		return Value(ArrayValue{
			elements: new_elements
		})
	}
	return args[0]
}

fn native_filter(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		callee := args[1]
		mut new_elements := []Value{cap: arr.elements.len}
		for elem in arr.elements {
			vm.push(callee)
			vm.push(elem)
			initial_frames := vm.frame_count
			if vm.call_value(callee, 1) {
				vm.run(initial_frames)
				res := vm.pop()
				if !is_falsey(res) {
					new_elements << elem
				}
			}
		}
		return Value(ArrayValue{
			elements: new_elements
		})
	}
	return args[0]
}

fn native_range(mut vm VM, args []Value) Value {
	mut start := 0.0
	mut stop := 0.0
	mut step := 1.0
	if args.len == 1 {
		stop = if args[0] is f64 { args[0] as f64 } else { 0.0 }
	} else if args.len >= 2 {
		start = if args[0] is f64 { args[0] as f64 } else { 0.0 }
		stop = if args[1] is f64 { args[1] as f64 } else { 0.0 }
		if args.len >= 3 {
			step = if args[2] is f64 { args[2] as f64 } else { 1.0 }
		}
	}
	if step == 0 {
		return Value(ArrayValue{
			elements: []Value{}
		})
	}
	mut elements := []Value{}
	if step > 0 {
		for i := start; i < stop; i += step {
			elements << Value(i)
		}
	} else {
		for i := start; i > stop; i += step {
			elements << Value(i)
		}
	}
	return Value(ArrayValue{
		elements: elements
	})
}

fn native_reduce(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		callee := args[1]
		mut acc := args[2]
		for elem in arr.elements {
			vm.push(callee)
			vm.push(acc)
			vm.push(elem)
			initial_frames := vm.frame_count
			if vm.call_value(callee, 2) {
				vm.run(initial_frames)
				acc = vm.pop()
			}
		}
		return acc
	}
	return args[2]
}

fn native_find(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		callee := args[1]
		for elem in arr.elements {
			vm.push(callee)
			vm.push(elem)
			initial_frames := vm.frame_count
			if vm.call_value(callee, 1) {
				vm.run(initial_frames)
				res := vm.pop()
				if !is_falsey(res) {
					return elem
				}
			}
		}
	}
	return Value(NilValue{})
}

fn native_any(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		callee := args[1]
		for elem in arr.elements {
			vm.push(callee)
			vm.push(elem)
			initial_frames := vm.frame_count
			if vm.call_value(callee, 1) {
				vm.run(initial_frames)
				res := vm.pop()
				if !is_falsey(res) {
					return Value(true)
				}
			}
		}
	}
	return Value(false)
}

fn native_all(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		callee := args[1]
		if arr.elements.len == 0 {
			return Value(true)
		}
		for elem in arr.elements {
			vm.push(callee)
			vm.push(elem)
			initial_frames := vm.frame_count
			if vm.call_value(callee, 1) {
				vm.run(initial_frames)
				res := vm.pop()
				if is_falsey(res) {
					return Value(false)
				}
			}
		}
		return Value(true)
	}
	return Value(false)
}

fn native_first(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		if arr.elements.len > 0 {
			return arr.elements[0]
		}
	}
	return Value(NilValue{})
}

fn native_last(mut vm VM, args []Value) Value {
	if args[0] is ArrayValue {
		arr := args[0] as ArrayValue
		if arr.elements.len > 0 {
			return arr.elements[arr.elements.len - 1]
		}
	}
	return Value(NilValue{})
}

fn native_memoize(mut vm VM, args []Value) Value {
	callee := args[0]
	mut cache := map[string]Value{}
	return Value(NativeFunctionValue{
		name:  'memoized_wrapper'
		arity: -1
		func:  fn [callee, mut cache] (mut vm VM, args []Value) Value {
			key := args.str()
			if val := cache[key] {
				return val
			}
			vm.push(callee)
			for a in args {
				vm.push(a)
			}
			initial_frames := vm.frame_count
			if vm.call_value(callee, args.len) {
				vm.run(initial_frames)
				res := vm.pop()
				cache[key] = res
				return res
			}
			return Value(NilValue{})
		}
	})
}

fn native_lru_cache(mut vm VM, args []Value) Value {
	callee := args[0]
	capacity := if args.len > 1 && args[1] is f64 { int(args[1] as f64) } else { 100 }
	mut cache := map[string]Value{}
	mut keys := []string{}
	return Value(NativeFunctionValue{
		name:  'lru_cache_wrapper'
		arity: -1
		func:  fn [callee, capacity, mut cache, mut keys] (mut vm VM, args []Value) Value {
			key := args.str()
			if val := cache[key] {
				idx := keys.index(key)
				if idx != -1 {
					keys.delete(idx)
				}
				keys << key
				return val
			}
			vm.push(callee)
			for a in args {
				vm.push(a)
			}
			initial_frames := vm.frame_count
			if vm.call_value(callee, args.len) {
				vm.run(initial_frames)
				res := vm.pop()
				cache[key] = res
				keys << key
				if keys.len > capacity {
					oldest := keys[0]
					cache.delete(oldest)
					keys.delete(0)
				}
				return res
			}
			return Value(NilValue{})
		}
	})
}

fn native_type(mut vm VM, args []Value) Value {
	val := args[0]
	return match val {
		f64 { Value('number') }
		bool { Value('boolean') }
		string { Value('string') }
		NilValue { Value('nil') }
		FunctionValue, ClosureValue, NativeFunctionValue { Value('function') }
		ArrayValue { Value('array') }
		MapValue { Value('map') }
		ClassValue { Value('class') }
		InstanceValue { Value('instance') }
		StructValue { Value('struct_type') }
		StructInstanceValue { Value('struct') }
		EnumValue { Value('enum_type') }
		EnumVariantValue { Value('enum_variant') }
		BoundMethodValue { Value('function') }
	}
}

fn native_keys(mut vm VM, args []Value) Value {
	if args[0] is MapValue {
		m := args[0] as MapValue
		mut ks := []Value{}
		for k, _ in m.items {
			ks << Value(k)
		}
		return Value(ArrayValue{
			elements: ks
		})
	}
	return Value(ArrayValue{
		elements: []Value{}
	})
}

fn native_values(mut vm VM, args []Value) Value {
	if args[0] is MapValue {
		m := args[0] as MapValue
		mut vs := []Value{}
		for _, v in m.items {
			vs << v
		}
		return Value(ArrayValue{
			elements: vs
		})
	}
	return Value(ArrayValue{
		elements: []Value{}
	})
}

fn native_has_key(mut vm VM, args []Value) Value {
	if args[0] is MapValue && args[1] is string {
		m := args[0] as MapValue
		k := args[1] as string
		return Value(k in m.items)
	}
	return Value(false)
}

fn native_json_encode(mut vm VM, args []Value) Value {
	return Value(value_to_json(args[0]))
}

fn value_to_json(v Value) string {
	return match v {
		f64 {
			v.str()
		}
		bool {
			v.str()
		}
		string {
			'"' + v + '"'
		}
		NilValue {
			'null'
		}
		ArrayValue {
			mut res := '['
			for i, elem in v.elements {
				res += value_to_json(elem)
				if i < v.elements.len - 1 {
					res += ','
				}
			}
			res += ']'
			res
		}
		MapValue {
			mut res := '{'
			mut count := 0
			for k, val in v.items {
				res += '"' + k + '": ' + value_to_json(val)
				if count < v.items.len - 1 {
					res += ','
				}
				count++
			}
			res += '}'
			res
		}
		else {
			'null'
		}
	}
}

fn native_json_decode(mut vm VM, args []Value) Value {
	if args[0] is string {
		source := args[0] as string
		raw := json2.decode[json2.Any](source) or { return Value(NilValue{}) }
		return json_to_value(raw)
	}
	return Value(NilValue{})
}

fn json_to_value(raw json2.Any) Value {
	match raw {
		map[string]json2.Any {
			mut items := map[string]Value{}
			for k, v in raw {
				items[k] = json_to_value(v)
			}
			return Value(MapValue{
				items: items
			})
		}
		[]json2.Any {
			mut elements := []Value{}
			for e in raw {
				elements << json_to_value(e)
			}
			return Value(ArrayValue{
				elements: elements
			})
		}
		string {
			return Value(raw)
		}
		f64 {
			return Value(raw)
		}
		i64 {
			return Value(f64(raw))
		}
		int {
			return Value(f64(raw))
		}
		bool {
			return Value(raw)
		}
		else {
			return Value(NilValue{})
		}
	}
}

fn native_to_string(mut vm VM, args []Value) Value {
	return Value(value_to_string(args[0]))
}

fn native_to_number(mut vm VM, args []Value) Value {
	val := args[0]
	if val is f64 {
		return val
	}
	if val is string {
		return Value(val.f64())
	}
	if val is bool {
		return Value(if val {
			f64(1)
		} else {
			f64(0)
		})
	}
	return Value(f64(0))
}

fn native_is_empty(mut vm VM, args []Value) Value {
	val := args[0]
	return match val {
		string { Value(val.len == 0) }
		ArrayValue { Value(val.elements.len == 0) }
		MapValue { Value(val.items.len == 0) }
		else { Value(true) }
	}
}

fn native_trim(mut vm VM, args []Value) Value {
	if args[0] is string {
		return Value((args[0] as string).trim_space())
	}
	return args[0]
}

fn native_is_digit(mut vm VM, args []Value) Value {
	if args[0] is string {
		s := args[0] as string
		if s.len == 0 {
			return Value(false)
		}
		for i in 0 .. s.len {
			if s[i] < `0` || s[i] > `9` {
				return Value(false)
			}
		}
		return Value(true)
	}
	return Value(false)
}

fn native_is_alpha(mut vm VM, args []Value) Value {
	if args[0] is string {
		s := args[0] as string
		if s.len == 0 {
			return Value(false)
		}
		for i in 0 .. s.len {
			c := s[i]
			if !((c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_`) {
				return Value(false)
			}
		}
		return Value(true)
	}
	return Value(false)
}

fn native_optimize(mut vm VM, args []Value) Value {
	return Value(NilValue{})
}

fn (mut vm VM) register_stdlib() {
	vm.define_native('clock', 0, native_clock)
	vm.define_native('len', 1, native_len)
	vm.define_native('push', 2, native_push)
	vm.define_native('slice', -1, native_slice)
	vm.define_native('sqrt', 1, native_sqrt)
	vm.define_native('floor', 1, native_floor)
	vm.define_native('printf', -1, native_printf)
	vm.define_native('print', -1, native_print)
	vm.define_native('println', -1, native_println)
	vm.define_native('eprint', -1, native_eprint)
	vm.define_native('type', 1, native_type)
	vm.define_native('to_string', 1, native_to_string)
	vm.define_native('to_number', 1, native_to_number)
	vm.define_native('is_empty', 1, native_is_empty)
	vm.define_native('trim', 1, native_trim)
	vm.define_native('is_digit', 1, native_is_digit)
	vm.define_native('is_alpha', 1, native_is_alpha)
	vm.define_native('abs', 1, native_abs)
	vm.define_native('min', -1, native_min)
	vm.define_native('max', -1, native_max)
	vm.define_native('round', 1, native_round)
	vm.define_native('pow', 2, native_pow)
	vm.define_native('apply', 2, native_apply)
	vm.define_native('map', 2, native_map)
	vm.define_native('filter', 2, native_filter)
	vm.define_native('reduce', 3, native_reduce)
	vm.define_native('find', 2, native_find)
	vm.define_native('any', 2, native_any)
	vm.define_native('all', 2, native_all)
	vm.define_native('range', -1, native_range)
	vm.define_native('first', 1, native_first)
	vm.define_native('last', 1, native_last)
	vm.define_native('memoize', 1, native_memoize)
	vm.define_native('lru_cache', -1, native_lru_cache)
	vm.define_native('keys', 1, native_keys)
	vm.define_native('values', 1, native_values)
	vm.define_native('has_key', 2, native_has_key)
	vm.define_native('json_encode', 1, native_json_encode)
	vm.define_native('json_decode', 1, native_json_decode)
	vm.define_native('optimize', 2, native_optimize)

	// Built-in Types

	// Result
	vm.globals['Result'] = EnumValue{
		name:     'Result'
		variants: ['ok', 'err']
	}
	
	// Option
	vm.globals['Option'] = EnumValue{
		name:     'Option'
		variants: ['some', 'none']
	}
}
