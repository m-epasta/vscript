fn create_resolved_promise(mut vm VM, value Value) Value {
	id := vm.next_promise_id
	vm.next_promise_id++
	vm.promises[id] = &PromiseState{
		status: .resolved
		value:  value
		gc:     vm.alloc_header(int(sizeof(MapValue)))
	}
	return Value(PromiseValue{
		id: id
	})
}
