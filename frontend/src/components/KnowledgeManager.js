import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './KnowledgeManager.css';

const KnowledgeManager = () => {
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingEntry, setEditingEntry] = useState(null);
  const [message, setMessage] = useState({ type: '', text: '' });
  const [syncStatus, setSyncStatus] = useState(null);
  const [selectedSource, setSelectedSource] = useState('');
  const [availableSources, setAvailableSources] = useState([]);
  
  // Form state
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    url: '',
  });

  useEffect(() => {
    fetchEntries();
    fetchSyncStatus();
    fetchSources();
  }, []);

  useEffect(() => {
    // Refetch entries when filter changes (only if component is mounted)
    fetchEntries();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedSource]);

  const fetchSyncStatus = async () => {
    try {
      const response = await axios.get('/api/knowledge/sync/zendesk/status');
      setSyncStatus(response.data);
    } catch (error) {
      console.error('Error fetching sync status:', error);
    }
  };

  const fetchSources = async () => {
    try {
      const response = await axios.get('/api/knowledge/sources');
      setAvailableSources(response.data.sources || []);
    } catch (error) {
      console.error('Error fetching sources:', error);
    }
  };

  const fetchEntries = async () => {
    setLoading(true);
    try {
      const params = {};
      if (selectedSource) {
        params.source = selectedSource;
      }
      const response = await axios.get('/api/knowledge', { params });
      setEntries(response.data);
    } catch (error) {
      setMessage({ type: 'error', text: 'Error al cargar entradas' });
    } finally {
      setLoading(false);
    }
  };

  const handleSyncZendesk = async () => {
    if (!window.confirm('¿Deseas sincronizar con Zendesk? Esto puede tardar varios minutos.')) {
      return;
    }

    setSyncing(true);
    setMessage({ type: 'info', text: 'Sincronizando con Zendesk...' });

    try {
      const response = await axios.post('/api/knowledge/sync/zendesk');
      setMessage({
        type: 'success',
        text: `Sincronización completada: ${response.data.added} añadidos, ${response.data.updated} actualizados`,
      });
      fetchEntries();
      fetchSources(); // Refresh sources list
    } catch (error) {
      setMessage({
        type: 'error',
        text: error.response?.data?.detail || 'Error al sincronizar con Zendesk',
      });
    } finally {
      setSyncing(false);
    }
  };

  const handleAddFromURL = async () => {
    const url = prompt('Ingresa la URL a añadir:');
    if (!url) return;

    // Validate URL format
    try {
      new URL(url);
    } catch (e) {
      setMessage({
        type: 'error',
        text: 'URL inválida. Por favor, ingresa una URL válida (ej: https://ejemplo.com)',
      });
      return;
    }

    setLoading(true);
    setMessage({ type: '', text: '' });
    
    try {
      const formData = new FormData();
      formData.append('url', url);
      
      await axios.post('/api/knowledge/from-url', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      
      setMessage({ type: 'success', text: 'URL añadida exitosamente' });
      fetchEntries();
      fetchSources(); // Refresh sources list in case a new source type was added
      setFormData({ title: '', content: '', url: '' });
    } catch (error) {
      console.error('Error adding URL:', error);
      setMessage({
        type: 'error',
        text: error.response?.data?.detail || error.message || 'Error al añadir URL. Verifica que la URL sea accesible.',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (editingEntry) {
        await axios.put(`/api/knowledge/${editingEntry.id}`, formData);
        setMessage({ type: 'success', text: 'Entrada actualizada exitosamente' });
      } else {
        await axios.post('/api/knowledge', formData);
        setMessage({ type: 'success', text: 'Entrada añadida exitosamente' });
      }
      
      fetchEntries();
      fetchSources(); // Refresh sources list in case a new source type was added
      setFormData({ title: '', content: '', url: '' });
      setShowAddForm(false);
      setEditingEntry(null);
    } catch (error) {
      setMessage({
        type: 'error',
        text: error.response?.data?.detail || 'Error al guardar entrada',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (entry) => {
    setEditingEntry(entry);
    setFormData({
      title: entry.title,
      content: entry.content,
      url: entry.url || '',
    });
    setShowAddForm(true);
  };

  const handleDelete = async (id) => {
    if (!window.confirm('¿Estás seguro de que deseas eliminar esta entrada?')) {
      return;
    }

    try {
      await axios.delete(`/api/knowledge/${id}`);
      setMessage({ type: 'success', text: 'Entrada eliminada exitosamente' });
      fetchEntries();
    } catch (error) {
      setMessage({
        type: 'error',
        text: error.response?.data?.detail || 'Error al eliminar entrada',
      });
    }
  };

  const handleCancel = () => {
    setShowAddForm(false);
    setEditingEntry(null);
    setFormData({ title: '', content: '', url: '' });
  };

  return (
    <div className="knowledge-container">
      <div className="knowledge-header">
        <h1>Gestión de Base de Conocimiento</h1>
        <div className="knowledge-actions">
          {syncStatus && syncStatus.zendesk_configured && (
            <div className="sync-status-info">
              {syncStatus.auto_sync_enabled ? (
                <span className="sync-status-badge sync-enabled">
                  ✓ Sincronización automática activa
                  {syncStatus.next_run && (
                    <span className="sync-next-run">
                      (Próxima: {new Date(syncStatus.next_run).toLocaleString('es-ES')})
                    </span>
                  )}
                </span>
              ) : (
                <span className="sync-status-badge sync-disabled">
                  ⚠ Sincronización automática desactivada
                </span>
              )}
            </div>
          )}
          <button
            className="btn btn-secondary"
            onClick={handleSyncZendesk}
            disabled={syncing}
          >
            {syncing ? 'Sincronizando...' : 'Sincronizar con Zendesk Ahora'}
          </button>
          <button
            className="btn btn-secondary"
            onClick={handleAddFromURL}
            disabled={loading}
          >
            Añadir desde URL
          </button>
          <button
            className="btn btn-primary"
            onClick={() => setShowAddForm(true)}
            disabled={showAddForm}
          >
            Añadir Contenido Manual
          </button>
        </div>
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
        <div className="card knowledge-form-card">
          <h2 className="card-header">
            {editingEntry ? 'Editar Entrada' : 'Añadir Nueva Entrada'}
          </h2>
          <form onSubmit={handleSubmit} className="knowledge-form">
            <div className="form-group">
              <label className="form-label">Título</label>
              <input
                type="text"
                className="form-input"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Contenido</label>
              <textarea
                className="form-textarea"
                value={formData.content}
                onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                required
                rows={10}
              />
            </div>

            <div className="form-group">
              <label className="form-label">URL (opcional)</label>
              <input
                type="url"
                className="form-input"
                value={formData.url}
                onChange={(e) => setFormData({ ...formData, url: e.target.value })}
                placeholder="https://ejemplo.com"
              />
            </div>

            <div className="form-actions">
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? 'Guardando...' : editingEntry ? 'Actualizar' : 'Añadir'}
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

      <div className="knowledge-stats">
        <div className="knowledge-stats-content">
          <p>Total de entradas: {entries.length}</p>
          <div className="knowledge-filter">
            <label htmlFor="source-filter" className="filter-label">
              Filtrar por tipo:
            </label>
            <select
              id="source-filter"
              className="filter-select"
              value={selectedSource}
              onChange={(e) => setSelectedSource(e.target.value)}
            >
              <option value="">Todos los tipos</option>
              {availableSources.map((source) => (
                <option key={source} value={source}>
                  {source === 'manual' ? 'Manual' : source === 'zendesk' ? 'Zendesk' : source === 'url' ? 'URL' : source}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {loading && !showAddForm && (
        <div className="loading">Cargando entradas...</div>
      )}

      <div className="knowledge-entries">
        {entries.map((entry) => (
          <div key={entry.id} className="card knowledge-entry">
            <div className="knowledge-entry-header">
              <h3>{entry.title}</h3>
              <div className="knowledge-entry-actions">
                <button
                  className="btn btn-secondary btn-sm"
                  onClick={() => handleEdit(entry)}
                >
                  Editar
                </button>
                <button
                  className="btn btn-danger btn-sm"
                  onClick={() => handleDelete(entry.id)}
                >
                  Eliminar
                </button>
              </div>
            </div>

            <div className="knowledge-entry-meta">
              <span className="badge badge-source">{entry.source}</span>
              {entry.url && (
                <a
                  href={entry.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="knowledge-entry-url"
                >
                  Ver original
                </a>
              )}
              <span className="knowledge-entry-date">
                {new Date(entry.created_at).toLocaleDateString('es-ES')}
              </span>
            </div>

            <div className="knowledge-entry-content">
              {entry.content.substring(0, 200)}
              {entry.content.length > 200 && '...'}
            </div>
          </div>
        ))}
      </div>

      {entries.length === 0 && !loading && (
        <div className="knowledge-empty">
          <p>No hay entradas en la base de conocimiento.</p>
          <p>Sincroniza con Zendesk o añade contenido manualmente.</p>
        </div>
      )}
    </div>
  );
};

export default KnowledgeManager;


