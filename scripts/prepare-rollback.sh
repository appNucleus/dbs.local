#!/usr/bin/env bash
set -Eeuo pipefail

: "${DEPLOY_ENV_FILE:?DEPLOY_ENV_FILE is required}"
if [[ -f "$DEPLOY_ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$DEPLOY_ENV_FILE"
  set +a
fi

: "${BACKUP_ROOT:?BACKUP_ROOT is required}"
: "${ROLLBACK_STATE_DIR:?ROLLBACK_STATE_DIR is required}"

umask 077
rm -rf -- "$ROLLBACK_STATE_DIR"
mkdir -p "$ROLLBACK_STATE_DIR/source"
mkdir -p "$BACKUP_ROOT"

printf 'false\n' > "$ROLLBACK_STATE_DIR/has-rollback"

previous_backup=""
while IFS= read -r candidate; do
  if [[ -f "$candidate/.db-success-backup" && \
        -f "$candidate/source/compose.yaml" && \
        -f "$candidate/runtime.env" ]]; then
    previous_backup="$candidate"
    break
  fi
done < <(
  find "$BACKUP_ROOT" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    ! -name '.staging-*' \
    -printf '%T@ %p\n' 2>/dev/null |
    sort -nr |
    cut -d' ' -f2-
)

if [[ -n "$previous_backup" ]]; then
  cp -a "$previous_backup" "$ROLLBACK_STATE_DIR/previous-backup"
  cp -a "$previous_backup/source/." "$ROLLBACK_STATE_DIR/source/"
  install -m 600 "$previous_backup/runtime.env" "$ROLLBACK_STATE_DIR/runtime.env"
  printf '%s\n' "$previous_backup" > "$ROLLBACK_STATE_DIR/previous-backup-path.txt"
  printf 'true\n' > "$ROLLBACK_STATE_DIR/has-rollback"

  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "HAS_ROLLBACK=true" >> "$GITHUB_ENV"
  fi

  echo "Prepared rollback from managed successful backup: $previous_backup"
  exit 0
fi

# Transitional first-run fallback: if a container is currently running but this
# workflow has not created a managed backup yet, preserve the current runtime env.
# For this DB stack, reliable rollback becomes fully available after the first
# successful managed deployment backup is created.
representative_container="${DASHBOARD_CONTAINER_NAME:-db-dashboard}"
if docker container inspect "$representative_container" >/dev/null 2>&1; then
  git archive --format=tar HEAD | tar -xf - -C "$ROLLBACK_STATE_DIR/source"
  install -m 600 "$DEPLOY_ENV_FILE" "$ROLLBACK_STATE_DIR/runtime.env"
  printf 'true\n' > "$ROLLBACK_STATE_DIR/has-rollback"

  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "HAS_ROLLBACK=true" >> "$GITHUB_ENV"
  fi

  echo "No managed backup exists yet; prepared a limited first-run rollback from the current checkout and runtime env."
  exit 0
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "HAS_ROLLBACK=false" >> "$GITHUB_ENV"
fi

echo "No previous managed DB deployment backup was found. This appears to be the first deployment; automatic rollback is unavailable until the first successful backup is created."
