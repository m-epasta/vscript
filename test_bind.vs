import core:http_server;
print("Pre-bind");
http_server.bind(0);
print("Post-bind");