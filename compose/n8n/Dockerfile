FROM n8nio/n8n@sha256:85214df20cd7bc020f8e4b0f60f87ea87f0a754ca7ba3d1ccdfc503ccd6e7f9c

USER root
RUN mkdir -p /opt/n8n/custom \
  && npm install --prefix /opt/n8n/custom @n8n/n8n-nodes-langchain
USER node
