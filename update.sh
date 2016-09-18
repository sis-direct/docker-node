#!/bin/bash
set -e

cd $(cd ${0%/*} && pwd -P);

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )


template=
dockerfile=

function update_node_version {
	fullVersion="$(curl -sSL --compressed 'https://nodejs.org/dist' | grep '<a href="v'"$version." | sed -E 's!.*<a href="v([^"/]+)/?".*!\1!' | cut -f 3 -d . | sort -n | tail -1)"
	(
		cp $template $dockerfile
		sed -E -i.bak 's/^(ENV NODE_VERSION |FROM node:).*/\1'"$version.$fullVersion"'/' "$dockerfile"
		rm "$dockerfile.bak"

		# Don't set npm log level in 0.10 and 0.12.
		if [[ "$version" == "0.10" || "$version" == "0.12" ]]; then
			sed -E -i.bak '/^ENV NPM_CONFIG_LOGLEVEL info/d' "$dockerfile"
			rm "$dockerfile.bak"
		fi
	)
}

for version in "${versions[@]}"; do
	if [[ "$version" == "docs" ]]; then
		continue
	fi

	template="Dockerfile.template"
	dockerfile="$version/Dockerfile"

	update_node_version

	variants=$(ls -d $version/*/ | awk -F"/" '{print $2}')

	for variant in $variants; do
		template="Dockerfile-$variant.template"
		dockerfile="$version/$variant/Dockerfile"

		update_node_version

	done
done
