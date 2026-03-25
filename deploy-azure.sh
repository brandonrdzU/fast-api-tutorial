#!/bin/bash

# Deploy script for Azure
# Usage: ./deploy-azure.sh <resource-group> <registry-name> <app-name> <location>

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 <resource-group> <registry-name> [app-name] [location]${NC}"
    echo "Example: $0 my-rg my-registry my-fastapi-ocr eastus"
    exit 1
fi

RESOURCE_GROUP=$1
REGISTRY_NAME=$2
APP_NAME=${3:-fastapi-ocr-app}
LOCATION=${4:-eastus}
IMAGE_NAME="fastapi-ocr"
IMAGE_TAG="latest"
REGISTRY_URL="${REGISTRY_NAME}.azurecr.io"
IMAGE_URL="${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${YELLOW}FastAPI OCR - Azure Deployment${NC}"
echo "Resource Group: $RESOURCE_GROUP"
echo "Registry: $REGISTRY_NAME"
echo "App Name: $APP_NAME"
echo "Location: $LOCATION"
echo ""

# Step 1: Login to Azure
echo -e "${YELLOW}[1/6] Logging in to Azure...${NC}"
az login

# Step 2: Create Resource Group
echo -e "${YELLOW}[2/6] Creating/Checking Resource Group...${NC}"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" || true

# Step 3: Create Container Registry
echo -e "${YELLOW}[3/6] Creating/Checking Container Registry...${NC}"
az acr create --resource-group "$RESOURCE_GROUP" \
    --name "$REGISTRY_NAME" --sku Basic || true

# Step 4: Build and push image to ACR
echo -e "${YELLOW}[4/6] Building and pushing Docker image to ACR...${NC}"
az acr build --registry "$REGISTRY_NAME" \
    --image "${IMAGE_NAME}:${IMAGE_TAG}" \
    --image "${IMAGE_NAME}:$(date +%Y%m%d-%H%M%S)" .

# Step 5: Create App Service Plan
echo -e "${YELLOW}[5/6] Creating/Checking App Service Plan...${NC}"
PLAN_NAME="${APP_NAME}-plan"
az appservice plan create --name "$PLAN_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --is-linux --sku B1 || true

# Step 6: Deploy Web App
echo -e "${YELLOW}[6/6] Deploying Web App...${NC}"
az webapp create --resource-group "$RESOURCE_GROUP" \
    --plan "$PLAN_NAME" \
    --name "$APP_NAME" \
    --deployment-container-image-name "$IMAGE_URL" || true

# Configure web app to use ACR
echo -e "${YELLOW}Configuring Web App...${NC}"
az webapp config container set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --docker-custom-image-name "$IMAGE_URL" \
    --docker-registry-server-url "https://${REGISTRY_URL}" \
    --docker-registry-server-user $(az acr credential show -n "$REGISTRY_NAME" --query username -o tsv) \
    --docker-registry-server-password $(az acr credential show -n "$REGISTRY_NAME" --query 'passwords[0].value' -o tsv)

# Get the app URL
APP_URL=$(az webapp show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query defaultHostName -o tsv)

echo ""
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo -e "${GREEN}App URL: https://${APP_URL}${NC}"
echo -e "${GREEN}API Docs: https://${APP_URL}/docs${NC}"
echo ""
echo "Next steps:"
echo "1. Test the API: curl https://${APP_URL}/"
echo "2. View logs: az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME"
echo "3. Update settings: az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $APP_NAME --settings ..."
