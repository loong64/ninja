FROM ghcr.io/loong64/opencloudos:23 AS build-ninja
ARG TARGETARCH

RUN set -ex && \
    yum install -y clang-analyzer cmake gcc-c++ gtest-devel libasan make ninja-build && \
    yum clean all

ARG NINJA_VERSION
ARG WORKDIR=/opt/ninja

WORKDIR ${WORKDIR}

RUN git clone --depth=1 --branch ${NINJA_VERSION} https://github.com/ninja-build/ninja ${WORKDIR}

RUN set -ex && \
    cmake -GNinja -DCMAKE_BUILD_TYPE=Release -B release-build && \
    cmake --build release-build --parallel --config Release && \
    strip release-build/ninja && \
    cd release-build && \
    ./ninja_test && \
    ./ninja --version

FROM ghcr.io/loong64/opencloudos:23
ARG TARGETARCH

COPY --from=build-ninja /opt/ninja/release-build/ninja /opt/dist/ninja

VOLUME /dist

CMD cp -f /opt/dist/ninja /dist/