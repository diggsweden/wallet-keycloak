# SPDX-FileCopyrightText: 2026 Digg - Agency for Digital Government
#
# SPDX-License-Identifier: EUPL-1.2

ARG KEYCLOAK_VERSION=26.8.2
ARG KEYCLOAK_DIGEST=sha256:7e66a96e4739239070aeaf72e4c5decf0f7f682cfc725b9f7ea2b336eaba38b3

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}@${KEYCLOAK_DIGEST} AS builder

ARG ABCA_EXT_VERSION=0.2.2

# hadolint ignore=DL3020
ADD --chown=keycloak:keycloak --chmod=0644 https://repo1.maven.org/maven2/eu/europa/ec/eudi/abca-keycloak-ext/${ABCA_EXT_VERSION}/abca-keycloak-ext-${ABCA_EXT_VERSION}.jar /opt/keycloak/providers/abca-keycloak-ext-${ABCA_EXT_VERSION}.jar

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
