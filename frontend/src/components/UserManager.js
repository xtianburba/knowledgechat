import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './UserManager.css';

const UserManager = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [message, setMessage] = useState({ type: '', text: '' });
  
  // Form state
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    is_admin: false,
    role: 'user',
  });

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const response = await axios.get('/api/users');
      setUsers(response.data);
    } catch (error) {
      setMessage({ 
        type: 'error', 
        text: error.response?.data?.detail || 'Error al cargar usuarios' 
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage({ type: '', text: '' });

    try {
      if (editingUser) {
        // Update user - always include username and email even if unchanged
        const updateData = {
          username: formData.username,
          email: formData.email,
        };
        
        // Only include password if provided
        if (formData.password) {
          updateData.password = formData.password;
        }
        
        // Include role
        if (formData.role) {
          updateData.role = formData.role;
        }
        
        // Keep is_admin for backward compatibility
        if (formData.is_admin !== undefined) {
          updateData.is_admin = formData.is_admin;
        }

        await axios.put(`/api/users/${editingUser.id}`, updateData);
        setMessage({ type: 'success', text: 'Usuario actualizado exitosamente' });
      } else {
        // Create user
        await axios.post('/api/users', formData);
        setMessage({ type: 'success', text: 'Usuario creado exitosamente' });
      }
      
      fetchUsers();
      setFormData({ username: '', email: '', password: '', is_admin: false, role: 'user' });
      setShowAddForm(false);
      setEditingUser(null);
    } catch (error) {
      setMessage({
        type: 'error',
        text: error.response?.data?.detail || 'Error al guardar usuario',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (user) => {
    setEditingUser(user);
    setFormData({
      username: user.username,
      email: user.email,
      password: '',
      is_admin: user.is_admin,
      role: user.role || (user.is_admin ? 'admin' : 'user'),
    });
    setShowAddForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('¿Estás seguro de que deseas eliminar este usuario?')) {
      return;
    }

    try {
      await axios.delete(`/api/users/${id}`);
      setMessage({ type: 'success', text: 'Usuario eliminado exitosamente' });
      fetchUsers();
    } catch (error) {
      setMessage({
        type: 'error',
        text: error.response?.data?.detail || 'Error al eliminar usuario',
      });
    }
  };

  const handleCancel = () => {
    setShowAddForm(false);
    setEditingUser(null);
    setFormData({ username: '', email: '', password: '', is_admin: false, role: 'user' });
  };

  return (
    <div className="user-manager-container">
      <div className="user-manager-header">
        <h1>Gestión de Usuarios</h1>
        <button
          className="btn btn-primary"
          onClick={() => setShowAddForm(true)}
          disabled={showAddForm}
        >
          Añadir Usuario
        </button>
      </div>

      {message.text && (
        <div className={`message message-${message.type}`}>
          {message.text}
          <button
            className="message-close"
            onClick={() => setMessage({ type: '', text: '' })}
          >
            ×
          </button>
        </div>
      )}

      {showAddForm && (
        <div className="card user-form-card">
          <h2 className="card-header">
            {editingUser ? 'Editar Usuario' : 'Añadir Nuevo Usuario'}
          </h2>
          <form onSubmit={handleSubmit} className="user-form">
            <div className="form-group">
              <label className="form-label">Usuario</label>
              <input
                type="text"
                className="form-input"
                value={formData.username}
                onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                type="email"
                className="form-input"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">
                {editingUser ? 'Nueva Contraseña (dejar vacío para no cambiar)' : 'Contraseña'}
              </label>
              <input
                type="password"
                className="form-input"
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                required={!editingUser}
                minLength={6}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Rol</label>
              <select
                className="form-input"
                value={formData.role}
                onChange={(e) => {
                  const newRole = e.target.value;
                  setFormData({ 
                    ...formData, 
                    role: newRole,
                    is_admin: newRole === 'admin' // Keep is_admin in sync
                  });
                }}
                required
              >
                <option value="user">Usuario</option>
                <option value="supervisor">Supervisor</option>
                <option value="admin">Administrador</option>
              </select>
            </div>

            <div className="form-actions">
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? 'Guardando...' : editingUser ? 'Actualizar' : 'Crear'}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={handleCancel}
                disabled={loading}
              >
                Cancelar
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="user-stats">
        <p>Total de usuarios: {users.length}</p>
      </div>

      {loading && !showAddForm && (
        <div className="loading">Cargando usuarios...</div>
      )}

      <div className="user-list">
        {users.map((user) => (
          <div key={user.id} className="card user-card">
            <div className="user-header">
              <div>
                <h3>{user.username}</h3>
                <p className="user-email">{user.email}</p>
              </div>
              <div className="user-badges">
                {user.role === 'admin' && <span className="badge badge-admin">Admin</span>}
                {user.role === 'supervisor' && <span className="badge" style={{backgroundColor: '#ff9800'}}>Supervisor</span>}
                {(!user.role || user.role === 'user') && <span className="badge" style={{backgroundColor: '#666'}}>Usuario</span>}
                <span className="badge badge-date">
                  Creado: {new Date(user.created_at).toLocaleDateString('es-ES')}
                </span>
              </div>
            </div>

            <div className="user-actions">
              <button
                className="btn btn-secondary btn-sm"
                onClick={() => handleEdit(user)}
              >
                Editar
              </button>
              <button
                className="btn btn-danger btn-sm"
                onClick={() => handleDelete(user.id)}
              >
                Eliminar
              </button>
            </div>
          </div>
        ))}
      </div>

      {users.length === 0 && !loading && (
        <div className="empty-state">
          <p>No hay usuarios registrados.</p>
        </div>
      )}
    </div>
  );
};

export default UserManager;


