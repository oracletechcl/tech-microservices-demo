#!/bin/bash

# Script para probar la autenticación con OCIR

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables (edita estas según tu configuración)
REGION_KEY="sjc"
OCIR_NS="idi1o0a010nx"
OCI_USERNAME="oracleidentitycloudservice/denny.alquinta@oracle.com"

echo -e "${YELLOW}🔐 Probador de Autenticación OCIR${NC}"
echo "=================================="

# Solicitar auth token
read -s -p "Ingresa tu OCI Auth Token: " OCI_AUTH_TOKEN
echo ""

if [[ -z "$OCI_AUTH_TOKEN" ]]; then
    echo -e "${RED}❌ No se proporcionó auth token${NC}"
    exit 1
fi

# Probar login
echo "🔄 Probando autenticación con OCIR..."
docker logout "$REGION_KEY.ocir.io" 2>/dev/null || true

if echo "$OCI_AUTH_TOKEN" | docker login "$REGION_KEY.ocir.io" -u "$OCIR_NS/$OCI_USERNAME" --password-stdin; then
    echo -e "${GREEN}✅ ¡Autenticación exitosa!${NC}"
    echo "🎉 Tu auth token es válido y funciona correctamente."
    echo ""
    echo -e "${YELLOW}📝 Para usar este token en el script:${NC}"
    echo "1. Edita build-and-push.sh"
    echo "2. Actualiza la línea: OCI_AUTH_TOKEN=\"TU_TOKEN_AQUI\""
    echo "3. Ejecuta: ./build-and-push.sh"
else
    echo -e "${RED}❌ Error de autenticación${NC}"
    echo "💡 Posibles causas:"
    echo "   - Auth token incorrecto o expirado"
    echo "   - Usuario/namespace incorrecto"
    echo "   - Problemas de red"
    echo ""
    echo "🔧 Para generar un nuevo token, ejecuta: ./generate-auth-token.sh"
fi
