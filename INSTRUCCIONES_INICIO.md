# Instrucciones para Iniciar el Sistema

## Método 1: Usando los archivos .bat (RECOMENDADO en Windows)

### Paso 1: Iniciar el Backend

1. **Doble clic en `START_BACKEND.bat`**
   - O haz clic derecho → "Ejecutar como administrador"
   - Espera a que aparezca: `INFO:     Uvicorn running on http://0.0.0.0:8000`
   - **NO CIERRES ESTA VENTANA** - debe quedarse corriendo

### Paso 2: Iniciar el Frontend (en una nueva ventana)

1. **Abre una nueva ventana de PowerShell o cmd**
2. **Doble clic en `START_FRONTEND.bat`**
   - O ejecuta manualmente: `cd frontend && npm start`
   - Espera a que se abra el navegador automáticamente
   - **NO CIERRES ESTA VENTANA** - debe quedarse corriendo

## Método 2: Manualmente en PowerShell

### Terminal 1 - Backend:

```powershell
cd C:\Users\krystian\Desktop\osac_knowledge\backend
.\venv\Scripts\Activate.ps1
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Espera a ver:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Terminal 2 - Frontend:

```powershell
cd C:\Users\krystian\Desktop\osac_knowledge\frontend
npm start
```

Espera a que se abra el navegador automáticamente.

## Verificar que Funciona

1. **Backend**: Abre en el navegador: http://localhost:8000/api/health
   - Deberías ver: `{"status":"ok","service":"OSAC Knowledge Bot API"}`

2. **Frontend**: Abre en el navegador: http://localhost:3000
   - Deberías ver la página de inicio (login/register)

## Problemas Comunes

### Error: "No se puede acceder a este sitio web"

**Causa**: El backend no está corriendo

**Solución**:
1. Verifica que el backend esté corriendo en una ventana
2. Verifica que veas `INFO:     Uvicorn running on http://0.0.0.0:8000`
3. Espera 10-15 segundos después de iniciar el backend
4. Abre http://localhost:8000/api/health para verificar

### Error: "Puerto 8000 ya en uso"

**Solución**:
```powershell
# Buscar el proceso usando el puerto 8000
netstat -ano | findstr :8000

# Matar el proceso (reemplaza PID con el número que veas)
taskkill /PID <PID> /F
```

### Error: "Puerto 3000 ya en uso"

**Solución**: El frontend preguntará si quieres usar otro puerto. Presiona "Y" para aceptar.

### El navegador no se abre automáticamente

**Solución**: Abre manualmente http://localhost:3000

## Primera Vez: Registrar Usuario

1. Ve a http://localhost:3000
2. Haz clic en "Registrarse"
3. Completa el formulario
4. **El primer usuario será automáticamente administrador**

¡Listo! Ya puedes usar el sistema.


