import core:json as json

var arr = [1, 2, 3]
print(arr.len)

var map = {"a": 1, "b": 2}
var keys = map.keys()
print(keys.len)

var obj = json.parse("{\"x\": 10}")
print(obj.x)
