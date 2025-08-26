#!/bin/bash

# ---------- CONFIGURACIÓN ----------
DOCKERHUB_USERNAME="dralquinta"
REPO_NAME="movimientos-ms"
TAG="v1"
FULL_IMAGE="${DOCKERHUB_USERNAME}/${REPO_NAME}:${TAG}"
NAMESPACE="movimientos-ms-namespace"
DEPLOYMENT_NAME="movimientos-ms"

# ---------- CONSTRUCCIÓN ----------
echo "🔧 Building Docker Image..."
if ! docker build -t ${FULL_IMAGE} .; then
    echo "❌ Error: Failure in Docker image construction. No further actions will be done. Fix and retry"
    exit 1
fi

# ---------- PUSH ----------
echo "🚀 Uploading image to Docker Hub..."
if ! docker push ${FULL_IMAGE}; then
    echo "❌ Error: Failure in docker push. Fix and retry."
    exit 1
fi

echo "✅ Imagen subida correctamente: ${FULL_IMAGE}"

# ---------- VERIFICAR SI EL DEPLOYMENT EXISTE ----------
echo "🔍 Checking if deployment exists..."
if kubectl get deployment ${DEPLOYMENT_NAME} -n ${NAMESPACE} &>/dev/null; then
    echo "✅ Deployment found. Restarting existing deployment..."
    
    # ---------- REINICIAR DEPLOYMENT ----------
    echo "♻️  Reiniciando deployment"
    if ! kubectl rollout restart deployment ${DEPLOYMENT_NAME} -n ${NAMESPACE}; then
        echo "⚠️  Warning: Deployment restart failed. Check status with kubectl or k9s."
        exit 1
    fi
    
    echo "⏳ Waiting for rollout to complete..."
    kubectl rollout status deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE}
    
else
    echo "🆕 Deployment not found. Performing initial deployment..."
    
    # ---------- CREAR NAMESPACE SI NO EXISTE ----------
    echo "📁 Creating namespace if it doesn't exist..."
    kubectl apply -f kubernetes/namespace-app.yaml
    
    # ---------- APLICAR TODOS LOS RECURSOS ----------
    echo "🚀 Applying all Kubernetes resources..."
    
    # Apply resources in order
    echo "  📝 Applying namespace..."
    kubectl apply -f kubernetes/namespace-app.yaml
    
    echo "  📜 Applying certificate..."
    kubectl apply -f kubernetes/certificate.yaml
    
    echo "  🔗 Applying service..."
    kubectl apply -f kubernetes/service.yaml
    
    echo "  🚀 Applying deployment..."
    kubectl apply -f kubernetes/deployment.yaml
    
    echo "  📊 Applying HPA..."
    kubectl apply -f kubernetes/hpa.yaml
    
    echo "  🌍 Applying ingress rules..."
    kubectl apply -f kubernetes/ingress-rule.yaml
    
    echo "⏳ Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE}
    
    if [ $? -eq 0 ]; then
        echo "✅ Initial deployment completed successfully!"
    else
        echo "⚠️  Warning: Deployment may not be fully ready. Check status with kubectl or k9s."
    fi
fi

echo "🏁 Build and deployment process completed successfully."

# ---------- MOSTRAR STATUS ----------
echo ""
echo "📊 Current deployment status:"
kubectl get pods -n ${NAMESPACE}
echo ""
echo "🌐 Service information:"
kubectl get svc -n ${NAMESPACE}