import React, { useState, useEffect } from 'react';
import './App.css';
import TaskList from './components/TaskList';
import TaskForm from './components/TaskForm';
import api from './services/api';
import { Task } from './types';

function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<string>('all');

  useEffect(() => {
    fetchTasks();
  }, []);

  const fetchTasks = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await api.getTasks();
      setTasks(data);
    } catch (err: any) {
      setError(err.message || 'Failed to fetch tasks');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateTask = async (taskData: Omit<Task, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const newTask = await api.createTask(taskData);
      setTasks([newTask, ...tasks]);
    } catch (err: any) {
      setError(err.message || 'Failed to create task');
    }
  };

  const handleUpdateTask = async (id: number, taskData: Partial<Task>) => {
    try {
      const updatedTask = await api.updateTask(id, taskData);
      setTasks(tasks.map(task => task.id === id ? updatedTask : task));
    } catch (err: any) {
      setError(err.message || 'Failed to update task');
    }
  };

  const handleDeleteTask = async (id: number) => {
    try {
      await api.deleteTask(id);
      setTasks(tasks.filter(task => task.id !== id));
    } catch (err: any) {
      setError(err.message || 'Failed to delete task');
    }
  };

  const filteredTasks = tasks.filter(task => {
    if (filter === 'all') return true;
    return task.status === filter;
  });

  return (
    <div className="App">
      <header className="App-header">
        <h1>📋 Task Manager</h1>
        <p className="subtitle">DevOps Production Project</p>
      </header>

      <main className="App-main">
        <div className="container">
          <TaskForm onSubmit={handleCreateTask} />
          
          <div className="filters">
            <button
              className={filter === 'all' ? 'active' : ''}
              onClick={() => setFilter('all')}
            >
              All
            </button>
            <button
              className={filter === 'pending' ? 'active' : ''}
              onClick={() => setFilter('pending')}
            >
              Pending
            </button>
            <button
              className={filter === 'in-progress' ? 'active' : ''}
              onClick={() => setFilter('in-progress')}
            >
              In Progress
            </button>
            <button
              className={filter === 'completed' ? 'active' : ''}
              onClick={() => setFilter('completed')}
            >
              Completed
            </button>
          </div>

          {error && (
            <div className="error-message">
              {error}
              <button onClick={() => setError(null)}>×</button>
            </div>
          )}

          {loading ? (
            <div className="loading">Loading tasks...</div>
          ) : (
            <TaskList
              tasks={filteredTasks}
              onUpdate={handleUpdateTask}
              onDelete={handleDeleteTask}
            />
          )}
        </div>
      </main>

      <footer className="App-footer">
        <p>DevOps Project - CI/CD Pipeline with Jenkins, EKS, and Terraform</p>
      </footer>
    </div>
  );
}

export default App;

