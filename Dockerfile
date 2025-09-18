FROM debian:bookworm-slim

LABEL maintainer="Maxence Winandy <maxence.winandy@digital-drive.io>"

ARG VER=1.7.0
ARG INSTALL_DIR=/crowdsec-v$VER
ARG CS_TARBALL=crowdsec-release.tgz
ARG CS_SHA256="4b318d4a301cb9c88d53a7455d752343112540b88d85c46a63b1fc79f8d712ab"

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="${INSTALL_DIR}/tests/:${PATH}"

COPY banner.txt /etc/container-message
RUN echo 'cat /etc/container-message' >> /root/.bashrc

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        gettext-base \
        git \
        rsync \
        sqlite3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

WORKDIR /
RUN curl -fsSL "https://github.com/crowdsecurity/crowdsec/releases/download/v${VER}/crowdsec-release.tgz" -o "${CS_TARBALL}" \
 && if [[ -n "${CS_SHA256}" ]]; then echo "${CS_SHA256}  ${CS_TARBALL}" | sha256sum -c -; fi \
 && tar xzf "${CS_TARBALL}" \
 && rm -f "${CS_TARBALL}"



# Préparation environnement crowdsec
WORKDIR "${INSTALL_DIR}"
RUN ./test_env.sh

# Patch de la config en une seule passe
RUN sed -i \
    -e 's/^\([[:space:]]*\)#simulation_path:/\1simulation_path:/' \
    -e 's/^\([[:space:]]*\)#hub_dir:/\1hub_dir:/' \
    -e 's/^\([[:space:]]*\)#index_path:/\1index_path:/' \
    -e "s#/etc/crowdsec/hub/#${INSTALL_DIR}/tests/hub/#g" \
    -e "s#\./config/hub/.index.json#${INSTALL_DIR}/tests/hub/.index.json#g" \
    -e "s#/etc/crowdsec/config/#${INSTALL_DIR}/tests/config/#g" \
    -e "s#\./config#${INSTALL_DIR}/tests/config#g" \
    -e "s#\./data/#${INSTALL_DIR}/tests/data/#g" \
    -e "s#\./plugins/#${INSTALL_DIR}/tests/plugins/#g" \
    "${INSTALL_DIR}/tests/dev.yaml"

# Zone de tests
WORKDIR "${INSTALL_DIR}/tests"

# Hub local shallow clone pour accélérer et mieux utiliser le cache
RUN git clone --filter=blob:none --depth=1 https://github.com/crowdsecurity/hub hub

# Alias csdev
RUN printf "alias csdev='%s/tests/cscli -c %s/tests/dev.yaml'\n" "${INSTALL_DIR}" "${INSTALL_DIR}" >> /root/.bashrc

# Lancement des tests hub
WORKDIR "${INSTALL_DIR}/tests/hub"
RUN "${INSTALL_DIR}/tests/cscli" -c "${INSTALL_DIR}/tests/dev.yaml" hubtest run --all

CMD ["/bin/bash"]