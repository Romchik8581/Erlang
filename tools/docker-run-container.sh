set -e
echo "==> Running sipcall container"
docker run \
    --network host \
    -it \
    --rm \
    sipcall
