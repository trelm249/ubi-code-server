FROM registry.access.redhat.com/ubi9/ubi-init

ARG TARGETARCH

RUN set -o errexit -o nounset \
    && dnf -y upgrade --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0 \
    && dnf install -y unzip sudo less libatomic git --nodocs --setopt=install_weak_deps=0 \
    && dnf clean all

# pull the aws cli from aws
RUN if [ $TARGETARCH = "arm64" ]; then \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" \
    ; else \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    ; fi

# install the aws cli
RUN set -o errexit -o nounset \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip \
    && rm -rf ./aws/ \
    && aws --version

# Add devuser and home directory
RUN set -o errexit -o nounset \
    && echo "Adding coder user and group" \
    && groupadd --system --gid 1000 devuser \
    && useradd --system -g devuser -G wheel --uid 1000 -m -d /home/devuser -c "dev user" devuser \
    && chown devuser:devuser /home/devuser 

# Add devuser to sudoers
COPY ./files/devuser /etc/sudoers.d/devuser
RUN chown root:root /etc/sudoers.d/devuser

# install code-server
RUN \
  CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||') \
  && printf ${CODE_RELEASE} \
  && if [ $TARGETARCH = "arm64" ]; then \
    curl -fOL "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-arm64.rpm" \
    && rpm -i code-server-${CODE_RELEASE}-arm64.rpm; else \
    curl -fOL "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-amd64.rpm" \
    && rpm -i code-server-${CODE_RELEASE}-amd64.rpm; fi 

WORKDIR /home/devuser/

USER devuser

# ports
EXPOSE 8443

ENTRYPOINT ["code-server", "--auth", "none", "--bind-addr", "0.0.0.0:8443"]
