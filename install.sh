#!/bin/sh

set -e

echo "Finding lastest version (1/3)"
if [ $# -eq 0 ]; then
    latest_release_uri="https://api.github.com/repos/JulienMaille/spicetify-dynamic-theme/releases/latest"
    version=$(command curl -sSf "$latest_release_uri" |
        command grep -Eo "tag_name\": .*" |
        command grep -Eo "[0-9.]+")
    if [ ! "${version}" ]; then exit 1; fi
else
    version="${1}"
fi

echo "Downloading v${version} (2/3)"
# Setup directories to download to
theme_dir="$(dirname "$(spicetify -c)")/Themes/DefaultDynamic"
ext_dir="$(dirname "$(spicetify -c)")/Extensions"

# Make directories if needed
mkdir -p "${theme_dir}"
mkdir -p "${ext_dir}"

# Download latest tagged files into correct directories
curl --progress-bar --output "${theme_dir}/color.ini" "https://raw.githubusercontent.com/JulienMaille/spicetify-dynamic-theme/${version}/color.ini"
curl --progress-bar --output "${theme_dir}/user.css" "https://raw.githubusercontent.com/JulienMaille/spicetify-dynamic-theme/${version}/user.css"
curl --progress-bar --output "${ext_dir}/default-dynamic.js" "https://raw.githubusercontent.com/JulienMaille/spicetify-dynamic-theme/${version}/default-dynamic.js"
curl --progress-bar --output "${ext_dir}/Vibrant.min.js" "https://raw.githubusercontent.com/JulienMaille/spicetify-dynamic-theme/${version}/Vibrant.min.js"

echo "Applying theme (3/3)"
spicetify config extensions dribbblish.js- extensions dribbblish-dynamic.js-
spicetify config extensions default-dynamic.js extensions Vibrant.min.js
spicetify config current_theme DefaultDynamic color_scheme base
spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
spicetify apply

echo "All done!"
