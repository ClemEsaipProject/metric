FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Installation de base
RUN apt-get update && apt-get install --no-install-recommends -y \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    tar \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Wireshark sans interface (mode non-interactif)
RUN apt-get update && echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections && \
    apt-get install --no-install-recommends -y \
    wireshark \
    tshark \
    && rm -rf /var/lib/apt/lists/*

# FFmpeg
RUN apt-get update && apt-get install --no-install-recommends -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Grafana (correction du chemin de la clé)
RUN wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key && \
    echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list && \
    apt-get update && apt-get install --no-install-recommends -y grafana && \
    rm -rf /var/lib/apt/lists/*

# Prometheus (correction des versions avec points)
RUN wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz && \
    tar -xzf prometheus-2.43.0.linux-amd64.tar.gz && \
    mv prometheus-2.43.0.linux-amd64/prometheus /usr/local/bin/ && \
    mv prometheus-2.43.0.linux-amd64/promtool /usr/local/bin/ && \
    mkdir /etc/prometheus && \
    mv prometheus-2.43.0.linux-amd64/prometheus.yml /etc/prometheus/ && \
    rm -rf prometheus*

# Node Exporter (correction des versions avec points)
RUN wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz && \
    tar -xzf node_exporter-1.6.1.linux-amd64.tar.gz && \
    mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/ && \
    rm -rf node_exporter*

# OWASP ZAP (correction de la version)
RUN mkdir /opt/zap && \
    wget https://github.com/zaproxy/zaproxy/releases/download/v2.14.0/ZAP_2.14.0_Linux.tar.gz && \
    tar -xzf ZAP_2.14.0_Linux.tar.gz -C /opt/zap --strip-components=1 && \
    ln -s /opt/zap/zap.sh /usr/local/bin/zaproxy && \
    rm ZAP_2.14.0_Linux.tar.gz

# Correction de la typo 'rn -> rm' et copie de la configuration
RUN apt-get update && apt-get install -y supervisor && rm -rf /var/lib/apt/lists/*
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3000 9090 9100

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]