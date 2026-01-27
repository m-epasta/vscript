module main

// mark_roots traces all reachable objects from the VM stack, globals, and frames.
fn (mut vm VM) mark_roots() {
	// 1. Stack
	for i in 0 .. vm.stack.len {
		vm.mark_value(vm.stack[i])
	}

	// 2. Globals
	for _, val in vm.globals {
		vm.mark_value(val)
	}

	// 3. Call Frames (Closures)
	for i in 0 .. vm.frame_count {
		vm.mark_value(Value(vm.frames[i].closure))
	}

	// 4. Open Upvalues
	for upvalue in vm.open_upvalues {
		vm.mark_object(upvalue.gc, Value(*upvalue))
	}
}

// mark_value identifies if a value is a heap object and marks it.
fn (mut vm VM) mark_value(v Value) {
	match v {
		ArrayValue { vm.mark_object(v.gc, v) }
		BoundMethodValue { vm.mark_object(v.gc, v) }
		ClassValue { vm.mark_object(v.gc, v) }
		ClosureValue { vm.mark_object(v.gc, v) }
		EnumValue { vm.mark_object(v.gc, v) }
		EnumVariantValue { vm.mark_object(v.gc, v) }
		FunctionValue { vm.mark_object(v.gc, v) }
		InstanceValue { vm.mark_object(v.gc, v) }
		MapValue { vm.mark_object(v.gc, v) }
		NativeFunctionValue { vm.mark_object(v.gc, v) }
		RequestValue { vm.mark_object(v.gc, v) }
		ResponseValue { vm.mark_object(v.gc, v) }
		SocketValue { vm.mark_object(v.gc, v) }
		StreamValue { vm.mark_object(v.gc, v) }
		StructInstanceValue { vm.mark_object(v.gc, v) }
		StructValue { vm.mark_object(v.gc, v) }
		else {}
	}
}

// mark_object marks a GCHeader and adds the object to the gray stack.
fn (mut vm VM) mark_object(gc &GCHeader, v Value) {
	if gc == unsafe { nil } || gc.marked {
		return
	}

	unsafe {
		mut mutable_gc := gc
		mutable_gc.marked = true
	}
	vm.gray_stack << v
}

// trace_references processes the gray stack until empty.
fn (mut vm VM) trace_references() {
	for vm.gray_stack.len > 0 {
		v := vm.gray_stack.last()
		vm.gray_stack.delete(vm.gray_stack.len - 1)
		vm.blacken_object(v)
	}
}

// blacken_object traces references within a marked object.
fn (mut vm VM) blacken_object(v Value) {
	match v {
		ArrayValue {
			for element in v.elements {
				vm.mark_value(element)
			}
		}
		BoundMethodValue {
			vm.mark_value(v.receiver)
			vm.mark_value(v.method)
		}
		ClassValue {
			for _, method in v.methods {
				vm.mark_value(method)
			}
		}
		ClosureValue {
			vm.mark_value(Value(v.function)) // function contains constant pool
			for uv in v.upvalues {
				vm.mark_object(uv.gc, Value(*uv))
			}
		}
		EnumVariantValue {
			for val in v.values {
				vm.mark_value(val)
			}
		}
		FunctionValue {
			for constant in v.chunk.constants {
				vm.mark_value(constant)
			}
		}
		InstanceValue {
			vm.mark_value(Value(v.class))
			for _, field in v.fields {
				vm.mark_value(field)
			}
		}
		MapValue {
			for _, item in v.items {
				vm.mark_value(item)
			}
		}
		NativeFunctionValue {
			for context_val in v.context {
				vm.mark_value(context_val)
			}
		}
		StructInstanceValue {
			vm.mark_value(Value(v.struct_type))
			for _, field in v.fields {
				vm.mark_value(field)
			}
		}
		StructValue {
			for _, def in v.field_defaults {
				vm.mark_value(def)
			}
		}
		Upvalue {
			if v.value != unsafe { nil } {
				vm.mark_value(*v.value)
			}
			vm.mark_value(v.closed)
		}
		PromiseState {
			vm.mark_value(v.value)
		}
		else {}
	}
}

// collect_garbage performs a full mark-and-sweep cycle.
fn (mut vm VM) collect_garbage() {
	$if vscript_debug_gc ? {
		println('--- GC START (allocated: ${vm.bytes_allocated}, threshold: ${vm.gc_threshold}) ---')
	}

	// 1. Mark
	vm.mark_roots()
	vm.trace_references()

	// 2. Sweep
	mut prev := &GCHeader(unsafe { nil })
	mut curr := vm.objects_head
	mut swept_count := 0

	for curr != unsafe { nil } {
		if curr.marked {
			// Object is reachable, keep it and reset marked flag for next cycle
			curr.marked = false
			prev = curr
			curr = curr.next
		} else {
			// Object is unreachable, remove from linked list
			swept_count++
			vm.bytes_allocated -= curr.size
			mut next_obj := curr.next

			if prev != unsafe { nil } {
				prev.next = next_obj
			} else {
				vm.objects_head = next_obj
			}

			curr = next_obj
		}
	}

	// 3. Adjust threshold
	if vm.bytes_allocated > 0 {
		vm.gc_threshold = vm.bytes_allocated * 2
	} else {
		vm.gc_threshold = 1024 * 1024 // reset to 1MB minimum
	}

	$if vscript_debug_gc ? {
		println('--- GC END (freed: ${swept_count} objects, new allocated: ${vm.bytes_allocated}, new threshold: ${vm.gc_threshold}) ---')
	}
}

// alloc_header creates a new GCHeader and registers it with the VM.
fn (mut vm VM) alloc_header(size int) &GCHeader {
	if vm.bytes_allocated > vm.gc_threshold {
		vm.collect_garbage()
	}

	mut header := &GCHeader{
		marked: false
		size:   size
		next:   vm.objects_head
	}
	vm.objects_head = header
	vm.bytes_allocated += size
	return header
}
