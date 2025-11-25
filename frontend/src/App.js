import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import Chat from './components/Chat';
import KnowledgeManager from './components/KnowledgeManager';
import UserManager from './components/UserManager';
import Analytics from './components/Analytics';
import Navbar from './components/Navbar';
import { AuthProvider, useAuth } from './context/AuthContext';
import './App.css';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  
  if (loading) {
    return <div className="loading">Cargando...</div>;
  }
  
  return isAuthenticated ? children : <Navigate to="/login" />;
};

const AdminRoute = ({ children }) => {
  const { isAuthenticated, isAdmin, loading } = useAuth();
  
  if (loading) {
    return <div className="loading">Cargando...</div>;
  }
  
  if (!isAuthenticated) {
    return <Navigate to="/login" />;
  }
  
  if (!isAdmin) {
    return <div className="error">No tienes permisos para acceder a esta página.</div>;
  }
  
  return children;
};

const SupervisorRoute = ({ children }) => {
  const { isAuthenticated, isSupervisor, loading } = useAuth();
  
  if (loading) {
    return <div className="loading">Cargando...</div>;
  }
  
  if (!isAuthenticated) {
    return <Navigate to="/login" />;
  }
  
  if (!isSupervisor) {
    return <div className="error">No tienes permisos para acceder a esta página.</div>;
  }
  
  return children;
};

function App() {
  return (
    <Router>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </Router>
  );
}

function AppContent() {
  const { isAuthenticated } = useAuth();
  
  return (
    <div className="App">
      {isAuthenticated && <Navbar />}
      <Routes>
        <Route path="/login" element={!isAuthenticated ? <Login /> : <Navigate to="/chat" />} />
        <Route
          path="/chat"
          element={
            <ProtectedRoute>
              <Chat />
            </ProtectedRoute>
          }
        />
        <Route
          path="/knowledge"
          element={
            <SupervisorRoute>
              <KnowledgeManager />
            </SupervisorRoute>
          }
        />
        <Route
          path="/users"
          element={
            <AdminRoute>
              <UserManager />
            </AdminRoute>
          }
        />
        <Route
          path="/analytics"
          element={
            <SupervisorRoute>
              <Analytics />
            </SupervisorRoute>
          }
        />
        <Route path="/" element={<Navigate to="/chat" />} />
      </Routes>
    </div>
  );
}

export default App;

