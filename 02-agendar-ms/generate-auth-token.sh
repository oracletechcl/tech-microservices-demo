#!/bin/bash

# Script para generar un nuevo Auth Token para OCI Container Registry

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔑 Generador de Auth Token para OCI${NC}"
echo "========================================="

# Obtener información del usuario actual
USER_OCID=$(oci iam user get --user-id ocid1.user.oc1..aaaaaaaajpizqlfu7yhwkjvqyeobcd6zggh4bke5pb76toqpglisleyqv2sa --query 'data.id' --raw-output 2>/dev/null)

if [[ -z "$USER_OCID" ]] || [[ "$USER_OCID" == "null" ]]; then
    echo -e "${RED}❌ No se pudo encontrar el usuario en OCI${NC}"
    exit 1
fi

echo -e "${GREEN}👤 Usuario encontrado:${NC} $USER_OCID"

# Listar tokens existentes
echo -e "\n${YELLOW}📋 Auth Tokens existentes:${NC}"
oci iam auth-token list --user-id "$USER_OCID" --query 'data[].{Description:description,Id:id,State:"lifecycle-state"}' --output table

echo -e "\n${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "Los Auth Tokens solo se pueden ver una vez cuando se crean."
echo "Si has perdido el valor del token, necesitas crear uno nuevo."
echo ""
echo -e "${YELLOW}📝 Para crear un nuevo Auth Token:${NC}"
echo "1. Ve a la Consola OCI: https://cloud.oracle.com"
echo "2. Navega a: Identity & Security > Users"
echo "3. Busca tu usuario: denny.alquinta@oracle.com"
echo "4. Ve a la pestaña 'Auth Tokens'"
echo "5. Haz clic en 'Generate Token'"
echo "6. Ingresa una descripción (ej: 'DevOps-Deploy-$(date +%Y%m%d)')"
echo "7. Copia el token generado"
echo "8. Actualiza la variable OCI_AUTH_TOKEN en build-and-push.sh"
echo ""
echo -e "${GREEN}💡 Tip:${NC} Guarda el token en un lugar seguro inmediatamente después de generarlo."
