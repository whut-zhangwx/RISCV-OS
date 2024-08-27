# docker commit -p=true -a "whutzhangwx" riscvenv whutzhangwx/riscv-os:env

set -e
USER_NAME="whutzhangwx"
REPONSITORY="riscv-os"
TAG="0.1"
echo "${USER_NAME}/${REPONSITORY}:${TAG}"

# docker build -t "${USER_NAME}/${REPONSITORY}:${TAG}" .

docker login --username whutzhangwx
docker push "${USER_NAME}/${REPONSITORY}:${TAG}"

# docker run -dit --name riscvtest "${USER_NAME}/${REPONSITORY}:${TAG}" /bin/bash
