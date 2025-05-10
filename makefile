REPO_URL=https://github.com/ClemEsaipProject/metric.git
REPO_DIR=metric
IMAGE_NAME=outils-mesure-streaming
CONTAINER_NAME=outils-mesure

.PHONY: all clone build run clean

all: clone build run

clone:
	git clone $(REPO_URL) || true
	cd $(REPO_DIR) && git pull

build:
	cd $(REPO_DIR) && DOCKER_BUILDKIT=1 docker build -t $(IMAGE_NAME) .

run:
	docker run -d -p 3000:3000 -p 9090:9090 -p 9100:9100 --name $(CONTAINER_NAME) $(IMAGE_NAME)

clean:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	docker rmi $(IMAGE_NAME) || true
	rm -rf $(REPO_DIR)
