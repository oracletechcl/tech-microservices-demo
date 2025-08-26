#!/bin/bash

# ======= VARIABLES DE CONFIGURACIÓN =======
APP_NAME="agendar-ms-fn"
FN_CONTEXT="us-sanjose-1"
OCI_COMPARTMENT_OCID="ocid1.compartment.oc1..aaaaaaaal7vn7wsy3qgizklrlfgo2vllfta3wkqlnfkvykoroite3lzxbnna"
SUBNET_OCID="ocid1.subnet.oc1.us-sanjose-1.aaaaaaaa23am2rdz7db7ty5btfdndlah2tusxbv52jb3sdaehrghwdbhv7ba"
REGION_KEY="sjc"
OCIR_NS="idi1o0a010nx"
OCI_USERNAME="oracleidentitycloudservice/denny.alquinta@oracle.com"
# IMPORTANTE: Ejecuta ./generate-auth-token.sh para obtener instrucciones de cómo generar un token válido
OCI_AUTH_TOKEN=">m)#_E3b6KVg0B{IdHiF"
EXPECTED_API_URL="https://functions.us-sanjose-1.oci.oraclecloud.com"
# ===========================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🔧 Validando autenticación y contexto..."

# Validar prerequisitos
echo "🔍 Validando herramientas necesarias..."
for tool in oci fn docker; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ ERROR: $tool no está instalado o no está en PATH${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Todas las herramientas necesarias están disponibles${NC}"

# Autenticación OCI CLI
if ! oci os ns get &>/dev/null; then
    echo -e "${RED}ERROR: No estás autenticado en OCI CLI.${NC}"
    echo "Ejecuta: oci setup config"
    exit 1
else
    echo -e "${GREEN}✅ OCI CLI autenticado.${NC}"
fi

# Setear y limpiar contexto
fn use context default
fn list context | awk 'NR>1 && $2 != "default" {print $1}' | while read ctx; do
    fn delete context "$ctx"
done
echo -e "${GREEN}✅ Contextos anteriores eliminados${NC}"

# Crear contexto si no existe
if ! fn list context | grep -wq "$FN_CONTEXT"; then
    fn create context "$FN_CONTEXT" --provider oracle    
fi
echo -e "${GREEN}✅ Contexto ${FN_CONTEXT} creado o ya existente${NC}"

fn use context "$FN_CONTEXT"
fn update context oracle.region us-sanjose-1
fn update context api-url "$EXPECTED_API_URL"
fn update context oracle.compartment-id "$OCI_COMPARTMENT_OCID"
fn update context registry "$REGION_KEY.ocir.io/$OCIR_NS"

echo -e "${GREEN}✅ Contexto configurado correctamente${NC}"

# Login a OCIR usando OCI CLI
docker logout "$REGION_KEY.ocir.io" 2>/dev/null || true
echo "🔐 Intentando login a OCIR usando OCI CLI..."

# Verificar si el auth token está configurado
if [[ "$OCI_AUTH_TOKEN" == "PLACEHOLDER_TOKEN_NEEDS_UPDATE" ]]; then
    echo -e "${RED}❌ El auth token no está configurado${NC}"
    echo ""
    echo -e "${YELLOW}📋 Pasos para configurar el auth token:${NC}"
    echo "1. Ve a la Consola OCI: https://cloud.oracle.com"
    echo "2. Navega a: Identity & Security > Users > denny.alquinta@oracle.com"
    echo "3. Ve a la pestaña 'Auth Tokens'"
    echo "4. Haz clic en 'Generate Token'"
    echo "5. Descripción: 'DevOps-Deploy-$(date +%Y%m%d)'"
    echo "6. Copia el token generado"
    echo "7. Edita este script y reemplaza 'PLACEHOLDER_TOKEN_NEEDS_UPDATE'"
    echo ""
    echo -e "${YELLOW}💡 O usa el script de ayuda:${NC} ./generate-auth-token.sh"
    exit 1
fi

# Intentar login con el token proporcionado
if echo "$OCI_AUTH_TOKEN" | docker login "$REGION_KEY.ocir.io" -u "$OCIR_NS/$OCI_USERNAME" --password-stdin 2>/dev/null; then
    echo -e "${GREEN}✅ Loggeado en OCIR exitosamente${NC}"
else
    echo -e "${RED}❌ Error al hacer login en OCIR${NC}"
    echo "El auth token parece ser inválido o ha expirado."
    echo ""
    echo -e "${YELLOW}🔧 Para resolver este problema:${NC}"
    echo "1. Ejecuta: ./generate-auth-token.sh"
    echo "2. Genera un nuevo token en la consola OCI"
    echo "3. Actualiza OCI_AUTH_TOKEN en este script"
    echo "4. Ejecuta: ./test-ocir-auth.sh (para probar)"
    exit 1
fi

# Crear aplicación si no existe
if ! fn list apps | grep -wq "$APP_NAME"; then
    echo "📦 Creando aplicación '$APP_NAME'..."
    echo "[\"$SUBNET_OCID\"]" > subnet-ids.json
    application_id=$(oci fn application create \
        --compartment-id "$OCI_COMPARTMENT_OCID" \
        --display-name "$APP_NAME" \
        --subnet-ids file://subnet-ids.json \
        --query data.id --raw-output)
    echo "✅ Application creada con OCID: $application_id"
    rm subnet-ids.json
else
    echo "📦 Aplicación '$APP_NAME' ya existe."
fi

# Desplegar cada función con su propio shared/
for dir in */; do
    if [[ "$dir" == "shared/" ]]; then
        continue
    fi
    if [[ -f "$dir/func.yaml" ]]; then
        FUNC_DIR=${dir%/}
        echo -e "\n🚀 Desplegando función: ${GREEN}$FUNC_DIR${NC}"

        cd "$FUNC_DIR"

        # Validar requirements.txt
        if ! grep -q "fdk" requirements.txt; then
            echo "fdk" >> requirements.txt
        fi
        if ! grep -q "requests" requirements.txt; then
            echo "requests" >> requirements.txt
        fi

        # Validar shared/__init__.py
        if [[ ! -d "shared" ]]; then
            mkdir -p shared
        fi
        if [[ ! -f "shared/__init__.py" ]]; then
            touch shared/__init__.py
        fi

        # Despliegue
        echo "🔨 Desplegando función '$FUNC_DIR' en aplicación '$APP_NAME'..."
        if fn -v deploy --app "$APP_NAME" --no-bump; then
            echo -e "${GREEN}✅ Función '$FUNC_DIR' desplegada exitosamente${NC}"
        else
            echo -e "${RED}❌ Error al desplegar función '$FUNC_DIR'${NC}"
            echo "❌ Abortando despliegue debido a error"
            exit 1
        fi

        cd ..
    else
        echo -e "${RED}⚠️  El directorio '$dir' no contiene func.yaml. Se omite.${NC}"
    fi
done

echo -e "\n${GREEN}🏁 Todas las funciones fueron construidas y desplegadas exitosamente.${NC}"