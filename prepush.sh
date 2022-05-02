#!/bin/bash
FLATPAK_SIGN_GPG_PUB=$(base64 --wrap=0 < key.pub.gpg)
printf "GPGKey=%s\n" $FLATPAK_SIGN_GPG_PUB >> public/thiccpak.flatpakrepo

# Build JSON of apps
find apps/* -maxdepth 1 -type d -exec basename "{}" \; | jq --raw-input -c --slurp 'split("\n") | map(select(. != ""))' > public/apps.json

cp -a public/. repo/
