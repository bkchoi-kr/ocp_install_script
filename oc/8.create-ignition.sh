#!/bin/bash

. env.sh

# check oc command is exist
if command -v oc >/dev/null 2>&1; then
        echo "oc command is exists."
else
        echo "oc command is not exists!"
        exit 1
fi

# Create ignistion

openshift-install create ignition-configs --dir=$WORKDIR/install_dir/

cp -v $WORKDIR/install_dir/*.ign /var/www/html/
chmod 644 -R /var/www/html


