#!/usr/bin/env bash
# Shared helpers for db.local scripts. Source this file from other scripts.

set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

runtime_env_file="${DEPLOY_ENV_FILE:-$repo_root/.env}"

ensure_runtime_env_file() {
  mkdir -p "$(dirname "$runtime_env_file")"

  if [[ ! -f "$runtime_env_file" ]]; then
    if [[ -f "$repo_root/.env.example" ]]; then
      install -m 600 "$repo_root/.env.example" "$runtime_env_file"
      echo "Created runtime environment file: $runtime_env_file"
    else
      echo "Missing .env.example; cannot create runtime environment file." >&2
      exit 1
    fi
  else
    chmod 600 "$runtime_env_file" 2>/dev/null || true
  fi
}

load_runtime_env() {
  if [[ -f "$runtime_env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$runtime_env_file"
    set +a
  fi
}

repo_path() {
  local path_value="$1"

  if [[ "$path_value" = /* ]]; then
    printf '%s' "$path_value"
  else
    printf '%s/%s' "$repo_root" "${path_value#./}"
  fi
}

compose() {
  docker compose --env-file "$runtime_env_file" "$@"
}
