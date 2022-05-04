#!/bin/bash
for appname in apps/* ; do
    appname=$(basename $appname)

    echo "Building $appname"
    buildfile=
    if [ -f "apps/$appname/$appname.yml" ]; then
        buildfile="apps/$appname/$appname.yml"
    fi
    if [ -f "apps/$appname/$appname.json" ]; then
        buildfile="apps/$appname/$appname.json"
    fi

    if [ ! $buildfile ]; then
        echo "Could not find builder config for $appname, skipping"
        continue
    fi

    flatpak-builder --skip-if-unchanged \
        --force-clean \
        --install-deps-from=flathub \
        --user \
        --delete-build-dirs \
        --gpg-sign=8614ED0F606A2EEE \
        --collection-id=blue.jozen.Thiccpak \
        --repo=repo build $buildfile
    status=$?

    if [[ $status -ne 0 ]] ; then
        [ $status -eq 42 ] && continue || exit $status
    fi
done

# Build .flatpakref files
FLATPAK_SIGN_GPG_PUB=$(base64 --wrap=0 < key.pub.gpg)
mkdir -p public/appstream/

for appname in apps/* ; do
    appname=$(basename $appname)

    OSTREE_OUT=$(ostree refs --repo=repo -c blue.jozen.Thiccpak | grep -oP "blue\.jozen\.Thiccpak, \K.+/$appname/.+(?=\))") # Shouldn't get .Debug, .Sources, etc
    APP_BRANCH=$(echo $OSTREE_OUT | awk -F/ '{print $4}')
    APP_TYPE=$(echo $OSTREE_OUT | awk -F/ '{print $1}')

    printf "[Flatpak Ref]\n" > public/appstream/$appname.flatpakref
    printf "Name=%s\n" $appname >> public/appstream/$appname.flatpakref
    printf "Branch=%s\n" $APP_BRANCH >> public/appstream/$appname.flatpakref
    printf "Title=%s from Thiccpak\n" $appname >> public/appstream/$appname.flatpakref
    if [ $APP_TYPE == 'runtime' ]; then
        printf "IsRuntime=%s\n" "true" >> public/appstream/$appname.flatpakref
    else
        printf "IsRuntime=%s\n" "false" >> public/appstream/$appname.flatpakref
    fi
    printf "Url=%s\n" "https://thiccpak.jozen.blue/" >> public/appstream/$appname.flatpakref
    printf "DeployCollectionID=%s\n" "blue.jozen.Thiccpak" >> public/appstream/$appname.flatpakref
    printf "SuggestRemoteName=%s\n" "thiccpak" >> public/appstream/$appname.flatpakref
    printf "RuntimeRepo=%s\n" "https://dl.flathub.org/repo/flathub.flatpakrepo" >> public/appstream/$appname.flatpakref
    printf "GPGKey=%s\n" $FLATPAK_SIGN_GPG_PUB >> public/appstream/$appname.flatpakref
done
