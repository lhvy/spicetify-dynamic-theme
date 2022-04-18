#!/bin/sh

set -e

cd "$(dirname "$(spicetify -c)")"

echo "Uninstalling (1/2)"
cd "$(dirname "$(spicetify -c)")"
spicetify config current_theme "SpicetifyDefault" color_scheme "green-dark" extensions default-dynamic.js- extensions Vibrant.min.js-

echo "Deleting (2/2)"
while true; do
    read -p "Do you wish to delete theme files? [y/n] " yn </dev/tty
    case $yn in
    [Yy]*)
        theme_dir="$(dirname "$(spicetify -c)")/Themes/DefaultDynamic"
        ext_dir="$(dirname "$(spicetify -c)")/Extensions"
        rm -rf "$theme_dir"
        # Use -f to ignore if missing
        rm -f "$ext_dir/default-dynamic.js"
        rm -f "$ext_dir/Vibrant.min.js"
        break
        ;;
    [Nn]*)
        echo "Skipping deletion."
        break
        ;;
    *) echo "Please answer yes or no." ;;
    esac
done

spicetify apply
