#!/bin/bash

. ../bastion/env.sh
. env.sh

if command -v oc-mirror >/dev/null 2>&1; then
	echo "oc-mirror command is exists."
else
	echo "oc-mirror command is not exists!"
	exit 1
fi

if [ ! -f redhat-pullsecret.json ]; then
        echo "redhat-pullsecret.json not found.."

	exit 1
fi

if [ ! -f mirror-config-release.yaml ]; then
        echo "mirror-config-release.yaml not found.. example -> template/mirror-config-release.yaml_ori"
	exit 1
fi

if [ ! -f mirror-config-operator.yaml ]; then
        echo "mirror-config-operator.yaml not found.. example -> template/mirror-config-operator.yaml_ori"
	exit 1
fi


mkdir ~/.docker
yes|cp redhat-pullsecret.json ~/.docker/config.json


oc-mirror --config=./mirror-config-release.yaml file://mirror-release


oc-mirror --config=./mirror-config-operator.yaml file://mirror-operator