import core:json as json

let arr = [1, 2, 3]
print(arr.len)

let map = {"a": 1, "b": 2}
let keys = map.keys()
print(keys.len)

let obj = json.parse("{\"x\": 10}")
print(obj.x)
