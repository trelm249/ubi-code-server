FROM registry.access.redhat.com/ubi9

ARG TARGETARCH

RUN set -o errexit -o nounset \
    && dnf -y upgrade --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0 \
#    && dnf install -y jq gnupg shadow-utils --nodocs --setopt=install_weak_deps=0 \
#    && dnf install -y unzip which curl less groff-base --nodocs --setopt=install_weak_deps=0
    && dnf install -y unzip sudo less --nodocs --setopt=install_weak_deps=0 \
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

COPY ./files/devuser /etc/sudoers.d/devuser

RUN chown root:root /etc/sudoers.d/devuser

WORKDIR /home/devuser

USER devuser
