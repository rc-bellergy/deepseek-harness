#!/bin/sh
# The Web profile's webserver rejects wildcard bind addresses, so bind the
# container's first external IPv4 address; Docker's published port forwards to it.
set -eu

BIND_HOST="$(node --input-type=commonjs -e '
const os = require("node:os")
const found = Object.values(os.networkInterfaces())
  .flat()
  .find((a) => a && !a.internal && (a.family === "IPv4" || a.family === 4))
if (found === undefined) {
  console.error("entrypoint: no external IPv4 interface to bind")
  process.exit(1)
}
process.stdout.write(found.address)
')"

exec node /repo/apps/cli/lib/bin.js web \
  --host "$BIND_HOST" \
  --port "${DSH_WEB_PORT:-3080}" \
  --no-open \
  "$@"
