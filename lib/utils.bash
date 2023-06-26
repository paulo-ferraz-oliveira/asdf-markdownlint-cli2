#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/DavidAnson/markdownlint-cli2"
TOOL_NAME="markdownlint-cli2"
BASE_TOOL="node_modules/.bin/markdownlint-cli2"
TOOL_TEST="$BASE_TOOL _version"

fail() {
	printf "asdf-%s: $*\n" "$TOOL_NAME"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//'
}

list_all_versions() {
	list_github_tags
}

download_release() {
	local version destination
	version="$1"
	destination="$2"

	printf "* Downloading %s release %s...\n" "$TOOL_NAME" "$version"
	npm pack --silent "${TOOL_NAME}@${version}" --pack-destination "$destination" >/dev/null
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cd "$install_path"

		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"
		npm --silent install markdownlint-cli2 --save-dev >/dev/null

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
