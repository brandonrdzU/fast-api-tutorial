# FastAPI OCR Application

API de FastAPI con capacidad OCR para extraer palabras de imágenes y devolverlas como un arreglo JSON.

## Features

- ✅ Endpoint POST `/ocr` para subir imágenes y extraer texto
- ✅ Validación de archivos de imagen
- ✅ Dockerizado y listo para producción
- ✅ Fácil deployment en Azure
- ✅ Docker Compose para desarrollo local
- ✅ Health checks integrados
- ✅ API docs automática en `/docs`

## Requisitos

- Docker/Docker Desktop
- Docker Compose (incluido con Docker Desktop)
- Azure CLI (para deploy en Azure)
- Python 3.9+ (solo para desarrollo local)

## Instalación Local (Desarrollo)

### 1. Clonar/Descargar el proyecto

```bash
cd fast-api-tutorial
```

### 2. Con Docker Compose (Recomendado)

```bash
# Iniciar la app en Docker
./deploy-local.sh up

# O manualmente
docker-compose up -d
```

La app estará disponible en: http://localhost:8000

### 3. Sin Docker (Python directo)

```bash
# Crear virtual environment
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar
uvicorn main:app --reload
```

## Uso de la API

### Endpoint OCR - Extraer palabras de imagen

**POST** `/ocr`

```bash
curl -X POST "http://localhost:8000/ocr" \
  -F "file=@/ruta/a/tu/imagen.png"
```

**Respuesta exitosa (200):**

```json
{
  "words": ["palabra", "número", "de", "palabras", "detectadas"]
}
```

**Errores:**

- `400`: El archivo no es una imagen válida
- `500`: Error al procesar OCR

### Otros Endpoints

- **GET** `/` - Health check
- **GET** `/docs` - Swagger UI (documentación interactiva)
- **GET** `/redoc` - ReDoc (alternativa de documentación)

## Deployment Local con Docker

### Comandos disponibles

```bash
# Iniciar contenedores
./deploy-local.sh up
# o: docker-compose up -d

# Detener contenedores
./deploy-local.sh down

# Ver logs en tiempo real
./deploy-local.sh logs

# Construir imagen (si hay cambios)
./deploy-local.sh build

# Reiniciar contenedores
./deploy-local.sh restart

# Limpiar todo (remover contenedores y volúmenes)
./deploy-local.sh clean

# Nota: También puedes usar docker-compose directamente
# docker-compose up -d
# docker-compose down
# docker-compose logs -f
```

## Deployment en Azure

### Requisitos previos

1. **Azure CLI instalado y configurado**

   ```bash
   # Instalar si no lo tienes
   # macOS: brew install azure-cli
   # Windows: https://learn.microsoft.com/cli/azure/install-azure-cli-windows
   # Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Suscripción activa en Azure**

### Pasos de Deployment

#### Opción 1: Script automático (Recomendado)

```bash
# Hacer ejecutable (primera vez)
chmod +x deploy-azure.sh

# Ejecutar deployment
./deploy-azure.sh <resource-group> <registry-name> [app-name] [location]

# Ejemplo
./deploy-azure.sh my-rg my-registry fastapi-ocr-app eastus
```

El script hará automáticamente:

- ✅ Login en Azure
- ✅ Crear Resource Group
- ✅ Crear Container Registry
- ✅ Buildear y pushear imagen
- ✅ Crear App Service
- ✅ Deployar la aplicación

#### Opción 2: Pasos manuales

```bash
# 1. Login
az login

# 2. Crear resource group
az group create --name my-rg --location eastus

# 3. Crear Container Registry
az acr create --resource-group my-rg \
  --name myregistry --sku Basic

# 4. Buildear y pushear imagen
az acr build --registry myregistry \
  --image fastapi-ocr:latest .

# 5. Crear App Service Plan
az appservice plan create --name myplan \
  --resource-group my-rg \
  --is-linux --sku B1

# 6. Crear Web App
az webapp create --resource-group my-rg \
  --plan myplan \
  --name fastapi-ocr-app \
  --deployment-container-image-name myregistry.azurecr.io/fastapi-ocr:latest

# 7. Configurar autenticación de ACR
az webapp config container set \
  --name fastapi-ocr-app \
  --resource-group my-rg \
  --docker-custom-image-name myregistry.azurecr.io/fastapi-ocr:latest \
  --docker-registry-server-url https://myregistry.azurecr.io \
  --docker-registry-server-user <username> \
  --docker-registry-server-password <password>
```

### Verificar Deployment

```bash
# Obtener URL de la app
az webapp show --resource-group my-rg --name fastapi-ocr-app \
  --query defaultHostName --output tsv

# Ver logs
az webapp log tail --resource-group my-rg --name fastapi-ocr-app

# Probar API
curl https://fastapi-ocr-app.azurewebsites.net/
curl https://fastapi-ocr-app.azurewebsites.net/docs
```

## Configuración

### Variables de Entorno

Copiar `.env.example` a `.env` y personalizar si es necesario:

```bash
cp .env.example .env
```

### Escalado en Azure

Para cambiar el tamaño de la instancia:

```bash
# Escalar a tier superior (S1 = Standard)
az appservice plan update --name myplan \
  --resource-group my-rg \
  --sku S1
```

## Estructura del Proyecto

```
fast-api-tutorial/
├── main.py                 # Aplicación FastAPI
├── Dockerfile              # Configuración Docker
├── docker-compose.yml      # Orquestación Local
├── requirements.txt        # Dependencias Python
├── deploy-local.sh         # Script deploy local
├── deploy-azure.sh         # Script deploy Azure
├── .env.example            # Template de variables
└── .dockerignore          # Archivos a ignorar en imagen
```

## Troubleshooting

### Error: "tesseract not found"

**En Docker:** La imagen ya incluye tesseract. Si usas Python directo:

```bash
# macOS
brew install tesseract

# Ubuntu/Debian
sudo apt-get install tesseract-ocr

# Windows
# Descargar desde: https://github.com/UB-Mannheim/tesseract/wiki
```

### Error: "No space left on device"

Limpiar imágenes y contenedores Docker:

```bash
docker system prune -a
```

### La app no responde en Azure

```bash
# Ver logs detallados
az webapp log tail --resource-group my-rg --name fastapi-ocr-app

# Reiniciar app
az webapp restart --resource-group my-rg --name fastapi-ocr-app
```

## Performance y Optimizaciones

- Imagen Docker optimizada con multi-stage build (~650MB)
- Health checks cada 30 segundos
- Auto-restart en caso de fallo
- B1 plan en Azure es suficiente para uso moderado

Para mayor throughput en producción:

- Escalar a S1 o superior
- Usar autoscaling
- Implementar cache de requests
- Usar CDN para assets estáticos

## Seguridad

- No incluir secretos en el Dockerfile
- Usar `.env` para variables sensibles
- Azure Key Vault para credenciales en producción
- Habilitar HTTPS (automático en Azure)

## Próximos Pasos

- [ ] Agregar autenticación (JWT)
- [ ] Implementar logging centralizado
- [ ] Agregar soporte para múltiples idiomas OCR
- [ ] Cachear resultados OCR
- [ ] Agregar rate limiting
- [ ] CI/CD GitHub Actions

## Licencia

MIT

## Soporte

Para problemas o preguntas, abre un issue en el repositorio.
