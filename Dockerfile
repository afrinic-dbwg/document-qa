FROM debian:10-slim

# Install base dependencies
RUN apt update -q && \
    apt install -yq git \
                    hunspell \
                    hunspell-en-us \
                    nodejs \
                    npm

# Install markdown lint dependencies
RUN npm install -g markdownlint-cli

# Set action directory
ENV ACTION_DIR="/opt/document-qa-action"
RUN mkdir -p "${ACTION_DIR}"

# Set working directory
ENV WORKING_DIR="/opt/working"
RUN mkdir -p "${WORKING_DIR}"
VOLUME $WORKING_DIR

# Copy config files
COPY dictionary markdownlint.yml "${ACTION_DIR}/"

# Add entrypoint
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
