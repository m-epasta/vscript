// Test maps and JSON support
let m = {
    "name": "Alice",
    "age": 30,
    "has_pet": true,
    "data": [1, 2, 3]
};

print("Map Literal:");
print(m);

print("Indexing:");
print(m["name"]);
print(m["age"]);
m["city"] = "New York";
print(m);

print("Map Helpers:");
let ks = keys(m);
let vs = values(m);
print("Keys:");
print(ks);
print("Values:");
print(vs);
print("Has Key 'age':");
print(has_key(m, "age"));

print("JSON Support:");
let json_str = json_encode(m);
print("Encoded:");
print(json_str);

let decoded = json_decode(json_str);
print("Decoded:");
print(decoded);
print("Decoded name:");
print(decoded["name"]);
