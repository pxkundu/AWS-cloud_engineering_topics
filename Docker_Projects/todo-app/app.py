from flask import Flask, jsonify, request
from flask_cors import CORS  # Add this

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
todos = []

@app.route('/todos', methods=['GET'])
def get_todos():
    return jsonify(todos)

@app.route('/todos', methods=['POST'])
def add_todo():
    todo = request.json.get('task')
    todos.append(todo)
    return jsonify({'message': 'Todo added', 'todos': todos}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
