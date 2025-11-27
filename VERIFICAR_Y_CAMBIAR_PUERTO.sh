#!/bin/bash
# Script seguro para verificar qué usa el puerto 3001 y cambiar si es necesario

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Verificación Segura del Puerto 3001${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar qué está usando el puerto 3001
echo -e "${YELLOW}[1/4] Verificando qué está usando el puerto 3001...${NC}"
echo ""

PID=""
PROCESS_INFO=""

# Intentar diferentes métodos para encontrar el proceso
if command -v lsof &> /dev/null; then
    PID=$(lsof -ti:3001 2>/dev/null || echo "")
    if [ ! -z "$PID" ]; then
        PROCESS_INFO=$(ps -fp "$PID" 2>/dev/null || ps -p "$PID" -o pid,cmd 2>/dev/null || echo "")
    fi
elif command -v netstat &> /dev/null; then
    PID=$(netstat -tlnp 2>/dev/null | grep ':3001' | awk '{print $7}' | cut -d'/' -f1 | head -1 || echo "")
elif command -v ss &> /dev/null; then
    PID=$(ss -tlnp 2>/dev/null | grep ':3001' | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | head -1 || echo "")
fi

if [ ! -z "$PID" ] && [ "$PID" != "" ]; then
    echo -e "${RED}⚠ El puerto 3001 está en uso por el proceso PID: $PID${NC}"
    echo ""
    echo "Información del proceso:"
    if [ ! -z "$PROCESS_INFO" ]; then
        echo "$PROCESS_INFO"
    else
        ps -p "$PID" -o pid,cmd 2>/dev/null || echo "No se pudo obtener información"
    fi
    echo ""
    
    # Verificar si es un proceso de PM2
    if pm2 list 2>/dev/null | grep -q "$PID"; then
        PM2_NAME=$(pm2 jlist 2>/dev/null | jq -r ".[] | select(.pid==$PID) | .name" 2>/dev/null || echo "")
        if [ ! -z "$PM2_NAME" ]; then
            echo -e "${YELLOW}Este proceso está gestionado por PM2: $PM2_NAME${NC}"
            echo ""
            
            if [ "$PM2_NAME" = "osac-frontend" ]; then
                echo -e "${GREEN}Es nuestro frontend. Podemos reiniciarlo.${NC}"
            else
                echo -e "${RED}⚠ Es otra aplicación ($PM2_NAME). NO debemos matarla.${NC}"
                echo ""
                echo "Solución: Cambiar el puerto del frontend a otro puerto libre."
            fi
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}¿Deseas cambiar el puerto del frontend a otro (ej: 3002)? [S/n]${NC}"
    read -t 10 -r response || response="s"
    
    if [[ "$response" =~ ^[Ss]$ ]] || [ -z "$response" ]; then
        NEW_PORT="3002"
        
        # Verificar que el nuevo puerto esté libre
        while true; do
            if lsof -ti:$NEW_PORT > /dev/null 2>&1 || netstat -tlnp 2>/dev/null | grep -q ":$NEW_PORT" || ss -tlnp 2>/dev/null | grep -q ":$NEW_PORT"; then
                echo "Puerto $NEW_PORT también en uso, probando siguiente..."
                NEW_PORT=$((NEW_PORT + 1))
            else
                break
            fi
            
            # Evitar loop infinito
            if [ "$NEW_PORT" -gt "3010" ]; then
                echo -e "${RED}Error: No se encontró un puerto libre entre 3002-3010${NC}"
                exit 1
            fi
        done
        
        echo ""
        echo -e "${YELLOW}[2/4] Cambiando frontend al puerto $NEW_PORT...${NC}"
        
        # Actualizar ecosystem.config.js
        cd /opt/osac-knowledge-bot
        if [ -f "ecosystem.config.js" ]; then
            # Backup
            cp ecosystem.config.js ecosystem.config.js.bak
            
            # Cambiar puerto
            sed -i "s/PORT: 3001/PORT: $NEW_PORT/g" ecosystem.config.js
            sed -i "s/-l 3001/-l $NEW_PORT/g" ecosystem.config.js
            sed -i "s/3001/$NEW_PORT/g" ecosystem.config.js 2>/dev/null || true
            
            echo -e "${GREEN}✓ ecosystem.config.js actualizado${NC}"
        fi
        
        # Actualizar serve-frontend.sh si existe
        if [ -f "frontend/serve-frontend.sh" ]; then
            sed -i "s/-l 3001/-l $NEW_PORT/g" frontend/serve-frontend.sh
            echo -e "${GREEN}✓ serve-frontend.sh actualizado${NC}"
        fi
        
        # Actualizar configuración de Apache
        echo ""
        echo -e "${YELLOW}[3/4] Actualizando configuración de Apache...${NC}"
        if [ -f "/etc/apache2/sites-available/osac-knowledge-bot.conf" ]; then
            # Backup
            cp /etc/apache2/sites-available/osac-knowledge-bot.conf /etc/apache2/sites-available/osac-knowledge-bot.conf.bak
            
            # Cambiar puerto en Apache
            sed -i "s/localhost:3001/localhost:$NEW_PORT/g" /etc/apache2/sites-available/osac-knowledge-bot.conf
            
            # Recargar Apache
            systemctl reload apache2
            
            echo -e "${GREEN}✓ Apache actualizado y recargado${NC}"
        fi
        
        echo ""
        echo -e "${YELLOW}[4/4] Reiniciando frontend...${NC}"
        pm2 stop osac-frontend 2>/dev/null || true
        pm2 delete osac-frontend 2>/dev/null || true
        sleep 1
        
        pm2 start ecosystem.config.js --only osac-frontend
        pm2 save
        
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✅ Frontend cambiado al puerto $NEW_PORT${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        echo "El frontend ahora está en:"
        echo "  - http://localhost:$NEW_PORT"
        echo "  - http://osac-knowledge-bot.perfumesclub-helping.com"
        echo ""
        
    else
        echo "Operación cancelada."
        exit 0
    fi
    
else
    echo -e "${GREEN}✓ Puerto 3001 está libre${NC}"
    echo ""
    echo "Puedes usar el puerto 3001 normalmente."
fi

echo ""

