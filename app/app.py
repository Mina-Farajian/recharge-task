# returns pod IP in body and X-Pod-IP header
from flask import Flask, jsonify, request
import socket
import os

app = Flask(__name__)
@app.route('/info', methods=['GET'])
def info():
    # Get Pod IP from environment variable or hostname
    pod_ip = os.environ.get('POD_IP', 'unknown')

    response = jsonify({'pod_ip': pod_ip})
    response.headers['X-Pod-IP'] = pod_ip
    return response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
