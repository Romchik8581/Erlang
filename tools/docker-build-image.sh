set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
echo "==> Building Docker image: sipcall"
docker build -t sipcall "$PROJECT_DIR"
echo "==> Done"
docker images sipcall
