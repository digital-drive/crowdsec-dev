FROM debian:bookworm

LABEL maintainer="Maxence Winandy <maxence.winandy@digital-drive.io>"

ARG VER=1.7.0
ARG INSTALL_DIR=/crowdsec-v$VER

ADD https://github.com/crowdsecurity/crowdsec/releases/download/v$VER/crowdsec-release.tgz crowdsec-release.tgz

COPY banner.txt /etc/container-message
RUN echo 'cat /etc/container-message' >> /root/.bashrc

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        gettext-base \
        wget \
        git \
        rsync \
        sqlite3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

RUN tar xvzf crowdsec-release.tgz

WORKDIR /crowdsec-v$VER
RUN ./test_env.sh #-d /crowdsec-v$VER/tests/

WORKDIR tests/

RUN git clone https://github.com/crowdsecurity/hub hub


RUN echo "alias csdev='${INSTALL_DIR}/tests/cscli -c ${INSTALL_DIR}/tests/dev.yaml'" >> /root/.bashrc

RUN sed -i 's/^\([[:space:]]*\)#simulation_path:/\1simulation_path:/' ${INSTALL_DIR}/tests/dev.yaml
RUN sed -i 's/^\([[:space:]]*\)#hub_dir:/\1hub_dir:/' ${INSTALL_DIR}/tests/dev.yaml
RUN sed -i 's/^\([[:space:]]*\)#index_path:/\1index_path:/' ${INSTALL_DIR}/tests/dev.yaml

RUN sed -i "s#/etc/crowdsec/hub/#${INSTALL_DIR}/tests/hub/#g" ${INSTALL_DIR}/tests/dev.yaml
RUN sed -i "s#\./config/hub/.index.json#${INSTALL_DIR}/tests/hub/.index.json#g" ${INSTALL_DIR}/tests/dev.yaml

RUN sed -i "s#/etc/crowdsec/config/#${INSTALL_DIR}/tests/config/#g" ${INSTALL_DIR}/tests/dev.yaml

RUN sed -i  -e "s#\./config#${INSTALL_DIR}/tests/config#g" \
            -e "s#\./data/#${INSTALL_DIR}/tests/data/#g" \
            -e "s#\./plugins/#${INSTALL_DIR}/tests/plugins/#g" \
            ${INSTALL_DIR}/tests/dev.yaml

ENV PATH="${INSTALL_DIR}/tests/:${PATH}"

WORKDIR hub/

RUN $INSTALL_DIR/tests/cscli -c $INSTALL_DIR/tests/dev.yaml hubtest run --all

CMD ["/bin/bash"]