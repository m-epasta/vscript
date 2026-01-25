// Value representation for vscript VM
module main

// Tagged union for runtime values - optimized for performance
type Value = f64
	| bool
	| string
	| NilValue
	| FunctionValue
	| ArrayValue
	| ClosureValue
	| NativeFunctionValue

struct NilValue {}

type NativeFn = fn (mut vm VM, args []Value) Value

struct NativeFunctionValue {
	name  string
	arity int
	func  NativeFn @[required]
}

struct FunctionValue {
	arity          int
	upvalues_count int
	chunk          &Chunk
	name           string
}

struct ArrayValue {
mut:
	elements []Value
}

@[heap]
struct Upvalue {
mut:
	value        &Value // Pointer to current value (stack or closed)
	closed       Value  // Storage for value once closed
	is_closed    bool
	location_idx int
}

@[heap]
struct ClosureValue {
	function &FunctionValue
mut:
	upvalues []&Upvalue
}

fn value_to_string(v Value) string {
	return match v {
		f64 {
			v.str()
		}
		bool {
			v.str()
		}
		string {
			v
		}
		NilValue {
			'nil'
		}
		FunctionValue {
			'<fn ${v.name}>'
		}
		ClosureValue {
			'<fn ${v.function.name}>'
		}
		NativeFunctionValue {
			'<native fn ${v.name}>'
		}
		ArrayValue {
			mut res := '['
			for i, elem in v.elements {
				res += value_to_string(elem)
				if i < v.elements.len - 1 {
					res += ', '
				}
			}
			res += ']'
			res
		}
	}
}

fn values_equal(a Value, b Value) bool {
	return match a {
		f64 {
			if b is f64 {
				return a == b
			}
			false
		}
		bool {
			if b is bool {
				return a == b
			}
			false
		}
		string {
			if b is string {
				return a == b
			}
			false
		}
		NilValue {
			return b is NilValue
		}
		FunctionValue {
			if b is FunctionValue {
				return a.name == b.name && a.chunk == b.chunk
			}
			false
		}
		ClosureValue {
			if b is ClosureValue {
				return a.function == b.function
			}
			false
		}
		NativeFunctionValue {
			if b is NativeFunctionValue {
				return a.name == b.name && a.func == b.func
			}
			false
		}
		ArrayValue {
			false // For now, simple inequality for arrays unless they are the same instance?
		}
	}
}

fn is_falsey(v Value) bool {
	return match v {
		NilValue { true }
		bool { !v }
		else { false }
	}
}
