import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [token, setToken] = useState(localStorage.getItem('token'));

  useEffect(() => {
    // Configure axios defaults
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      fetchUser();
    } else {
      setLoading(false);
    }
  }, [token]);

  const fetchUser = async () => {
    try {
      const response = await axios.get('/api/auth/me');
      setUser(response.data);
    } catch (error) {
      console.error('Error fetching user:', error);
      logout();
    } finally {
      setLoading(false);
    }
  };

  const login = async (username, password) => {
    try {
      // First, check if backend is accessible
      try {
        const healthCheck = await axios.get('/api/health', { timeout: 3000 });
        console.log('Backend health check:', healthCheck.data);
      } catch (healthError) {
        console.error('Backend health check failed:', healthError);
        return {
          success: false,
          error: 'No se pudo conectar con el servidor. Verifica que el backend esté corriendo en http://localhost:8000',
        };
      }
      
      // Configure axios timeout
      console.log('Attempting login for user:', username);
      const response = await axios.post(
        '/api/auth/login',
        {
          username,
          password,
        },
        {
          timeout: 10000, // 10 seconds timeout
          headers: {
            'Content-Type': 'application/json',
          }
        }
      );
      
      if (!response.data || !response.data.access_token) {
        return {
          success: false,
          error: 'Respuesta inválida del servidor',
        };
      }
      
      const { access_token, user: userData } = response.data;
      setToken(access_token);
      setUser(userData);
      localStorage.setItem('token', access_token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${access_token}`;
      return { success: true };
    } catch (error) {
      console.error('Login error:', error);
      
      if (error.code === 'ECONNABORTED' || error.message.includes('timeout')) {
        return {
          success: false,
          error: 'Tiempo de espera agotado. Verifica que el backend esté corriendo en http://localhost:8000',
        };
      }
      
      if (error.response) {
        // Server responded with error
        return {
          success: false,
          error: error.response?.data?.detail || 'Error al iniciar sesión',
        };
      } else if (error.request) {
        // Request was made but no response received
        return {
          success: false,
          error: 'No se pudo conectar con el servidor. Verifica que el backend esté corriendo en http://localhost:8000',
        };
      } else {
        // Something else happened
        return {
          success: false,
          error: error.message || 'Error desconocido al iniciar sesión',
        };
      }
    }
  };

  const register = async (username, email, password) => {
    try {
      await axios.post('/api/auth/register', {
        username,
        email,
        password,
      });
      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.detail || 'Error al registrar usuario',
      };
    }
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    localStorage.removeItem('token');
    delete axios.defaults.headers.common['Authorization'];
  };

  // Helper functions for role checking
  const getUserRole = () => {
    if (!user) return null;
    return user.role || (user.is_admin ? "admin" : "user");
  };

  const isAdmin = () => {
    const role = getUserRole();
    return role === "admin" || user?.is_admin === true;
  };

  const isSupervisor = () => {
    const role = getUserRole();
    return role === "supervisor" || role === "admin" || user?.is_admin === true;
  };

  const value = {
    user,
    token,
    loading,
    isAuthenticated: !!token && !!user,
    isAdmin: isAdmin(),
    isSupervisor: isSupervisor(),
    userRole: getUserRole(),
    login,
    register,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};


