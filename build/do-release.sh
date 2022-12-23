#!/bin/bash

export default_branch="main"

function ensure_release_notes() {
  release_notes_file="$1"
  if [[ ! -f "${release_notes_file}" ]]; then
    >&2 echo "Must have release notes ${release_notes_file}"
    exit 6
  fi
}

function create_branch_if_doesnt_exist() {
  wanted_branch="$1"
  if ! git checkout "${wanted_branch}" >/dev/null; then
      echo "Creating ${wanted_branch} from $(git branch --show-current)"
      git checkout -b "${wanted_branch}"
      git push origin "$(git branch --show-current)"
  else
      git checkout "${wanted_branch}"
      git pull --ff-only origin "${release_branch}"
  fi
}

git config user.name "GitHub Actions Bot"
git config user.email "<>"

release_version=$(go run pkg/version/generate/release_generate.go print-version)
release_notes_file="docs/release_notes/${release_version}.md"
ensure_release_notes "${release_notes_file}"

# Create release  branch
release_branch="release-${release_version}"
create_branch_if_doesnt_exist "${release_branch}"

# Tag and push release
msg="Release ${release_version}"
git tag --annotate --message "${msg}" "${release_version}"
git push origin "${release_version}"

# Do release
export GORELEASER_CURRENT_TAG=${release_version}
curl -sfL https://goreleaser.com/static/run | bash release --rm-dist --timeout 60m --skip-validate --config=./.goreleaser.yaml --release-notes="${release_notes_file}"
