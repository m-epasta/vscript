import core:os as os
import core:json as json
import core:compiler as compiler

fn send_response(obj) {
    var content = json.stringify(obj)
    var header = "Content-Length: ${len(content)} \r\n\r\n"
    os.stdout_write(header + content);
}

fn handle_request(req) {
    if (req.method == "initialize") {
        send_response({
            "id": req.id,
            "result": {
                "capabilities": {
                    "textDocumentSync": 1, // Full sync
                    "hoverProvider": false
                }
            }
        });
    } else if (req.method == "textDocument/didOpen" || req.method == "textDocument/didChange") {
        var text = "";
        if (req.method == "textDocument/didOpen") {
            text = req.params.textDocument.text;
        } else {
            text = req.params.contentChanges[0].text;
        }
        
        var diags = compiler.get_diagnostics(text);
        
        var diagnostics = [];
        for (var i = 0; i < len(diags); i = i + 1) {
            var d = diags[i];
            push(diagnostics, {
                "severity": 1,
                "range": {
                    "start": {"line": d.line - 1, "character": d.col},
                    "end": {"line": d.line - 1, "character": d.col + 1}
                },
                "message": d.message,
                "source": "vscript"
            });
        }

        send_response({
            "method": "textDocument/publishDiagnostics",
            "params": {
                "uri": req.params.textDocument.uri,
                "diagnostics": diagnostics
            }
        });
    }
}

// Main Loop
var running = true;
var line = "";
while (running) {
    line = os.stdin_read_line();
    if (line == nil || line == "") {
        running = false;
    } else {
        // Simple header parsing
        if (len(line) > 15) {
            if (slice(line, 0, 15) == "Content-Length:") {
                var length_str = trim(slice(line, 15, len(line)));
                var length = to_number(length_str);
                
                // Read the empty line (\r\n)
                os.stdin_read_line();
                
                // Read body
                var body = os.stdin_read(length);
                var req_res = json.parse(body);
                if (req_res.is_ok()) {
                    handle_request(req_res.unwrap());
                }
            }
        }
    }
}
