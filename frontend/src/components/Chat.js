import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import './Chat.css';

const Chat = () => {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);

  // Function to convert markdown links to React elements
  const formatMessage = (text) => {
    if (!text) return text;
    
    // Split by lines to preserve line breaks
    const lines = text.split('\n');
    const result = [];
    
    lines.forEach((line, lineIndex) => {
      if (lineIndex > 0) {
        result.push(<br key={`br-${lineIndex}`} />);
      }
      
      // Convert markdown links [text](url) to HTML links
      const linkRegex = /\[([^\]]+)\]\(([^)]+)\)/g;
      const parts = [];
      let lastIndex = 0;
      let match;
      let linkCounter = 0;
      
      while ((match = linkRegex.exec(line)) !== null) {
        // Add text before the link
        if (match.index > lastIndex) {
          parts.push(line.substring(lastIndex, match.index));
        }
        
        // Add the link as JSX
        parts.push(
          <a
            key={`link-${lineIndex}-${linkCounter++}`}
            href={match[2]}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              color: '#9c27b0',
              textDecoration: 'underline',
              fontWeight: '500'
            }}
          >
            {match[1]}
          </a>
        );
        
        lastIndex = match.index + match[0].length;
      }
      
      // Add remaining text
      if (lastIndex < line.length) {
        parts.push(line.substring(lastIndex));
      } else if (parts.length === 0) {
        // If no links found, add the whole line
        parts.push(line);
      }
      
      result.push(
        <span key={`line-${lineIndex}`}>
          {parts}
        </span>
      );
    });
    
    return result;
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  // Scroll to bottom when messages change
  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Focus input when loading finishes (after receiving response)
  useEffect(() => {
    if (!loading && inputRef.current) {
      // Small delay to ensure the DOM is updated
      setTimeout(() => {
        inputRef.current?.focus();
      }, 100);
    }
  }, [loading]);

  // Focus input on component mount
  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const handleSend = async (e) => {
    e.preventDefault();
    
    if (!input.trim() || loading) return;

    const userMessage = { role: 'user', content: input };
    setMessages((prev) => [...prev, userMessage]);
    const currentInput = input;
    setInput('');
    setLoading(true);
    
    // Focus back to input after clearing
    setTimeout(() => {
      inputRef.current?.focus();
    }, 10);

    try {
      const response = await axios.post('/api/chat', {
        message: input,
      });

      const botMessage = {
        role: 'assistant',
        content: response.data.response,
        sources: response.data.sources || [],
        contextCount: response.data.context_count || 0,
      };

      setMessages((prev) => [...prev, botMessage]);
    } catch (error) {
      const errorMessage = {
        role: 'assistant',
        content: 'Lo siento, hubo un error al procesar tu mensaje. Por favor, intenta de nuevo.',
        error: true,
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setLoading(false);
      // Focus input after response is received
      setTimeout(() => {
        inputRef.current?.focus();
      }, 100);
    }
  };

  return (
    <div className="chat-container">
      <div className="chat-header">
        <h1>Chat con Knowledge Bot</h1>
        <p>Haz preguntas sobre procedimientos, condiciones de envío, manuales, etc.</p>
      </div>

      <div className="chat-messages">
        {messages.length === 0 && (
          <div className="chat-welcome">
            <h2>¡Hola! 👋</h2>
            <p>Pregúntame sobre procedimientos, condiciones de envío, manuales o cualquier información de la base de conocimiento.</p>
            <div className="chat-examples">
              <p>Ejemplos de preguntas:</p>
              <ul>
                <li>¿Cuáles son las condiciones de envío?</li>
                <li>¿Cómo funciona el proceso de devoluciones?</li>
                <li>¿Cuál es el procedimiento para procesar un pedido?</li>
              </ul>
            </div>
          </div>
        )}

        {messages.map((message, index) => (
          <div
            key={index}
            className={`message-wrapper ${
              message.role === 'user' ? 'message-user' : 'message-bot'
            }`}
          >
            <div className="message-content">
              <div className="message-text">{formatMessage(message.content)}</div>
              {message.sources && message.sources.length > 0 && (
                <div className="message-sources">
                  <small>
                    Basado en {message.contextCount} documento(s) de la base de conocimiento
                  </small>
                </div>
              )}
            </div>
          </div>
        ))}

        {loading && (
          <div className="message-wrapper message-bot">
            <div className="message-content">
              <div className="message-loading">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={handleSend} className="chat-input-form">
        <input
          ref={inputRef}
          type="text"
          className="chat-input"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Escribe tu pregunta aquí..."
          disabled={loading}
          autoFocus
        />
        <button
          type="submit"
          className="btn btn-primary"
          disabled={loading || !input.trim()}
        >
          Enviar
        </button>
      </form>
    </div>
  );
};

export default Chat;


