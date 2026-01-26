fn create_resolved_promise(mut vm VM, value Value) Value {
	id := vm.next_promise_id
	vm.next_promise_id++
	vm.promises[id] = &PromiseState{
		status: .resolved
		value:  value
	}
	return Value(PromiseValue{
		id: id
	})
}
