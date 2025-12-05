# returns pod IP in body and X-Pod-IP header
from flask import Flask, jsonify, request
import socket
app = Flask(__name__)
@app.route("/info")
def info():
    ip = socket.gethostbyname(socket.gethostname())
    resp = jsonify({"pod_ip": ip})
    resp.headers["X-Pod-IP"] = ip
    return resp
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
