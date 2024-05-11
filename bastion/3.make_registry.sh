#!/bin/bash

. ./env.sh

# Check Current Path
echo $CURRENTPATH

# make directories
mkdir -p $SRC_REGISTRY_BASE/{auth,certs,data,tools}


# create cert
openssl genrsa -out $SRC_REGISTRY_BASE/certs/rootCA.key 4096

openssl req -x509 -new -nodes -key $SRC_REGISTRY_BASE/certs/rootCA.key -sha256 -days 36500 -out $SRC_REGISTRY_BASE/certs/rootCA.crt -subj "/CN=Private CA"

openssl req -addext "subjectAltName=DNS:$SRC_REGISTRY" -new -nodes -out $SRC_REGISTRY_BASE/certs/server-registry.csr -keyout $SRC_REGISTRY_BASE/certs/server-registry.key -subj "/CN=$SRC_REGISTRY"

cat > $SRC_REGISTRY_BASE/certs/server.ext << EOF
subjectAltName = @alt_names

[alt_names]
DNS = $SRC_REGISTRY
EOF

openssl x509 -req -in $SRC_REGISTRY_BASE/certs/server-registry.csr -CA $SRC_REGISTRY_BASE/certs/rootCA.crt -CAkey $SRC_REGISTRY_BASE/certs/rootCA.key -CAcreateserial -out $SRC_REGISTRY_BASE/certs/server-registry.crt -days 36500 -extfile $SRC_REGISTRY_BASE/certs/server.ext

cat $SRC_REGISTRY_BASE/certs/server-registry.crt $SRC_REGISTRY_BASE/certs/rootCA.crt > $SRC_REGISTRY_BASE/certs/fullchain-registry.crt

# copy cert and update-ca-trust
cp $SRC_REGISTRY_BASE/certs/rootCA.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

# create htpasswd auth
htpasswd -bBc $SRC_REGISTRY_BASE/auth/htpasswd $SRC_REGISTRY_ID $SRC_REGISTRY_PASS

# load registry image
#podman load -i $CURRENTPATH/registry.tar

# create registry run script
echo -e "podman run --name ocp-registry --rm -d -p ${SRC_REGISTRY_PORT}:5000 \\
-v ${SRC_REGISTRY_BASE}/data:/var/lib/registry:z \\
-v ${SRC_REGISTRY_BASE}/auth:/auth:z \\
-v ${SRC_REGISTRY_BASE}/certs:/certs:z \\
-e REGISTRY_AUTH=htpasswd \\
-e REGISTRY_AUTH_HTPASSWD_REALM=Registry \\
-e REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry \\
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \\
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain-registry.crt \\
-e REGISTRY_HTTP_TLS_KEY=/certs/server-registry.key \\
-e REGISTRY_STORAGE_DELETE_ENABLED=true \\
docker.io/library/registry:latest" > $SRC_REGISTRY_BASE/tools/start_registry.sh

# change file permission
chmod +x $SRC_REGISTRY_BASE/tools/start_registry.sh

# run registry
$SRC_REGISTRY_BASE/tools/start_registry.sh





# test tmp_registry
sleep 2
echo -e "\n test registry"
curl -u $SRC_REGISTRY_ID:$SRC_REGISTRY_PASS -k https://$SRC_REGISTRY:$SRC_REGISTRY_PORT/v2/_catalog