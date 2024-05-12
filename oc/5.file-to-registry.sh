#!/bin/bash

. env.sh

# check oc command is exist
if command -v oc-mirror >/dev/null 2>&1; then
	echo "oc-mirror command is exists."
else
	echo "oc-mirror command is not exists!"
	exit 1
fi

if [ ! -f pull-secret-private.json ]; then
        echo "pullsecret not found.."
	podman login -u ${SRC_REGISTRY_ID} -p ${SRC_REGISTRY_PASS} ${SRC_REGISTRY}:${SRC_REGISTRY_PORT}
        cat /run/user/$(id -u)/containers/auth.json |jq -c > pull-secret-private.json
fi

# Push OCP Cluster Operator Container Image to Registry


if [ -d "mirror-release" ]; then
  oc-mirror --from ./mirror-release docker://container-registry.kcbcore.com/okd4
fi

if [ -d "mirror-operator" ]; then
  oc-mirror --from ./mirror-operator docker://container-registry.kcbcore.com/operator
fi