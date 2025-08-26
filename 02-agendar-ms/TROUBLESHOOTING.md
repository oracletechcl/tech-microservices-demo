# 🔧 Guía de Solución para build-and-push.sh

## Problemas Identificados y Soluciones

### 1. 🔐 Error de Autenticación OCIR
**Problema:** `denied: Anonymous users are only allowed read access on public repos`

**Causa:** El Auth Token en el script está expirado o es inválido.

**Solución:**
1. Ejecuta `./generate-auth-token.sh` para obtener instrucciones
2. Ve a la [Consola OCI](https://cloud.oracle.com)
3. Navega a: Identity & Security > Users > tu usuario
4. Ve a la pestaña "Auth Tokens"
5. Genera un nuevo token con descripción "DevOps-Deploy-$(date +%Y%m%d)"
6. Copia el token inmediatamente (solo se muestra una vez)
7. Actualiza `OCI_AUTH_TOKEN` en `build-and-push.sh`

### 2. 📁 Error de Directorio Shared
**Problema:** `touch: cannot touch 'shared/__init__.py': No such file or directory`

**Solución:** ✅ **YA CORREGIDO** - El script ahora crea automáticamente el directorio `shared/` si no existe.

### 3. 🛑 Continuación Después de Errores
**Problema:** El script continuaba desplegando funciones aunque hubiera errores.

**Solución:** ✅ **YA CORREGIDO** - El script ahora se detiene en el primer error.

## 🚀 Cómo Usar los Scripts Actualizados

### Paso 1: Generar Auth Token
```bash
./generate-auth-token.sh
```

### Paso 2: Probar Autenticación (Opcional)
```bash
./test-ocir-auth.sh
```

### Paso 3: Actualizar el Script
Edita `build-and-push.sh` y actualiza:
```bash
OCI_AUTH_TOKEN="TU_NUEVO_TOKEN_AQUI"
```

### Paso 4: Ejecutar Despliegue
```bash
./build-and-push.sh
```

## 🔍 Validaciones Añadidas

El script actualizado incluye estas mejoras:

1. **Validación de herramientas:** Verifica que `oci`, `fn`, y `docker` estén instalados
2. **Validación de autenticación:** Confirma que OCI CLI esté configurado
3. **Mejor manejo de errores:** Se detiene en el primer error de despliegue
4. **Creación automática de directorios:** Crea `shared/` si no existe
5. **Mensajes informativos:** Mejor retroalimentación sobre el estado del proceso

## 📋 Prerequisitos

- ✅ OCI CLI configurado (`oci setup config`)
- ✅ Fn CLI instalado
- ✅ Docker instalado y funcionando
- 🔄 Auth Token válido (generar si es necesario)

## 🆘 Solución de Problemas

### Si el script falla en autenticación:
```bash
# Verifica OCI CLI
oci iam user list --limit 1

# Prueba autenticación OCIR
./test-ocir-auth.sh

# Regenera auth token si es necesario
./generate-auth-token.sh
```

### Si las funciones no se despliegan:
1. Verifica que cada directorio de función tenga `func.yaml`
2. Revisa que `requirements.txt` esté presente
3. Confirma que la aplicación OCI Functions exista

## 📞 Contacto

Si continúas teniendo problemas, verifica:
- Permisos de IAM en OCI
- Configuración de red (VCN/Subnet)
- Estado de los servicios OCI Functions
