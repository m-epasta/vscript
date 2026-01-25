// Value types for vscript
module main

type Value = ArrayValue
	| BoundMethodValue
	| ClassValue
	| ClosureValue
	| EnumValue
	| EnumVariantValue
	| FunctionValue
	| InstanceValue
	| MapValue
	| NativeFunctionValue
	| NilValue
	| PromiseValue
	| SocketValue
	| StreamValue
	| StructInstanceValue
	| StructValue
	| bool
	| f64
	| string

struct NilValue {}

@[heap]
struct SocketValue {
pub:
	handle   voidptr
	messages chan string
}

@[heap]
struct StreamValue {
pub:
	chunks chan string
mut:
	is_closed bool
}

struct FunctionValue {
pub:
	arity          int
	upvalues_count int
	chunk          &Chunk
	name           string
	attributes     []string // Stores attribute names/values for runtime reflection (e.g. test)
	is_async       bool
}

struct ClosureValue {
pub:
	function FunctionValue
mut:
	upvalues []&Upvalue
}

type NativeFn = fn (mut VM, []Value) Value

struct NativeFunctionValue {
	name    string
	arity   int
	func    NativeFn @[required]
	context []Value
}

struct ArrayValue {
mut:
	elements []Value
}

struct MapValue {
mut:
	items map[string]Value
}

struct ClassValue {
	name string
mut:
	methods map[string]Value // Can be ClosureValue or NativeFunctionValue wrapper
}

struct InstanceValue {
	class ClassValue
mut:
	fields map[string]Value
}

struct StructValue {
	name string
mut:
	field_names    []string
	field_types    map[string]string
	field_defaults map[string]Value
}

struct StructInstanceValue {
	struct_type StructValue
mut:
	fields map[string]Value
}

struct EnumValue {
	name string
mut:
	variants []string
}

struct EnumVariantValue {
	enum_name string
	variant   string
	values    []Value // Associated data for Sum Types
}

struct BoundMethodValue {
	receiver Value
	method   Value // Can be ClosureValue or NativeFunctionValue wrapper
}

enum PromiseStatus {
	pending
	resolved
	rejected
}

@[heap]
struct PromiseState {
pub mut:
	status PromiseStatus
	value  Value
}

struct PromiseValue {
pub mut:
	id int
}

@[heap]
struct Upvalue {
mut:
	value     &Value
	closed    Value
	is_closed bool
	// Index in the stack where the variable lives (while open)
	location_idx int
}

fn value_to_string(v Value) string {
	match v {
		f64 {
			return v.str()
		}
		bool {
			return v.str()
		}
		string {
			return v
		}
		NilValue {
			return 'nil'
		}
		FunctionValue {
			return '<fn ${v.name}>'
		}
		ClosureValue {
			return '<fn ${v.function.name}>'
		}
		NativeFunctionValue {
			return '<native fn ${v.name}>'
		}
		SocketValue {
			return '<Socket>'
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
			return res
		}
		MapValue {
			mut res := '{'
			mut count := 0
			for k, val in v.items {
				res += '"' + k + '": ' + value_to_string(val)
				if count < v.items.len - 1 {
					res += ', '
				}
				count++
			}
			res += '}'
			return res
		}
		ClassValue {
			return '<class ${v.name}>'
		}
		InstanceValue {
			return '<instance of ${v.class.name}>'
		}
		StructValue {
			return '<struct type ${v.name}>'
		}
		StructInstanceValue {
			return '<struct instance of ${v.struct_type.name}>'
		}
		EnumValue {
			return '<enum ${v.name}>'
		}
		EnumVariantValue {
			return '${v.enum_name}.${v.variant}'
		}
		BoundMethodValue {
			return value_to_string(v.method)
		}
		PromiseValue {
			return '<Promise id=${v.id}>'
		}
		StreamValue {
			return '<Stream>'
		}
	}
}

fn values_equal(a Value, b Value) bool {
	match a {
		NilValue {
			return b is NilValue
		}
		f64 {
			if b is f64 {
				return a == b
			}
		}
		bool {
			if b is bool {
				return a == b
			}
		}
		string {
			if b is string {
				return a == b
			}
		}
		SocketValue {
			if b is SocketValue {
				return a.handle == b.handle
			}
		}
		EnumVariantValue {
			if b is EnumVariantValue {
				if a.enum_name != b.enum_name || a.variant != b.variant {
					return false
				}
				if a.values.len != b.values.len {
					return false
				}
				for i in 0 .. a.values.len {
					if !values_equal(a.values[i], b.values[i]) {
						return false
					}
				}
				return true
			}
		}
		else {
			return false
		}
	}
	return false
}

fn is_falsey(v Value) bool {
	match v {
		NilValue { return true }
		bool { return !v }
		else { return false }
	}
}
