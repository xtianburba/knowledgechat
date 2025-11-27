#!/bin/bash
# Script para liberar el puerto 3001

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Verificando qué está usando el puerto 3001...${NC}"
echo ""

# Ver qué proceso está usando el puerto 3001
PID=$(lsof -ti:3001 2>/dev/null || netstat -tlnp 2>/dev/null | grep ':3001' | awk '{print $7}' | cut -d'/' -f1 | head -1 || ss -tlnp 2>/dev/null | grep ':3001' | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | head -1 || echo "")

if [ -z "$PID" ] || [ "$PID" = "" ]; then
    echo -e "${YELLOW}No se encontró ningún proceso usando el puerto 3001${NC}"
    echo "Intentando con otros métodos..."
    
    # Intentar con fuser
    if command -v fuser &> /dev/null; then
        PID=$(fuser 3001/tcp 2>/dev/null | awk '{print $1}' | head -1 || echo "")
    fi
fi

if [ ! -z "$PID" ] && [ "$PID" != "" ]; then
    echo -e "${YELLOW}Proceso encontrado usando puerto 3001: PID $PID${NC}"
    
    # Ver qué proceso es
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Información del proceso:"
        ps -fp "$PID" || ps -p "$PID" -o pid,cmd
        echo ""
        
        echo -e "${YELLOW}¿Deseas matar este proceso? [y/N]${NC}"
        read -t 5 -r response || response="y"
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "Matando proceso $PID..."
            kill -9 "$PID" 2>/dev/null || true
            sleep 1
            echo -e "${GREEN}✓ Proceso terminado${NC}"
        fi
    else
        echo "El proceso ya no existe, pero el puerto puede estar en TIME_WAIT"
    fi
else
    echo -e "${YELLOW}No se pudo identificar el proceso automáticamente${NC}"
    echo ""
    echo "Verificando procesos manualmente..."
    echo ""
    echo "Procesos relacionados con node/serve:"
    ps aux | grep -E "node|serve|3001" | grep -v grep || echo "No encontrados"
    echo ""
    
    echo "Intentando detener todos los procesos de PM2 relacionados con frontend..."
    pm2 stop osac-frontend 2>/dev/null || true
    pm2 delete osac-frontend 2>/dev/null || true
    
    # Esperar un poco
    sleep 2
    
    # Verificar de nuevo
    PID=$(lsof -ti:3001 2>/dev/null || echo "")
    if [ ! -z "$PID" ]; then
        echo "Forzando terminación del proceso $PID..."
        kill -9 "$PID" 2>/dev/null || true
    fi
fi

echo ""
echo -e "${GREEN}Verificando que el puerto 3001 esté libre...${NC}"
sleep 1

if lsof -ti:3001 > /dev/null 2>&1 || netstat -tlnp 2>/dev/null | grep -q ':3001' || ss -tlnp 2>/dev/null | grep -q ':3001'; then
    echo -e "${RED}⚠ El puerto 3001 todavía está en uso${NC}"
    echo "Ejecuta manualmente:"
    echo "  lsof -ti:3001 | xargs kill -9"
    echo "  o"
    echo "  fuser -k 3001/tcp"
else
    echo -e "${GREEN}✓ Puerto 3001 está libre${NC}"
    echo ""
    echo "Ahora puedes iniciar el frontend con:"
    echo "  pm2 start ecosystem.config.js --only osac-frontend"
fi

echo ""

