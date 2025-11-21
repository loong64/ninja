ARG BASE_IMAGE=ghcr.io/loong64/anolis:23

FROM ${BASE_IMAGE} AS build-ninja
ARG TARGETARCH

RUN set -ex \
    && dnf -y install dnf-plugins-core \
    && if [ "${TARGETARCH}" != "loong64" ]; then \
        dnf config-manager --set-enabled powertools; \
    fi \
    && dnf install -y clang-analyzer cmake gcc-c++ git gtest-devel libasan make ninja-build \
    && dnf clean all

ARG VERSION
ARG WORKDIR=/opt/ninja

RUN git clone --depth=1 --branch ${VERSION} https://github.com/ninja-build/ninja ${WORKDIR}

WORKDIR ${WORKDIR}

RUN set -ex \
    && cmake -GNinja -DCMAKE_BUILD_TYPE=Release -B release-build \
    && cmake --build release-build --parallel --config Release \
    && strip release-build/ninja \
    && cd release-build \
    && if [ "${TARGETARCH}" = "s390x" ]; then \
        ./ninja_test || true; \
    else \
        ./ninja_test; \
    fi \
    && ./ninja --version

FROM ${BASE_IMAGE}
ARG TARGETARCH

COPY --from=build-ninja /opt/ninja/release-build/ninja /opt/dist/ninja

VOLUME /dist

CMD cp -f /opt/dist/ninja /dist/