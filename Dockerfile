# DeepSeek Harness Web profile image: builds repository artifacts, then serves `dsh web`.
FROM node:24-bookworm

# python3: node-gyp for node-pty and the native flock addon; bubblewrap: the
# Linux sandbox runner; git: repository-aware tools inside sessions.
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 bubblewrap git \
  && rm -rf /var/lib/apt/lists/*

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable

WORKDIR /repo
COPY . .

# Corepack resolves the pinned pnpm from package.json (packageManager field).
RUN --mount=type=cache,target=/root/.local/share/pnpm pnpm install --frozen-lockfile

# .git stays out of the build context; build metadata reads the commit from
# this variable instead. Stamp the real one with:
#   DSH_CLIENT_COMMIT_HASH=$(git rev-parse --short=7 HEAD) docker compose build
ARG DSH_CLIENT_COMMIT_HASH=0000000
ENV DSH_CLIENT_COMMIT_HASH=${DSH_CLIENT_COMMIT_HASH}
RUN pnpm run build:artifacts

# Harness state (sessions, credentials, settings) persists under /data.
ENV DSH_HOME=/data
EXPOSE 3080
ENTRYPOINT ["/repo/docker/web-entrypoint.sh"]
