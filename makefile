# Variables
REPO_URL=https://github.com/ClemEsaiProject/metric.git
REPO_DIR=metric
IMAGE_NAME=outils-mesure-streaming
CONTAINER_NAME=outils-mesure
NODE_EXPORTER_CONTAINER=node_exporter
PROM_CONFIG=prometheus.yml
PROM_CONFIG_PATH=$(REPO_DIR)/$(PROM_CONFIG)

.PHONY: clone pull build run stop clean rebuild logs prometheus-config node-exporter-start node-exporter-stop node-exporter-logs

# Cloner le dépôt si absent
clone:
	@if [ ! -d "$(REPO_DIR)" ]; then \
		echo "Clonage du dépôt..."; \
		git clone $(REPO_URL); \
	else \
		echo "Le dépôt '$(REPO_DIR)' existe déjà."; \
	fi

# Mettre à jour le dépôt s'il existe
pull:
	@if [ -d "$(REPO_DIR)" ]; then \
		echo "Mise à jour du dépôt..."; \
		cd $(REPO_DIR) && git pull; \
	else \
		echo "Le dépôt n'existe pas. Lancez 'make clone' d'abord."; \
	fi

# Générer un fichier de configuration Prometheus de base si absent
prometheus-config:
	@if [ ! -f "$(PROM_CONFIG_PATH)" ]; then \
		echo "Création du fichier $(PROM_CONFIG)..."; \
		mkdir -p $(REPO_DIR); \
		cat <<EOF > $(PROM_CONFIG_PATH) \
global:\n  scrape_interval: 15s\n\
scrape_configs:\n\
  - job_name: 'prometheus'\n\
    static_configs:\n\
      - targets: ['localhost:9090']\n\
  - job_name: 'node-exporter'\n\
    static_configs:\n\
      - targets: ['localhost:9100']\
EOF \
	else \
		echo "$(PROM_CONFIG) existe déjà."; \
	fi

# Construire l'image Docker
build: pull prometheus-config
	@echo "Construction de l'image Docker..."
	@DOCKER_BUILDKIT=1 docker build -t $(IMAGE_NAME) $(REPO_DIR)

# Lancer le conteneur principal avec Prometheus configuré
run:
	@echo "Lancement du conteneur Docker principal avec Prometheus et Grafana..."
	@docker run -d --name $(CONTAINER_NAME) \
		-p 3000:3000 -p 9090:9090 \
		-v $(PROM_CONFIG_PATH):/etc/prometheus/prometheus.yml \
		$(IMAGE_NAME)

# Lancer Node Exporter (pour monitorer la VM)
node-exporter-start:
	@echo "Lancement de Node Exporter (accès au système hôte)..."
	@docker rm -f $(NODE_EXPORTER_CONTAINER) 2>/dev/null || true
	@docker run -d \
		--name $(NODE_EXPORTER_CONTAINER) \
		--net="host" \
		--pid="host" \
		-v "/:/host:ro,rslave" \
		quay.io/prometheus/node-exporter:latest \
		--path.rootfs=/host

# Arrêter et supprimer Node Exporter
node-exporter-stop:
	@echo "Arrêt et suppression de Node Exporter..."
	@docker stop $(NODE_EXPORTER_CONTAINER) || true
	@docker rm $(NODE_EXPORTER_CONTAINER) || true

# Logs Node Exporter
node-exporter-logs:
	@docker logs -f $(NODE_EXPORTER_CONTAINER)

# Afficher les logs du conteneur principal
logs:
	@docker logs -f $(CONTAINER_NAME)

# Arrêter et supprimer le conteneur principal
stop:
	@echo "Arrêt et suppression du conteneur principal..."
	@docker stop $(CONTAINER_NAME) || true
	@docker rm $(CONTAINER_NAME) || true

# Supprimer image et conteneur principal
clean: stop node-exporter-stop
	@echo "Suppression de l'image Docker..."
	@docker rmi $(IMAGE_NAME) || true

# Tout refaire proprement
rebuild: clean clone build

