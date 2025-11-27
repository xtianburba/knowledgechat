# Solución: Permission denied

El error "Permission denied" significa que el script no tiene permisos de ejecución.

## Solución Rápida

```bash
cd /opt/osac-knowledge-bot
chmod +x QUICK_DEPLOY.sh
chmod +x deploy.sh
chmod +x setup-apache.sh
chmod +x SOLUCION_DEPLOY_COMPLETA.sh
./QUICK_DEPLOY.sh
```

O ejecuta directamente con bash:

```bash
cd /opt/osac-knowledge-bot
bash QUICK_DEPLOY.sh
```

## Verificar Permisos

Para ver los permisos actuales:
```bash
ls -l *.sh
```

Deberían mostrar `-rwxr-xr-x` (x = ejecutable)



