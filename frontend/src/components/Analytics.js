import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Analytics.css';

const Analytics = () => {
  const [loading, setLoading] = useState(true);
  const [overview, setOverview] = useState(null);
  const [questionsByDay, setQuestionsByDay] = useState([]);
  const [topQuestions, setTopQuestions] = useState([]);
  const [topDocuments, setTopDocuments] = useState([]);
  const [topUsers, setTopUsers] = useState([]);
  const [peakHours, setPeakHours] = useState([]);
  const [documentSources, setDocumentSources] = useState([]);
  const [unusedDocuments, setUnusedDocuments] = useState([]);
  const [selectedDays, setSelectedDays] = useState(30);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    fetchAllData();
  }, [selectedDays]);

  const fetchAllData = async () => {
    setLoading(true);
    try {
      const [overviewRes, questionsByDayRes, topQuestionsRes, topDocumentsRes, topUsersRes, peakHoursRes, sourcesRes, unusedRes] = await Promise.all([
        axios.get(`/api/analytics/overview?days=${selectedDays}`),
        axios.get(`/api/analytics/questions-by-day?days=7`),
        axios.get(`/api/analytics/top-questions?days=${selectedDays}&limit=10`),
        axios.get(`/api/analytics/top-documents?limit=10`),
        axios.get(`/api/analytics/top-users?days=${selectedDays}&limit=10`),
        axios.get(`/api/analytics/peak-hours?days=${selectedDays}`),
        axios.get(`/api/analytics/document-sources`),
        axios.get(`/api/analytics/unused-documents`)
      ]);

      setOverview(overviewRes.data);
      setQuestionsByDay(questionsByDayRes.data);
      setTopQuestions(topQuestionsRes.data);
      setTopDocuments(topDocumentsRes.data);
      setTopUsers(topUsersRes.data);
      setPeakHours(peakHoursRes.data);
      setDocumentSources(sourcesRes.data);
      setUnusedDocuments(unusedRes.data);
    } catch (error) {
      console.error('Error fetching analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('es-ES', { day: '2-digit', month: '2-digit' });
  };

  const formatSource = (source) => {
    const sourceMap = {
      'manual': 'Manual',
      'zendesk': 'Zendesk',
      'url': 'URL'
    };
    return sourceMap[source] || source;
  };

  const getMaxCount = (data) => {
    if (!data || data.length === 0) return 1;
    return Math.max(...data.map(item => item.count || 0), 1);
  };

  if (loading) {
    return (
      <div className="analytics-container">
        <div className="loading">Cargando informes de usabilidad...</div>
      </div>
    );
  }

  return (
    <div className="analytics-container">
      <div className="analytics-header">
        <h1>Informes de Usabilidad</h1>
        <div className="analytics-filters">
          <label htmlFor="days-filter" className="filter-label">
            Período:
          </label>
          <select
            id="days-filter"
            className="filter-select"
            value={selectedDays}
            onChange={(e) => setSelectedDays(parseInt(e.target.value))}
          >
            <option value={7}>Últimos 7 días</option>
            <option value={30}>Últimos 30 días</option>
            <option value={90}>Últimos 90 días</option>
            <option value={365}>Último año</option>
          </select>
        </div>
      </div>

      {/* Overview Cards */}
      {overview && (
        <div className="analytics-cards">
          <div className="analytics-card">
            <div className="card-icon">💬</div>
            <div className="card-content">
              <div className="card-value">{overview.total_questions}</div>
              <div className="card-label">Total de Preguntas</div>
            </div>
          </div>
          <div className="analytics-card">
            <div className="card-icon">👥</div>
            <div className="card-content">
              <div className="card-value">{overview.active_users}</div>
              <div className="card-label">Usuarios Activos</div>
              <div className="card-sublabel">de {overview.total_users} totales</div>
            </div>
          </div>
          <div className="analytics-card">
            <div className="card-icon">📊</div>
            <div className="card-content">
              <div className="card-value">{overview.avg_questions_per_user}</div>
              <div className="card-label">Promedio por Usuario</div>
            </div>
          </div>
          <div className="analytics-card">
            <div className="card-icon">📄</div>
            <div className="card-content">
              <div className="card-value">{overview.total_documents}</div>
              <div className="card-label">Documentos</div>
            </div>
          </div>
          <div className="analytics-card">
            <div className="card-icon">⚠️</div>
            <div className="card-content">
              <div className="card-value">{overview.questions_no_context}</div>
              <div className="card-label">Sin Respuesta</div>
            </div>
          </div>
          <div className="analytics-card">
            <div className="card-icon">⚡</div>
            <div className="card-content">
              <div className="card-value card-value-small">{Math.round(overview.avg_response_time_ms)}ms</div>
              <div className="card-label">Tiempo Respuesta</div>
            </div>
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="analytics-tabs">
        <button
          className={`tab-button ${activeTab === 'overview' ? 'active' : ''}`}
          onClick={() => setActiveTab('overview')}
        >
          Resumen
        </button>
        <button
          className={`tab-button ${activeTab === 'questions' ? 'active' : ''}`}
          onClick={() => setActiveTab('questions')}
        >
          Preguntas
        </button>
        <button
          className={`tab-button ${activeTab === 'documents' ? 'active' : ''}`}
          onClick={() => setActiveTab('documents')}
        >
          Documentos
        </button>
        <button
          className={`tab-button ${activeTab === 'users' ? 'active' : ''}`}
          onClick={() => setActiveTab('users')}
        >
          Usuarios
        </button>
      </div>

      {/* Tab Content */}
      <div className="analytics-content">
        {activeTab === 'overview' && (
          <div className="analytics-grid">
            {/* Questions by Day Chart */}
            <div className="analytics-section card">
              <h2>Preguntas por Día (Últimos 7 días)</h2>
              <div className="chart-container">
                <div className="bar-chart">
                  {questionsByDay.map((item, index) => {
                    const maxCount = getMaxCount(questionsByDay);
                    const height = maxCount > 0 ? (item.count / maxCount) * 100 : 0;
                    return (
                      <div key={index} className="bar-item">
                        <div
                          className="bar"
                          style={{ height: `${height}%`, backgroundColor: '#9c27b0' }}
                          title={`${item.count} preguntas`}
                        >
                          <span className="bar-value">{item.count}</span>
                        </div>
                        <div className="bar-label">{formatDate(item.date)}</div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Peak Hours Chart */}
            <div className="analytics-section card">
              <h2>Horas Pico de Uso</h2>
              <div className="chart-container">
                <div className="bar-chart horizontal">
                  {peakHours
                    .filter(item => item.count > 0)
                    .sort((a, b) => b.count - a.count)
                    .slice(0, 10)
                    .map((item, index) => {
                      const maxCount = getMaxCount(peakHours);
                      const width = maxCount > 0 ? (item.count / maxCount) * 100 : 0;
                      return (
                        <div key={index} className="bar-item horizontal">
                          <div className="bar-label">{item.hour}:00</div>
                          <div className="bar-wrapper">
                            <div
                              className="bar horizontal-bar"
                              style={{ width: `${width}%`, backgroundColor: '#e91e63' }}
                              title={`${item.count} preguntas`}
                            >
                              <span className="bar-value">{item.count}</span>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                </div>
              </div>
            </div>

            {/* Document Sources */}
            <div className="analytics-section card">
              <h2>Distribución por Fuente</h2>
              <div className="sources-list">
                {documentSources.map((item, index) => (
                  <div key={index} className="source-item">
                    <span className="source-name">{formatSource(item.source)}</span>
                    <span className="source-count">{item.count}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'questions' && (
          <div className="analytics-section card">
            <h2>Top 10 Preguntas Más Frecuentes</h2>
            <div className="top-questions-list">
              {topQuestions.length > 0 ? (
                topQuestions.map((item, index) => (
                  <div key={index} className="top-question-item">
                    <span className="question-rank">#{index + 1}</span>
                    <span className="question-text">{item.question}</span>
                    <span className="question-count">{item.count}</span>
                  </div>
                ))
              ) : (
                <p className="empty-message">No hay preguntas registradas en este período</p>
              )}
            </div>
          </div>
        )}

        {activeTab === 'documents' && (
          <div className="analytics-grid">
            <div className="analytics-section card">
              <h2>Top 10 Documentos Más Consultados</h2>
              <div className="documents-list">
                {topDocuments.length > 0 ? (
                  topDocuments.map((doc, index) => (
                    <div key={doc.id} className="document-item">
                      <div className="document-header">
                        <span className="document-rank">#{index + 1}</span>
                        <h3 className="document-title">{doc.title}</h3>
                      </div>
                      <div className="document-meta">
                        <span className="badge badge-source">{formatSource(doc.source)}</span>
                        <span className="document-stats">
                          {doc.times_used} consultas
                          {doc.last_used_at && (
                            <span className="last-used">
                              Última: {formatDate(doc.last_used_at)}
                            </span>
                          )}
                        </span>
                      </div>
                      {doc.url && (
                        <a
                          href={doc.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="document-url"
                        >
                          Ver documento →
                        </a>
                      )}
                    </div>
                  ))
                ) : (
                  <p className="empty-message">No hay documentos consultados aún</p>
                )}
              </div>
            </div>

            <div className="analytics-section card">
              <h2>Documentos Sin Usar</h2>
              <div className="unused-documents-list">
                {unusedDocuments.length > 0 ? (
                  <>
                    <p className="unused-count">Total: {unusedDocuments.length} documentos</p>
                    <div className="documents-list">
                      {unusedDocuments.slice(0, 10).map((doc) => (
                        <div key={doc.id} className="document-item unused">
                          <div className="document-header">
                            <h3 className="document-title">{doc.title}</h3>
                          </div>
                          <div className="document-meta">
                            <span className="badge badge-source">{formatSource(doc.source)}</span>
                            <span className="created-date">
                              Creado: {formatDate(doc.created_at)}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                    {unusedDocuments.length > 10 && (
                      <p className="more-items">... y {unusedDocuments.length - 10} más</p>
                    )}
                  </>
                ) : (
                  <p className="empty-message">¡Todos los documentos han sido consultados!</p>
                )}
              </div>
            </div>
          </div>
        )}

        {activeTab === 'users' && (
          <div className="analytics-section card">
            <h2>Top 10 Usuarios Más Activos</h2>
            <div className="users-list">
              {topUsers.length > 0 ? (
                topUsers.map((user, index) => (
                  <div key={user.id} className="user-item">
                    <div className="user-info">
                      <span className="user-rank">#{index + 1}</span>
                      <div>
                        <span className="user-name">{user.username}</span>
                        <span className="user-badge" data-role={user.role}>
                          {user.role === 'admin' ? 'Admin' : user.role === 'supervisor' ? 'Supervisor' : 'Usuario'}
                        </span>
                      </div>
                    </div>
                    <div className="user-stats">
                      <span className="question-count">{user.question_count} preguntas</span>
                      {user.last_activity && (
                        <span className="last-activity">
                          Última: {formatDate(user.last_activity)}
                        </span>
                      )}
                    </div>
                  </div>
                ))
              ) : (
                <p className="empty-message">No hay usuarios activos en este período</p>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Analytics;

