# FastAPI OCR Application

FastAPI service that extracts every word detected in an uploaded image and returns them as a JSON array.

## Features

- ✅ POST `/ocr` endpoint for image uploads and OCR extraction
- ✅ File-type validation to ensure only images are processed
- ✅ Production-ready Docker setup
- ✅ Azure-friendly deployment scripts
- ✅ Docker Compose workflow for local development
- ✅ Built-in health checks
- ✅ Interactive API docs at `/docs` (Swagger UI) and `/redoc`

## Requirements

- Docker / Docker Desktop
- Docker Compose (bundled with Docker Desktop)
- Azure CLI (for Azure deployments)
- Python 3.9+ (only if you want to run it locally without Docker)

## Local Installation (Development)

### 1. Clone or download the project

```bash
cd fast-api-tutorial
```

### 2. Run with Docker Compose (recommended)

```bash
# Start the stack
./deploy-local.sh up

# Alternatively
docker-compose up -d
```

The API will be available at http://localhost:8000

### 3. Run without Docker (direct Python)

```bash
# Create a virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn main:app --reload
```

## API Usage

### OCR endpoint — extract words from an image

**POST** `/ocr`

```bash
curl -X POST "http://localhost:8000/ocr" \
  -F "file=@/path/to/your/image.png"
```

**Successful response (200):**

```json
{
  "words": ["word", "number", "of", "words", "detected"]
}
```

**Error responses:**

- `400`: The uploaded file is not a valid image
- `500`: Unexpected OCR processing error

### Other endpoints

- **GET** `/` — Health check
- **GET** `/docs` — Swagger UI (interactive docs)
- **GET** `/redoc` — ReDoc (alternative docs view)

## Local Deployment with Docker

### Available commands

```bash
# Start containers
./deploy-local.sh up
# or: docker-compose up -d

# Stop containers
./deploy-local.sh down

# Stream logs
./deploy-local.sh logs

# Rebuild the image (after code changes)
./deploy-local.sh build

# Restart containers
./deploy-local.sh restart

# Remove containers and volumes
./deploy-local.sh clean

# Tip: you can always call docker-compose directly
# docker-compose up -d
# docker-compose down
# docker-compose logs -f
```

## Azure Deployment

### Prerequisites

1. **Azure CLI installed and logged in**

   ```bash
   # Install if you don’t have it yet
   # macOS: brew install azure-cli
   # Windows: https://learn.microsoft.com/cli/azure/install-azure-cli-windows
   # Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **An active Azure subscription**

### Deployment steps

#### Option 1: Automated script (recommended)

```bash
# Make the script executable (first run only)
chmod +x deploy-azure.sh

# Run the deployment
./deploy-azure.sh <resource-group> <registry-name> [app-name] [location]

# Example
./deploy-azure.sh my-rg my-registry fastapi-ocr-app eastus
```

The script will:

- ✅ Log into Azure
- ✅ Create (or reuse) the Resource Group
- ✅ Create Azure Container Registry
- ✅ Build & push the Docker image
- ✅ Create an App Service plan
- ✅ Deploy the Web App with your container

#### Option 2: Manual Azure CLI steps

```bash
# 1. Log in
az login

# 2. Create the resource group
az group create --name my-rg --location eastus

# 3. Create the Container Registry
az acr create --resource-group my-rg \
  --name myregistry --sku Basic

# 4. Build & push the image
az acr build --registry myregistry \
  --image fastapi-ocr:latest .

# 5. Create the App Service plan
az appservice plan create --name myplan \
  --resource-group my-rg \
  --is-linux --sku B1

# 6. Create the Web App
az webapp create --resource-group my-rg \
  --plan myplan \
  --name fastapi-ocr-app \
  --deployment-container-image-name myregistry.azurecr.io/fastapi-ocr:latest

# 7. Configure the ACR credentials
az webapp config container set \
  --name fastapi-ocr-app \
  --resource-group my-rg \
  --docker-custom-image-name myregistry.azurecr.io/fastapi-ocr:latest \
  --docker-registry-server-url https://myregistry.azurecr.io \
  --docker-registry-server-user <username> \
  --docker-registry-server-password <password>
```

### Verify the deployment

```bash
# Get the app URL
az webapp show --resource-group my-rg --name fastapi-ocr-app \
  --query defaultHostName --output tsv

# Tail logs
az webapp log tail --resource-group my-rg --name fastapi-ocr-app

# Hit the API
curl https://fastapi-ocr-app.azurewebsites.net/
curl https://fastapi-ocr-app.azurewebsites.net/docs
```

## Configuration

### Environment variables

Copy `.env.example` to `.env` and customize as needed:

```bash
cp .env.example .env
```

### Scaling in Azure

To resize the instance:

```bash
# Scale up to a higher tier (S1 = Standard)
az appservice plan update --name myplan \
  --resource-group my-rg \
  --sku S1
```

## Project structure

```
fast-api-tutorial/
├── main.py                 # FastAPI application
├── Dockerfile              # Docker build instructions
├── docker-compose.yml      # Local orchestration
├── requirements.txt        # Python dependencies
├── deploy-local.sh         # Local Docker helper
├── deploy-azure.sh         # Azure deployment helper
├── .env.example            # Environment template
└── .dockerignore           # Files excluded from the image
```

## Troubleshooting

### Error: "tesseract not found"

**Inside Docker:** already installed. If you run locally without Docker:

```bash
# macOS
brew install tesseract

# Ubuntu/Debian
sudo apt-get install tesseract-ocr

# Windows
# Download from https://github.com/UB-Mannheim/tesseract/wiki
```

### Error: "No space left on device"

Clean up dangling Docker assets:

```bash

```

### App not responding on Azure

```bash
# Check detailed logs
az webapp log tail --resource-group my-rg --name fastapi-ocr-app

# Restart the app
az webapp restart --resource-group my-rg --name fastapi-ocr-app
```

## Roadmap

- [ ] Add authentication (JWT)
- [ ] GitHub Actions CI/CD improvements

## License

MIT
