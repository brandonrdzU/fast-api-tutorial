#!/bin/bash

# Local Docker deployment script
# Usage: ./deploy-local.sh [up|down|build|logs]

set -e

ACTION=${1:-up}

case $ACTION in
    up)
        echo "Starting containers..."
        docker-compose up -d
        echo "✓ Containers started"
        echo "API available at: http://localhost:8000"
        echo "API Docs at: http://localhost:8000/docs"
        ;;
    down)
        echo "Stopping containers..."
        docker-compose down
        echo "✓ Containers stopped"
        ;;
    build)
        echo "Building image..."
        docker-compose build
        echo "✓ Image built"
        ;;
    logs)
        echo "Showing logs..."
        docker-compose logs -f
        ;;
    restart)
        echo "Restarting containers..."
        docker-compose restart
        echo "✓ Containers restarted"
        ;;
    clean)
        echo "Cleaning up..."
        docker-compose down -v
        docker system prune -f
        echo "✓ Cleanup complete"
        ;;
    *)
        echo "Usage: $0 {up|down|build|logs|restart|clean}"
        echo ""
        echo "Commands:"
        echo "  up       - Start the containers"
        echo "  down     - Stop the containers"
        echo "  build    - Build the Docker image"
        echo "  logs     - Show container logs"
        echo "  restart  - Restart containers"
        echo "  clean    - Remove containers and volumes"
        exit 1
        ;;
esac
