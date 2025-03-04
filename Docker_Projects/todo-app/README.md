### Project Overview
- **Goal**: A web app where you can view and add to-dos.
- **Components**:
  - **Frontend**: Nginx serves an HTML page with a form to add tasks.
  - **Backend**: Flask API stores and retrieves tasks.
- **Docker**: Two containers managed by Docker Compose.

---

### Step-by-Step Process

#### Step 1: Set Up Project Directory
1. **Create a fresh directory**:
   ```bash
   mkdir ~/todo-app
   cd ~/todo-app
   ```
2. **Purpose**: Keeps all files organized.

---

#### Step 2: Create the Backend (Flask API)
1. **Write `app.py`**:
   ```bash
   nano app.py
   ```
   Paste:
   ```python
   from flask import Flask, jsonify, request
   from flask_cors import CORS

   app = Flask(__name__)
   CORS(app)  # Enable CORS for frontend access
   todos = []

   @app.route('/todos', methods=['GET'])
   def get_todos():
       return jsonify(todos)

   @app.route('/todos', methods=['POST'])
   def add_todo():
       todo = request.json.get('task')
       if todo:
           todos.append(todo)
           return jsonify({'message': 'Todo added', 'todos': todos}), 201
       return jsonify({'error': 'No task provided'}), 400

   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   ```
   - Save: `Ctrl+O`, `Enter`, `Ctrl+X`.
   - **Notes**: Handles GET (list todos) and POST (add todo), with CORS enabled.

2. **Create `Dockerfile.backend`**:
   ```bash
   nano Dockerfile.backend
   ```
   Paste:
   ```dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY app.py .
   RUN pip install flask flask-cors
   CMD ["python", "app.py"]
   ```
   - Save: `Ctrl+O`, `Enter`, `Ctrl+X`.

---

#### Step 3: Create the Frontend (Nginx + HTML)
1. **Write `index.html`**:
   ```bash
   nano index.html
   ```
   Paste:
   ```html
   <!DOCTYPE html>
   <html>
   <body>
       <h1>To-Do List</h1>
       <ul id="todos"></ul>
       <input id="task" type="text" placeholder="New task">
       <button onclick="addTodo()">Add</button>
       <script>
           // Load existing todos
           fetch('http://localhost:5000/todos')
               .then(res => res.json())
               .then(data => {
                   const ul = document.getElementById('todos');
                   data.forEach(todo => {
                       const li = document.createElement('li');
                       li.textContent = todo;
                       ul.appendChild(li);
                   });
               })
               .catch(err => console.error('Fetch error:', err));

           // Add new todo
           function addTodo() {
               const task = document.getElementById('task').value;
               if (task) {
                   fetch('http://localhost:5000/todos', {
                       method: 'POST',
                       headers: { 'Content-Type': 'application/json' },
                       body: JSON.stringify({ task: task })
                   })
                   .then(() => {
                       document.getElementById('task').value = ''; // Clear input
                       location.reload(); // Refresh to show new todo
                   })
                   .catch(err => console.error('Add error:', err));
               }
           }
       </script>
   </body>
   </html>
   ```
   - Save: `Ctrl+O`, `Enter`, `Ctrl+X`.
   - **Notes**: Fetches todos from `localhost:5000` and posts new ones.

2. **Create `Dockerfile.frontend`**:
   ```bash
   nano Dockerfile.frontend
   ```
   Paste:
   ```dockerfile
   FROM nginx:latest
   COPY index.html /usr/share/nginx/html/index.html
   ```
   - Save: `Ctrl+O`, `Enter`, `Ctrl+X`.

---

#### Step 4: Set Up Docker Compose
1. **Create `docker-compose.yml`**:
   ```bash
   nano docker-compose.yml
   ```
   Paste:
   ```yaml
   version: '3'
   services:
     backend:
       build:
         context: .
         dockerfile: Dockerfile.backend
       ports:
         - "5000:5000"
     frontend:
       build:
         context: .
         dockerfile: Dockerfile.frontend
       ports:
         - "8080:80"
       depends_on:
         - backend
   ```
   - Save: `Ctrl+O`, `Enter`, `Ctrl+X`.
   - **Notes**: Maps backend to 5000 and frontend to 8080; `depends_on` ensures backend starts first.

2. **Install Docker Compose** (if not already):
   ```bash
   sudo apt install docker-compose -y
   ```

---

#### Step 5: Build and Run the App
1. **Build Images**:
   ```bash
   docker-compose build
   ```
   - Builds `todo-app_backend` and `todo-app_frontend`.

2. **Start Containers**:
   ```bash
   docker-compose up -d
   ```
   - Runs in detached mode.

3. **Verify Running**:
   ```bash
   docker ps
   ```
   - Look for `todo-app_backend_1` (5000) and `todo-app_frontend_1` (8080).

---

#### Step 6: Test the Application
1. **Test Backend**:
   ```bash
   curl localhost:5000/todos
   ```
   - **Expected**: `[]` (empty initially).
   ```bash
   curl -X POST -H "Content-Type: application/json" -d '{"task":"Buy milk"}' localhost:5000/todos
   ```
   - **Expected**: `{"message":"Todo added","todos":["Buy milk"]}`.

2. **Test Frontend**:
   - Open `http://localhost:8080` in your browser.
   - **Expected**: “To-Do List” with an empty list initially.
   - Type “Buy milk” in the input, click “Add”.
   - **Expected**: Page reloads, “Buy milk” appears in the list.

3. **Check Console** (Browser Inspect > Console):
   - No CORS errors should appear.

---

#### Step 7: Debug (If Needed)
- **Backend Logs**:
  ```bash
  docker logs todo-app_backend_1
  ```
  - Look for Flask errors.
- **Frontend Logs**:
  ```bash
  docker logs todo-app_frontend_1
  ```
  - Nginx logs for file serving issues.
- **Port Conflict**:
  - If 8080 or 5000 fails, change ports in `docker-compose.yml` (e.g., `8081:80`, `5001:5000`) and rerun.

---

#### Step 8: Clean Up
Stop and remove:
```bash
docker-compose down
```
- Optional: Add `-v` to remove volumes (`docker-compose down -v`).

---

### Real-World Use Case
- **Microservices**: Frontend and backend in separate containers mimic how companies like Amazon deploy UI and API services.
- **Dev Workflow**: Write code, build images, test locally—then deploy to EC2 or Kubernetes.
- **Your Learning**: Dockerfiles (image creation), Compose (multi-container apps), and networking (frontend-backend communication) reflect production setups.

---

### Project Files Recap
- `app.py`: Flask backend with CORS.
- `Dockerfile.backend`: Builds backend image.
- `index.html`: HTML frontend with fetch calls.
- `Dockerfile.frontend`: Builds frontend image.
- `docker-compose.yml`: Ties it together.

---

### Try It!
Follow these steps exactly in your WSL terminal. Once done:
1. Does `http://localhost:8080` show todos and let you add them?
2. Any errors? Share them (e.g., console output).
3. How would you improve this setup?

Use it from Dockerhub: https://hub.docker.com/u/pxkundu