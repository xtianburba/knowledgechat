import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Navbar.css';

const Navbar = () => {
  const { user, logout, isAdmin, isSupervisor } = useAuth();
  const navigate = useNavigate();
  const [toolsMenuOpen, setToolsMenuOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <div className="navbar-brand">
          <Link to="/chat">
            <img src="/logo.png" alt="OSAC Knowledge Bot Logo" className="navbar-logo" />
            <span>OSAC Knowledge Bot</span>
          </Link>
        </div>
        <div className="navbar-menu">
          <Link to="/chat" className="navbar-link">
            Chat
          </Link>
          {isSupervisor && (
            <>
              <Link to="/knowledge" className="navbar-link">
                Conocimiento
              </Link>
              <Link to="/analytics" className="navbar-link">
                Informes
              </Link>
            </>
          )}
          {isAdmin && (
            <Link to="/users" className="navbar-link">
              Usuarios
            </Link>
          )}
          <div 
            className="navbar-dropdown"
            onMouseEnter={() => setToolsMenuOpen(true)}
            onMouseLeave={() => setToolsMenuOpen(false)}
          >
            <button className="navbar-link navbar-dropdown-toggle">
              Herramientas
            </button>
            {toolsMenuOpen && (
              <div className="navbar-dropdown-menu">
                {(isAdmin || isSupervisor) && (
                  <a 
                    href="https://dashboard.perfumesclub-helping.com/" 
                    target="_blank" 
                    rel="noopener noreferrer"
                    className="navbar-dropdown-item"
                  >
                    Dashboard
                  </a>
                )}
                <a 
                  href="https://labellens.perfumesclub-helping.com/" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="navbar-dropdown-item"
                >
                  LabelLens
                </a>
              </div>
            )}
          </div>
          <div className="navbar-user">
            <span className="navbar-username">{user?.username}</span>
            {user?.role === 'admin' && <span className="navbar-badge">Admin</span>}
            {user?.role === 'supervisor' && <span className="navbar-badge" style={{backgroundColor: '#ff9800'}}>Supervisor</span>}
            {!user?.role || user?.role === 'user' ? <span className="navbar-badge" style={{backgroundColor: '#666'}}>Usuario</span> : null}
            <button onClick={handleLogout} className="btn btn-secondary btn-sm">
              Cerrar Sesión
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;


