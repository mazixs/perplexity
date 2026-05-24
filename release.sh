#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkgbuild="${repo_root}/aur/PKGBUILD"
srcinfo="${repo_root}/aur/.SRCINFO"

require_clean_tree() {
  if [ -n "$(git -C "${repo_root}" status --porcelain)" ]; then
    echo "Working tree is not clean. Commit or stash changes before releasing." >&2
    exit 1
  fi
}

require_main_branch() {
  local branch
  branch="$(git -C "${repo_root}" branch --show-current)"
  if [ "${branch}" != "main" ]; then
    echo "Release tags can only be created from main. Current branch: ${branch}" >&2
    exit 1
  fi
}

read_pkg_value() {
  local key="$1"
  sed -n "s/^${key}=//p" "${pkgbuild}"
}

verify_srcinfo() {
  local tmpfile
  tmpfile="$(mktemp)"
  (
    cd "${repo_root}/aur"
    makepkg --printsrcinfo
  ) > "${tmpfile}"

  if ! diff -u "${srcinfo}" "${tmpfile}" >/dev/null; then
    echo ".SRCINFO is out of date. Regenerate it before tagging." >&2
    diff -u "${srcinfo}" "${tmpfile}" || true
    rm -f "${tmpfile}"
    exit 1
  fi

  rm -f "${tmpfile}"
}

git -C "${repo_root}" fetch origin --tags

require_clean_tree
require_main_branch

local_head="$(git -C "${repo_root}" rev-parse HEAD)"
remote_head="$(git -C "${repo_root}" rev-parse origin/main)"
if [ "${local_head}" != "${remote_head}" ]; then
  echo "HEAD does not match origin/main. Pull or push main before tagging." >&2
  exit 1
fi

verify_srcinfo

pkgver="$(read_pkg_value pkgver)"
pkgrel="$(read_pkg_value pkgrel)"
tag="v${pkgver}-${pkgrel}"

if git -C "${repo_root}" show-ref --tags --verify --quiet "refs/tags/${tag}"; then
  echo "Tag ${tag} already exists." >&2
  exit 1
fi

git -C "${repo_root}" tag -a "${tag}" -m "Release ${tag}"

echo "Created tag ${tag}"
echo "Push command: git push origin main --follow-tags"
echo "If you need to abort before push: git tag -d ${tag}"
