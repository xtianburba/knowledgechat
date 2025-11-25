# Sincronización con Zendesk - Manual vs Automática

## 📊 Estado Actual

### Sincronización Manual (Por defecto)

Actualmente, la sincronización con Zendesk es **MANUAL**. Esto significa que:

- ✅ Un administrador debe hacer clic en "Sincronizar con Zendesk" en la interfaz
- ✅ Se ejecuta cuando lo necesitas, bajo tu control
- ✅ Puedes ver el progreso y resultados inmediatamente
- ❌ No se actualiza automáticamente

**Ventajas:**
- Control total sobre cuándo sincronizar
- No consume recursos cuando no se necesita
- Puedes elegir el momento adecuado (cuando hay menos tráfico)

**Desventajas:**
- Debes recordar sincronizar manualmente
- Si se añaden artículos en Zendesk, no se reflejan automáticamente

---

## 🔄 Sincronización Automática (Opcional)

He añadido la opción de **sincronización automática programada**. Esto significa que puedes configurar que se sincronice automáticamente cada día a una hora determinada.

### Cómo Activar la Sincronización Automática

#### Opción 1: Variables de Entorno en `.env`

Añade estas variables a tu archivo `backend/.env`:

```env
# Activar sincronización automática con Zendesk
ZENDESK_AUTO_SYNC=true

# Hora de sincronización (24 horas, UTC)
# Ejemplo: 2 = 2:00 AM UTC, 14 = 2:00 PM UTC
ZENDESK_SYNC_HOUR=2

# Minuto de sincronización (0-59)
ZENDESK_SYNC_MINUTE=0
```

**Ejemplo:**
- `ZENDESK_SYNC_HOUR=2` y `ZENDESK_SYNC_MINUTE=0` = Se sincroniza todos los días a las 2:00 AM UTC
- `ZENDESK_SYNC_HOUR=3` y `ZENDESK_SYNC_MINUTE=30` = Se sincroniza todos los días a las 3:30 AM UTC

#### Opción 2: Usando Cron en el Sistema (Alternativa)

Si prefieres usar el cron del sistema en lugar del scheduler interno, puedes crear un script:

```bash
#!/bin/bash
# /var/www/osac-knowledge-bot/scripts/sync-zendesk.sh

cd /var/www/osac-knowledge-bot/backend
source venv/bin/activate
curl -X POST http://localhost:8000/api/knowledge/sync/zendesk \
  -H "Authorization: Bearer TU_TOKEN_ADMIN_AQUI"
```

Y luego añadirlo al cron:
```bash
# Sincronizar todos los días a las 2 AM
0 2 * * * /var/www/osac-knowledge-bot/scripts/sync-zendesk.sh
```

---

## ⚙️ Configuración Recomendada

### Para Producción:

**Opción Recomendada: Sincronización Automática Diaria**

```env
ZENDESK_AUTO_SYNC=true
ZENDESK_SYNC_HOUR=3    # 3 AM UTC (ajusta a tu zona horaria)
ZENDESK_SYNC_MINUTE=0
```

**Ventajas:**
- ✅ La base de conocimiento siempre está actualizada
- ✅ Se ejecuta en horario de bajo tráfico
- ✅ No requiere intervención manual

### Para Desarrollo:

```env
ZENDESK_AUTO_SYNC=false
```

**Ventajas:**
- ✅ Control total
- ✅ Puedes sincronizar cuando lo necesites
- ✅ Evita sincronizaciones innecesarias durante desarrollo

---

## 📋 Ver Estado de Sincronización

### En la Interfaz Web:

1. Ve a "Gestionar Conocimiento"
2. Verás un indicador mostrando:
   - ✅ "Sincronización automática activa" (si está habilitada)
   - ⚠️ "Sincronización automática desactivada" (si está desactivada)
   - También muestra la próxima sincronización programada

### Por API:

```bash
GET /api/knowledge/sync/zendesk/status
```

Respuesta:
```json
{
  "enabled": true,
  "next_run": "2025-01-22T02:00:00Z",
  "trigger": "cron[hour='2', minute='0']",
  "zendesk_configured": true,
  "auto_sync_enabled": true,
  "sync_hour": 2,
  "sync_minute": 0
}
```

---

## 🔧 Cambiar la Configuración

1. **Edita el archivo `.env`** en `backend/`
2. **Cambia las variables**:
   - `ZENDESK_AUTO_SYNC=true/false` - Activar/desactivar
   - `ZENDESK_SYNC_HOUR=2` - Hora (0-23, UTC)
   - `ZENDESK_SYNC_MINUTE=0` - Minuto (0-59)
3. **Reinicia el backend** para aplicar los cambios

```bash
sudo systemctl restart osac-backend
```

---

## 📝 Resumen

| Característica | Manual | Automática |
|---------------|--------|------------|
| **Activación** | Clic en botón | Programada diariamente |
| **Control** | Total | Automático |
| **Recursos** | Solo cuando se usa | Cada día a la hora programada |
| **Actualización** | Solo cuando sincronizas | Automática cada día |
| **Recomendado para** | Desarrollo, pruebas | Producción |

---

## 🎯 Recomendación

- **Desarrollo/Pruebas**: Mantén `ZENDESK_AUTO_SYNC=false` (manual)
- **Producción**: Configura `ZENDESK_AUTO_SYNC=true` con una hora de bajo tráfico

---

¿Necesitas ayuda para configurarlo? Avísame y te guío paso a paso. 🚀


