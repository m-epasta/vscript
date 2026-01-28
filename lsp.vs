import core:os as os
import core:json as json
import core:compiler as compiler

fn send_response(obj) {
    let content = json.stringify(obj)
    let header = "Content-Length: ${len(content)} \r\n\r\n"
    os.stdout_write(header + content)
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
        })
    } else if (req.method == "textDocument/didOpen" || req.method == "textDocument/didChange") {
        let text = ""
        if (req.method == "textDocument/didOpen") {
            text = req.params.textDocument.text
        } else {
            text = req.params.contentChanges[0].text
        }
        
        let diags = compiler.get_diagnostics(text)
        
        let diagnostics = []
        for (let i = 0 i < len(diags) i = i + 1) {
            let d = diags[i]
            push(diagnostics, {
                "severity": 1,
                "range": {
                    "start": {"line": d.line - 1, "character": d.col},
                    "end": {"line": d.line - 1, "character": d.col + 1}
                },
                "message": d.message,
                "source": "vscript"
            })
        }

        send_response({
            "method": "textDocument/publishDiagnostics",
            "params": {
                "uri": req.params.textDocument.uri,
                "diagnostics": diagnostics
            }
        })
    }
}

// Main Loop
let running = true
let line = ""
while (running) {
    line = os.stdin_read_line()
    if (line == nil || line == "") {
        running = false
    } else {
        // Simple header parsing
        if (len(line) > 15) {
            if (slice(line, 0, 15) == "Content-Length:") {
                let length_str = trim(slice(line, 15, len(line)))
                let length = to_number(length_str)
                
                // Read the empty line (\r\n)
                os.stdin_read_line()
                
                // Read body
                let body = os.stdin_read(length)
                let req_res = json.parse(body)
                if (req_res.is_ok()) {
                    handle_request(req_res.unwrap())
                }
            }
        }
    }
}
