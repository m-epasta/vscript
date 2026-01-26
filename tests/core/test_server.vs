import core:http_server

print("Module http_server loaded.");

var bind_res = http_server.bind(0);
var res_copy = bind_res;
print("1. Bind result type: " + typeof(bind_res));
if (typeof(bind_res) != "map") {
    print("CRITICAL: Failed to bind server: " + bind_res);
} else {
    print("2. Success path, res type: " + typeof(res_copy));
    var my_server = res_copy;
    print("3. my_server type before port access: " + typeof(my_server));
    var actual_port = my_server.port;
    print("PORT_MARKER:" + actual_port);
    print("Server active at http://localhost:" + actual_port);

    while (true) {
        var res_data = await my_server.accept();
        if (typeof(res_data) == "map") {
            var req = res_data.request;
            var res = res_data.response;
            print("Request: " + req.method + " " + req.url);
            
            res.send("High-Performance vscript Server: OK");
        }
    }
}
