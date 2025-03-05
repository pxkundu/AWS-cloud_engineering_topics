import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [tasks, setTasks] = useState([]);
  const [newTask, setNewTask] = useState('');

  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = () => {
    axios.get('http://localhost:5000/api/tasks')
      .then(res => setTasks(res.data))
      .catch(err => console.error('Fetch error:', err));
  };

  const addTask = () => {
    if (newTask.trim()) {
      axios.post('http://localhost:5000/api/tasks', { title: newTask })
        .then(() => {
          setNewTask('');
          fetchTasks();
        })
        .catch(err => console.error('Add error:', err));
    }
  };

  const updateTask = (id, title) => {
    axios.put(`http://localhost:5000/api/tasks/${id}`, { title })
      .then(fetchTasks)
      .catch(err => console.error('Update error:', err));
  };

  const deleteTask = (id) => {
    axios.delete(`http://localhost:5000/api/tasks/${id}`)
      .then(fetchTasks)
      .catch(err => console.error('Delete error:', err));
  };

  return (
    <div className="App">
      <h1>SaaS Task Manager</h1>
      <input value={newTask} onChange={(e) => setNewTask(e.target.value)} placeholder="New task" />
      <button onClick={addTask}>Add Task</button>
      <ul>
        {tasks.map(task => (
          <li key={task.id}>
            {task.title} ({task.createdAt})
            <button onClick={() => updateTask(task.id, prompt('New title:', task.title))}>Edit</button>
            <button onClick={() => deleteTask(task.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
