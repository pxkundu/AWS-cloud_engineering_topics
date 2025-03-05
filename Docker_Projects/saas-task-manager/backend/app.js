const express = require('express');
const fs = require('fs').promises;
const cors = require('cors');
const path = require('path');

const app = express();
const TASKS_FILE = path.join(__dirname, 'tasks.json');

app.use(express.json());
app.use(cors());

// Initialize tasks file if it doesn't exist
async function initTasksFile() {
    try {
        await fs.access(TASKS_FILE);
        const data = await fs.readFile(TASKS_FILE, 'utf8');
        JSON.parse(data); // Validate JSON
    } catch (err) {
        console.log('Initializing tasks.json:', err.message);
        await fs.writeFile(TASKS_FILE, JSON.stringify([], null, 2));
    }
}

// Read tasks
async function getTasks() {
    try {
        const data = await fs.readFile(TASKS_FILE, 'utf8');
        return JSON.parse(data);
    } catch (err) {
        throw new Error('Failed to read tasks: ' + err.message);
    }
}

// Write tasks
async function saveTasks(tasks) {
    try {
        await fs.writeFile(TASKS_FILE, JSON.stringify(tasks, null, 2));
    } catch (err) {
        throw new Error('Failed to write tasks: ' + err.message);
    }
}

// GET: List tasks
app.get('/api/tasks', async (req, res) => {
    try {
        const tasks = await getTasks();
        res.json(tasks);
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: err.message });
    }
});

// POST: Add task
app.post('/api/tasks', async (req, res) => {
    try {
        const { title } = req.body;
        if (!title) return res.status(400).json({ error: 'Title is required' });
        const tasks = await getTasks();
        const task = { id: tasks.length ? tasks[tasks.length - 1].id + 1 : 1, title, createdAt: new Date().toISOString() };
        tasks.push(task);
        await saveTasks(tasks);
        res.status(201).json(task);
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: err.message });
    }
});

// PUT: Update task
app.put('/api/tasks/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { title } = req.body;
        if (!title) return res.status(400).json({ error: 'Title is required' });
        const tasks = await getTasks();
        const taskIndex = tasks.findIndex(t => t.id === parseInt(id));
        if (taskIndex === -1) return res.status(404).json({ error: 'Task not found' });
        tasks[taskIndex] = { ...tasks[taskIndex], title, updatedAt: new Date().toISOString() };
        await saveTasks(tasks);
        res.json(tasks[taskIndex]);
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: err.message });
    }
});

// DELETE: Delete task
app.delete('/api/tasks/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const tasks = await getTasks();
        const taskIndex = tasks.findIndex(t => t.id === parseInt(id));
        if (taskIndex === -1) return res.status(404).json({ error: 'Task not found' });
        tasks.splice(taskIndex, 1);
        await saveTasks(tasks);
        res.status(204).send();
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ error: err.message });
    }
});

const PORT = process.env.PORT || 5000;
initTasksFile().then(() => {
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}).catch(err => {
    console.error('Failed to start server:', err.message);
    process.exit(1);
});
