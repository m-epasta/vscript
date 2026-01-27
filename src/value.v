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
	| RequestValue
	| ResponseValue
	| SocketValue
	| StreamValue
	| StructInstanceValue
	| StructValue
	| bool
	| f64
	| string
	| Upvalue
	| PromiseState

struct NilValue {}

@[heap]
struct GCHeader {
pub mut:
	marked bool
	size   int
	next   &GCHeader = unsafe { nil }
}

@[heap]
struct RequestValue {
pub mut:
	method  string
	url     string
	headers map[string]string
	body    string
	gc      &GCHeader = unsafe { nil }
}

@[heap]
struct ResponseValue {
pub mut:
	status int
	handle voidptr // underlying connection handle
	gc     &GCHeader = unsafe { nil }
}

@[heap]
struct SocketValue {
pub mut:
	handle   voidptr
	messages chan string
	gc       &GCHeader = unsafe { nil }
}

@[heap]
struct StreamValue {
pub mut:
	chunks    chan string
	is_closed bool
	gc        &GCHeader = unsafe { nil }
}

struct FunctionValue {
pub mut:
	arity          int
	upvalues_count int
	chunk          &Chunk
	name           string
	attributes     []string // Stores attribute names/values for runtime reflection (e.g. test)
	is_async       bool
	gc             &GCHeader = unsafe { nil }
}

struct ClosureValue {
pub mut:
	function FunctionValue
	upvalues []&Upvalue
	gc       &GCHeader = unsafe { nil }
}

type NativeFn = fn (mut VM, []Value) Value

struct NativeFunctionValue {
pub mut:
	name    string
	arity   int
	func    NativeFn @[required]
	context []Value
	gc      &GCHeader = unsafe { nil }
}

struct ArrayValue {
pub mut:
	elements []Value
	gc       &GCHeader = unsafe { nil }
}

struct MapValue {
pub mut:
	items map[string]Value
	gc    &GCHeader = unsafe { nil }
}

struct ClassValue {
pub mut:
	name    string
	methods map[string]Value // Can be ClosureValue or NativeFunctionValue wrapper
	gc      &GCHeader = unsafe { nil }
}

struct InstanceValue {
pub mut:
	class  ClassValue
	fields map[string]Value
	gc     &GCHeader = unsafe { nil }
}

struct BoundMethodValue {
pub mut:
	receiver Value
	method   Value // ClosureValue or NativeFunctionValue
	gc       &GCHeader = unsafe { nil }
}

struct EnumValue {
pub mut:
	name     string
	variants []string
	gc       &GCHeader = unsafe { nil }
}

struct EnumVariantValue {
pub mut:
	enum_name string
	variant   string
	values    []Value
	gc        &GCHeader = unsafe { nil }
}

struct StructValue {
pub mut:
	name           string
	field_names    []string
	field_types    map[string]string
	field_defaults map[string]Value
	gc             &GCHeader = unsafe { nil }
}

struct StructInstanceValue {
pub mut:
	struct_type StructValue
	fields      map[string]Value
	gc          &GCHeader = unsafe { nil }
}

struct PromiseValue {
pub mut:
	id int
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
	gc     &GCHeader = unsafe { nil }
}

struct Upvalue {
pub mut:
	value        &Value = unsafe { nil }
	closed       Value
	location_idx int
	is_closed    bool
	next         &Upvalue  = unsafe { nil }
	gc           &GCHeader = unsafe { nil }
}

fn is_falsey(v Value) bool {
	match v {
		NilValue { return true }
		bool { return !v }
		else { return false }
	}
}

fn values_equal(a Value, b Value) bool {
	if a is bool && b is bool {
		return (a as bool) == (b as bool)
	}
	if a is f64 && b is f64 {
		return (a as f64) == (b as f64)
	}
	if a is string && b is string {
		return (a as string) == (b as string)
	}
	if a is NilValue && b is NilValue {
		return true
	}

	// For other types, they are only equal if they are the same object/pointer
	// which for structs means value equality, but since they contain maps/arrays
	// we should be careful. For now, we'll return false if not same type.
	// Actually, matching types is usually enough for Lox.

	// Note: Comparing non-primitive types by value in V can be complex.
	return false
}

fn value_to_string(v Value) string {
	match v {
		NilValue {
			return 'nil'
		}
		bool {
			return v.str()
		}
		f64 {
			if v == f64(int(v)) {
				return int(v).str()
			}
			return v.str()
		}
		string {
			return v
		}
		ArrayValue {
			mut res := '['
			for i, element in v.elements {
				res += value_to_string(element)
				if i < v.elements.len - 1 {
					res += ', '
				}
			}
			res += ']'
			return res
		}
		MapValue {
			mut res := '{'
			mut keys := v.items.keys()
			for i, k in keys {
				val := v.items[k] or { NilValue{} }
				res += '"${k}": ${value_to_string(val)}'
				if i < keys.len - 1 {
					res += ', '
				}
			}
			res += '}'
			return res
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
		ClassValue {
			return '<class ${v.name}>'
		}
		InstanceValue {
			return '<instance of ${v.class.name}>'
		}
		BoundMethodValue {
			return '<bound method>'
		}
		EnumValue {
			return '<enum ${v.name}>'
		}
		EnumVariantValue {
			mut res := '${v.enum_name}.${v.variant}'
			if v.values.len > 0 {
				res += '('
				for i, val in v.values {
					res += value_to_string(val)
					if i < v.values.len - 1 {
						res += ', '
					}
				}
				res += ')'
			}
			return res
		}
		PromiseValue {
			return '<promise ${v.id}>'
		}
		StructValue {
			return '<struct ${v.name}>'
		}
		StructInstanceValue {
			return '<struct instance ${v.struct_type.name}>'
		}
		RequestValue {
			return '<Request ${v.method} ${v.url}>'
		}
		ResponseValue {
			return '<Response ${v.status}>'
		}
		SocketValue {
			return '<Socket>'
		}
		StreamValue {
			return '<Stream>'
		}
		Upvalue {
			return '<upvalue>'
		}
		PromiseState {
			return '<promise state>'
		}
	}
}
