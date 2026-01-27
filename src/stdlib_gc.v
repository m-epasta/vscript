module main

fn create_gc_module(mut vm VM) Value {
	mut gc_map := map[string]Value{}

	vm.define_native_in_map(mut gc_map, 'collect', 0, fn (mut vm VM, args []Value) Value {
		vm.collect_garbage()
		return Value(NilValue{})
	})

	vm.define_native_in_map(mut gc_map, 'threshold', 0, fn (mut vm VM, args []Value) Value {
		return Value(f64(vm.gc_threshold))
	})

	vm.define_native_in_map(mut gc_map, 'set_threshold', 1, fn (mut vm VM, args []Value) Value {
		if args[0] is f64 {
			vm.gc_threshold = int(args[0] as f64)
		}
		return Value(NilValue{})
	})

	return Value(MapValue{
		items: gc_map
		gc:    vm.alloc_header(int(int(sizeof(EnumVariantValue))))
	})
}
