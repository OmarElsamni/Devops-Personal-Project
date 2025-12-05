import React, { useState } from 'react';
import { Task } from '../types';

interface TaskItemProps {
  task: Task;
  onUpdate: (id: number, data: Partial<Task>) => void;
  onDelete: (id: number) => void;
}

const TaskItem: React.FC<TaskItemProps> = ({ task, onUpdate, onDelete }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editedTask, setEditedTask] = useState(task);

  const handleSave = () => {
    onUpdate(task.id, editedTask);
    setIsEditing(false);
  };

  const handleCancel = () => {
    setEditedTask(task);
    setIsEditing(false);
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return '#ff4757';
      case 'medium': return '#ffa502';
      case 'low': return '#26de81';
      default: return '#777';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return '#26de81';
      case 'in-progress': return '#3742fa';
      case 'pending': return '#ffa502';
      default: return '#777';
    }
  };

  if (isEditing) {
    return (
      <div className="task-item editing">
        <input
          type="text"
          value={editedTask.title}
          onChange={(e) => setEditedTask({ ...editedTask, title: e.target.value })}
          className="task-title-input"
        />
        <textarea
          value={editedTask.description}
          onChange={(e) => setEditedTask({ ...editedTask, description: e.target.value })}
          className="task-description-input"
        />
        <div className="task-selects">
          <select
            value={editedTask.status}
            onChange={(e) => setEditedTask({ ...editedTask, status: e.target.value })}
          >
            <option value="pending">Pending</option>
            <option value="in-progress">In Progress</option>
            <option value="completed">Completed</option>
          </select>
          <select
            value={editedTask.priority}
            onChange={(e) => setEditedTask({ ...editedTask, priority: e.target.value })}
          >
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
          </select>
        </div>
        <div className="task-actions">
          <button onClick={handleSave} className="btn-save">Save</button>
          <button onClick={handleCancel} className="btn-cancel">Cancel</button>
        </div>
      </div>
    );
  }

  return (
    <div className="task-item">
      <div className="task-header">
        <h3 className="task-title">{task.title}</h3>
        <div className="task-badges">
          <span
            className="badge priority"
            style={{ backgroundColor: getPriorityColor(task.priority) }}
          >
            {task.priority}
          </span>
          <span
            className="badge status"
            style={{ backgroundColor: getStatusColor(task.status) }}
          >
            {task.status}
          </span>
        </div>
      </div>
      {task.description && (
        <p className="task-description">{task.description}</p>
      )}
      <div className="task-footer">
        <span className="task-date">
          Created: {new Date(task.created_at).toLocaleDateString()}
        </span>
        <div className="task-actions">
          <button onClick={() => setIsEditing(true)} className="btn-edit">
            Edit
          </button>
          <button onClick={() => onDelete(task.id)} className="btn-delete">
            Delete
          </button>
        </div>
      </div>
    </div>
  );
};

export default TaskItem;

