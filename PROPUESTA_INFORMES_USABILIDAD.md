# Propuesta: Informe de Usabilidad

## 📊 Métricas Propuestas

### 1. **Estadísticas Generales**
- **Total de preguntas realizadas** (histórico)
- **Total de usuarios activos** (últimos 30 días)
- **Preguntas por día/semana/mes** (gráfico de tendencias)
- **Promedio de preguntas por usuario**
- **Hora pico de uso** (horas del día con más actividad)

### 2. **Preguntas más Frecuentes**
- **Top 10 preguntas más realizadas** (con contador)
- **Preguntas sin respuesta** (si no se encontró información relevante)
- **Tendencias de búsqueda** (qué temas se consultan más)
- **Palabras clave más usadas**

### 3. **Uso por Usuario**
- **Ranking de usuarios más activos**
- **Preguntas por usuario** (individual)
- **Última actividad por usuario**
- **Usuarios nuevos** (primer uso en período seleccionado)

### 4. **Análisis de Documentos**
- **Documentos más consultados** (por cantidad de veces que aparecen en respuestas)
- **Documentos menos utilizados** (para identificar contenido innecesario)
- **Fuentes más consultadas** (Zendesk vs Manual vs URL)
- **Tiempo promedio de respuesta del bot**

### 5. **Calidad de Respuestas** (si implementamos feedback)
- **Preguntas con feedback positivo/negativo**
- **Tasa de satisfacción** (si añadimos sistema de "útil/no útil")
- **Preguntas que requirieron múltiples intentos** (usuario reformuló la pregunta)

### 6. **Actividad del Sistema**
- **Sincronizaciones de Zendesk** (cuándo se ejecutaron, cuántos documentos se añadieron)
- **Contenido añadido manualmente** (por fecha)
- **URLs añadidas** (por fecha)
- **Estado de la base de conocimiento** (total de documentos, por fuente)

### 7. **Filtros y Períodos**
- **Filtro por fecha**: Hoy, Última semana, Último mes, Último año, Personalizado
- **Filtro por usuario**: Ver estadísticas individuales
- **Exportar datos**: Descargar reporte en CSV/Excel

## 🎨 Visualización Propuesta

### Dashboard Principal
```
┌─────────────────────────────────────────────────────────────┐
│  Informes de Usabilidad                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Filtros: Fecha ▼] [Usuario ▼] [Exportar]                │
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │ Preguntas   │ │ Usuarios    │ │ Documentos  │          │
│  │   1,234     │ │     45      │ │     123     │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Gráfico: Preguntas por día                          │  │
│  │ [Gráfico de líneas temporal]                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────┐ ┌──────────────────────┐        │
│  │ Top 10 Preguntas     │ │ Documentos Más       │        │
│  │ 1. ¿Cómo...? (45)    │ │ Consultados         │        │
│  │ 2. ¿Cuándo...? (32)  │ │ 1. Documento X (23) │        │
│  │ 3. ...               │ │ 2. Documento Y (18) │        │
│  └──────────────────────┘ └──────────────────────┘        │
│                                                             │
│  ┌──────────────────────┐ ┌──────────────────────┐        │
│  │ Usuarios Más Activos │ │ Horas Pico           │        │
│  │ 1. Usuario1 (120)    │ │ [Gráfico de barras]  │        │
│  │ 2. Usuario2 (98)     │ │ 10:00 - 12:00        │        │
│  └──────────────────────┘ └──────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 🗄️ Nuevas Tablas de Base de Datos

### Tabla: `chat_interactions`
```sql
- id (PK)
- user_id (FK)
- question (texto de la pregunta)
- response_preview (primeros 200 caracteres)
- documents_used (IDs de documentos utilizados, JSON)
- response_time_ms (tiempo de respuesta en milisegundos)
- created_at (timestamp)
- feedback (nullable: 'positive', 'negative', null)
```

### Tabla: `document_usage_stats`
```sql
- id (PK)
- knowledge_entry_id (FK)
- times_used (contador)
- last_used_at (timestamp)
- created_at (timestamp)
```

## 📈 Métricas Adicionales Útiles

1. **Tasa de éxito**: % de preguntas que obtuvieron respuestas útiles
2. **Documentos sin usar**: Documentos que nunca han aparecido en respuestas
3. **Usuarios inactivos**: Usuarios que no han usado el sistema en X días
4. **Tendencias de palabras**: Nube de palabras más buscadas
5. **Comparación temporal**: Comparar período actual vs anterior (ej: este mes vs mes pasado)

## 🚀 Funcionalidades Adicionales

1. **Alertas**: Notificaciones cuando:
   - Un documento no se usa hace X tiempo
   - Aumenta significativamente el número de preguntas sin respuesta
   - Un usuario tiene muchas preguntas sin respuesta

2. **Exportación**: 
   - PDF con gráficos
   - CSV para análisis externo
   - Email automático semanal/mensual

3. **Comparativas**:
   - Comparar uso por departamento/rol
   - Comparar eficiencia antes/después de añadir contenido

## ✅ Implementación Sugerida (Fase 1 - Básico)

1. **Tabla de interacciones de chat** (registrar cada pregunta)
2. **Dashboard básico** con:
   - Total de preguntas
   - Top 5 preguntas más frecuentes
   - Gráfico de preguntas por día (últimos 7 días)
   - Usuarios más activos
   - Documentos más consultados

3. **Endpoint API** `/api/analytics/*` para obtener datos
4. **Componente React** `Analytics.js` con visualizaciones básicas

## 📝 ¿Qué implementamos primero?

¿Te parece bien empezar con estas métricas básicas?
1. Total de preguntas
2. Preguntas por día (gráfico)
3. Top 10 preguntas más frecuentes
4. Documentos más consultados
5. Usuarios más activos

¿Alguna métrica adicional que te gustaría incluir?

