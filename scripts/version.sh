#!/bin/bash
# Shared by application and installer builds; VERSION is committed per release.
APP_VERSION="$(cat "$(dirname "${BASH_SOURCE[0]}")/../VERSION")"
if [[ ! "$APP_VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo 'VERSION must contain a version such as 0.1.4 (without v).' >&2
  exit 1
fi
export APP_VERSION
