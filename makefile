# Variables
REPO_URL=https://github.com/ClemEsaiProject/metric.git
REPO_DIR=metric
IMAGE_NAME=outils-mesure-streaming
CONTAINER_NAME=outils-mesure

# Cloner le dépôt si absent
clone:
	if [ ! -d "$(REPO_DIR)" ]; then \
		git clone $(REPO_URL); \
	else \
		echo "Le dépôt '$(REPO_DIR)' existe déjà."; \
	fi

# Mettre à jour le dépôt s'il existe
pull:
	if [ -d "$(REPO_DIR)" ]; then \
		cd $(REPO_DIR) && git pull; \
	else \
		echo "Le dépôt n'existe pas, lancez 'make clone' d'abord."; \
	fi

# Construire l'image Docker
build: pull
	DOCKER_BUILDKIT=1 docker build -t $(IMAGE_NAME) $(REPO_DIR)

# Lancer le conteneur
run:
	docker run -d --name $(CONTAINER_NAME) \
		-p 3000:3000 -p 9090:9090 -p 9100:9100 \
		$(IMAGE_NAME)

# Arrêter et supprimer le conteneur
stop:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

# Supprimer image et conteneur
clean: stop
	docker rmi $(IMAGE_NAME) || true

# Tout refaire proprement
rebuild: clean clone build
