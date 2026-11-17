#!/usr/bin/env bash
# Check a source archive made by `git archive` against the commit it was made from.
#
# Usage: check-archive.sh <archive.tar.gz> <version> [<commit>]
#
# The archive must hold exactly one top directory, sudachidict-<version>/, and in
# it exactly the files of <commit> (default HEAD) that are not export-ignore'd,
# with the same bytes. A Git LFS file must hold its contents, not the pointer:
# its SHA-256 must equal its LFS oid. Prints ARCHIVE_OK on success.
#
# Run it from the repository; it reads <commit> and its attributes with git and
# git-lfs, and hashes the archive's files without extracting them (GNU tar).
set -euo pipefail
export LC_ALL=C

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "usage: $0 <archive.tar.gz> <version> [<commit>]" >&2
  exit 2
fi

archive=$1
version=$2
commit=${3:-HEAD}
top="sudachidict-${version}"

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

fail() {
  echo "ARCHIVE_FAIL: $*" >&2
  exit 1
}

# The top directory.
tar -tzf "${archive}" > "${work}/entries"
cut -d / -f 1 "${work}/entries" | sort -u > "${work}/tops"
if [ "$(cat "${work}/tops")" != "${top}" ]; then
  fail "the top directories are [$(paste -sd ' ' - < "${work}/tops")], not [${top}]"
fi

# The files of the commit, without the export-ignore'd paths. An attribute on a
# directory leaves out everything under it, as `git archive` does.
git ls-tree -r --name-only "${commit}" > "${work}/tracked"
awk -F / '{ p = $1; for (i = 2; i <= NF; i++) { print p; p = p "/" $i } }' "${work}/tracked" \
  | sort -u > "${work}/dirs"
cat "${work}/tracked" "${work}/dirs" \
  | git check-attr --source="${commit}" --stdin export-ignore > "${work}/export_attrs"
awk -F ': ' '$3 == "set" { print $1 }' "${work}/export_attrs" > "${work}/ignored"
awk 'NR == FNR { ignored[$0] = 1; next }
  {
    n = split($0, part, "/")
    skip = ($0 in ignored)
    p = part[1]
    for (i = 1; i < n; i++) {
      if (p in ignored) skip = 1
      p = p "/" part[i + 1]
    }
    if (!skip) print
  }' "${work}/ignored" "${work}/tracked" > "${work}/expected_paths"
if [ ! -s "${work}/expected_paths" ]; then
  fail "no file of ${commit} is expected in the archive"
fi

# The LFS oids of the commit. Every file that the attributes send to LFS must
# have one: a file without one would be checked against its blob, which is the
# pointer, and an archive of pointers would pass.
git lfs ls-files -l "${commit}" > "${work}/lfs_files"
declare -A lfs_oid=()
while read -r oid _ path; do
  lfs_oid["${path}"]=${oid}
done < "${work}/lfs_files"
git check-attr --source="${commit}" --stdin filter < "${work}/expected_paths" > "${work}/filter_attrs"
awk -F ': ' '$3 == "lfs" { print $1 }' "${work}/filter_attrs" > "${work}/lfs_paths"
while IFS= read -r path; do
  if [ -z "${lfs_oid[${path}]:-}" ]; then
    fail "${path} is an LFS file, but git lfs ls-files does not list it"
  fi
done < "${work}/lfs_paths"

# The SHA-256 each file must have: the LFS oid, or the hash of the blob.
while IFS= read -r path; do
  if [ -n "${lfs_oid[${path}]:-}" ]; then
    hash=${lfs_oid[${path}]}
  else
    hash=$(git cat-file blob "${commit}:${path}" | sha256sum | cut -d ' ' -f 1)
  fi
  printf '%s\t%s\n' "${path}" "${hash}"
done < "${work}/expected_paths" | sort > "${work}/expected"

# The SHA-256 of each file in the archive. Each line is written by the
# --to-command shell, so the variables in it are expanded there.
# shellcheck disable=SC2016
tar -xzf "${archive}" \
  --to-command='printf "%s\t%s\n" "${TAR_FILENAME#*/}" "$(sha256sum | cut -d " " -f 1)"' \
  | sort > "${work}/actual"

if ! diff "${work}/expected" "${work}/actual" > "${work}/diff"; then
  cat "${work}/diff" >&2
  fail "the files of the archive differ from ${commit} (< expected, > archive)"
fi

echo "ARCHIVE_OK ${archive}: ${top}/, $(wc -l < "${work}/actual") files"
