import subprocess
import json
import time

def test_lsp():
    proc = subprocess.Popen(['./vscript', '--lsp'], 
                            stdin=subprocess.PIPE, 
                            stdout=subprocess.PIPE, 
                            stderr=subprocess.PIPE, 
                            text=True)

    def send(msg):
        body = json.dumps(msg)
        header = f"Content-Length: {len(body)}\r\n\r\n"
        proc.stdin.write(header + body)
        proc.stdin.flush()

    def receive():
        line = proc.stdout.readline()
        if not line: return None
        if "Content-Length" in line:
            length = int(line.split(":")[1].strip())
            proc.stdout.readline() # empty line
            body = proc.stdout.read(length)
            return json.loads(body)
        return None

    import threading
    def log_stderr():
        for line in proc.stderr:
            print("LSP LOG:", line.strip())
    
    stderr_thread = threading.Thread(target=log_stderr, daemon=True)
    stderr_thread.start()

    try:
        # 1. Initialize
        print("Sending Initialize...")
        send({"method": "initialize", "id": 1, "params": {}})
        
        resp = receive()
        if resp:
            print("Response:", json.dumps(resp, indent=2))

        # 2. Open file with error
        print("Sending Open File...")
        send({"method": "textDocument/didOpen", "params": {
            "textDocument": {
                "uri": "file:///test.vs",
                "text": "var x = ;"
            }
        }})
        
        diag = receive()
        if diag:
            print("Diagnostics:", json.dumps(diag, indent=2))

    finally:
        if proc.poll() is None:
            time.sleep(1)
            proc.terminate()
        err = proc.communicate()
        if err:
            print("FINAL LSP LOG:", err)

if __name__ == "__main__":
    test_lsp()
