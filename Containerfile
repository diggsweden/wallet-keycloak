# SPDX-FileCopyrightText: 2026 Digg - Agency for Digital Government
#
# SPDX-License-Identifier: EUPL-1.2

ARG KEYCLOAK_VERSION=26.7.1
ARG KEYCLOAK_DIGEST=sha256:f1f1f01e472c8a78df40d8f2a49a925274eda4d3d80d5f6edbb5c880ee3c01c6

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}@${KEYCLOAK_DIGEST} AS builder

ARG ABCA_EXT_VERSION=0.2.2

# hadolint ignore=DL3020
ADD --chown=keycloak:keycloak https://repo1.maven.org/maven2/eu/europa/ec/eudi/abca-keycloak-ext/${ABCA_EXT_VERSION}/abca-keycloak-ext-${ABCA_EXT_VERSION}.jar /opt/keycloak/providers/abca-keycloak-ext-${ABCA_EXT_VERSION}.jar

RUN /opt/keycloak/bin/kc.sh build \
    --features=dpop \
    --health-enabled=true \
    --metrics-enabled=true \
    --http-relative-path=/idp \
    --db=dev-file

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}@${KEYCLOAK_DIGEST}
COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY --chown=keycloak:keycloak config/realms/ /opt/keycloak/data/import/
COPY --chown=keycloak:keycloak config/themes/ /opt/keycloak/themes/

WORKDIR /opt/keycloak
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized", "--import-realm"]
