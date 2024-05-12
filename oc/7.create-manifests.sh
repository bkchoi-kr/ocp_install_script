#!/bin/bash

. env.sh

# check oc command is exist
if command -v oc >/dev/null 2>&1; then
        echo "oc command is exists."
else
        echo "oc command is not exists!"
        exit 1
fi

if ! rpm -q httpd &>/dev/null; then
    echo "httpd is not installed. you need to install httpd!"
    exit 2
fi

openshift-install create manifests --dir=$WORKDIR/install_dir/

# Create install-config.yaml
files=( template/*.bu )

# Rename and convert file extensions while iterating through an array
# template/*.bu -> template/*.yaml use butane command
for file in "${files[@]}"
do
  butane $file -o "${file%%.*}.yaml"
done

cp -v template/*.yaml install_dir/openshift/
