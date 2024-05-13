#!/bin/bash

. ./env.sh

# Check Current Path
echo $CURRENTPATH


# Get the current user
current_user=$(whoami)

# Check if the current user is root
if [ "$current_user" != "root" ]; then

mkdir -p ~/.config/containers && echo -e "[containers]\nlog_size_max=10485760" >> ~/.config/containers/containers.conf

fi


# if DockerRegistry
if [ "$SRC_REGISTRY_TYPE" == "DockerRegistry" ]; then
	
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

cp $SRC_REGISTRY_BASE/certs/rootCA.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract



# test tmp_registry
sleep 2
echo -e "\n test registry"
curl -u $SRC_REGISTRY_ID:$SRC_REGISTRY_PASS -k https://$SRC_REGISTRY:$SRC_REGISTRY_PORT/v2/_catalog


# if ProjectQUAY	
elif [ "$SRC_REGISTRY_TYPE" == "ProjectQUAY" ]; then 


# make directories
mkdir -p $SRC_REGISTRY_BASE/certs


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


mkdir -p $SRC_REGISTRY_BASE/postgres-quay
setfacl -m u:26:rwx $SRC_REGISTRY_BASE/postgres-quay
podman unshare chown 26:26 $SRC_REGISTRY_BASE/postgres-quay
podman run -d --name postgresql-quay -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=quay -p  5432:5432 -e PGDATA=/var/lib/pgsql/pgdata -v $SRC_REGISTRY_BASE/postgres-quay:/var/lib/pgsql/pgdata:Z registry.redhat.io/rhel8/postgresql-10:1-205.1675799491

sleep 10

podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U user' CREATE EXTENSION


podman run -d --name redis -p 6379:6379 -e REDIS_PASSWORD=pass registry.redhat.io/rhel8/redis-6:1-102.1675799509


mkdir $SRC_REGISTRY_BASE/storage
setfacl -m u:1001:rwx $SRC_REGISTRY_BASE/storage
mkdir -p $SRC_REGISTRY_BASE/config/extra_ca_certs

cp $SRC_REGISTRY_BASE/certs/rootCA.crt $SRC_REGISTRY_BASE/config/extra_ca_certs/
cp $SRC_REGISTRY_BASE/certs/fullchain-registry.crt $SRC_REGISTRY_BASE/config/ssl.cert
cp $SRC_REGISTRY_BASE/certs/server-registry.key $SRC_REGISTRY_BASE/config/ssl.key

cat > $SRC_REGISTRY_BASE/config/config.yaml << EOF
ACTION_LOG_ARCHIVE_LOCATION: default
ALLOW_PULLS_WITHOUT_STRICT_LOGGING: true
AUTHENTICATION_TYPE: Database
AVATAR_KIND: local
BUILDLOGS_REDIS:
    host: $BA_IP
    password: pass
    port: 6379
CONTACT_INFO:
    - tel:000-0000-0000
DATABASE_SECRET_KEY: 3e9c7469-5881-46b1-bc7e-da0760f76fd5
DB_CONNECTION_ARGS: {}
DB_URI: postgresql://user:pass@$BA_IP/quay
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
    default:
        - LocalStorage
        - storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE:
    - default
EXTERNAL_TLS_TERMINATION: false
FEATURE_ACI_CONVERSION: false
FEATURE_ACTION_LOG_ROTATION: false
FEATURE_ANONYMOUS_ACCESS: true
FEATURE_APP_REGISTRY: true
FEATURE_APP_SPECIFIC_TOKENS: true
FEATURE_BITBUCKET_BUILD: false
FEATURE_BLACKLISTED_EMAILS: false
FEATURE_BUILD_SUPPORT: false
FEATURE_CHANGE_TAG_EXPIRATION: true
FEATURE_DIRECT_LOGIN: true
FEATURE_EXTENDED_REPOSITORY_NAMES: true
FEATURE_FIPS: false
FEATURE_GITHUB_BUILD: false
FEATURE_GITHUB_LOGIN: false
FEATURE_GITLAB_BUILD: false
FEATURE_GOOGLE_LOGIN: false
FEATURE_INVITE_ONLY_USER_CREATION: false
FEATURE_MAILING: false
FEATURE_NONSUPERUSER_TEAM_SYNCING_SETUP: false
FEATURE_PARTIAL_USER_AUTOCOMPLETE: true
FEATURE_PROXY_STORAGE: false
FEATURE_REPO_MIRROR: true
FEATURE_REQUIRE_TEAM_INVITE: true
FEATURE_RESTRICTED_V1_PUSH: true
FEATURE_SECURITY_NOTIFICATIONS: false
FEATURE_SECURITY_SCANNER: false
FEATURE_STORAGE_REPLICATION: false
FEATURE_TEAM_SYNCING: false
FEATURE_USER_CREATION: true
FEATURE_USER_LAST_ACCESSED: true
FEATURE_USER_LOG_ACCESS: false
FEATURE_USER_METADATA: false
FEATURE_USER_RENAME: false
FEATURE_USERNAME_CONFIRMATION: true
FRESH_LOGIN_TIMEOUT: 10m
GITHUB_LOGIN_CONFIG: {}
GITHUB_TRIGGER_CONFIG: {}
GITLAB_TRIGGER_KIND: {}
LDAP_ALLOW_INSECURE_FALLBACK: false
LDAP_EMAIL_ATTR: mail
LDAP_UID_ATTR: uid
LDAP_URI: ldap://localhost
LOG_ARCHIVE_LOCATION: default
LOGS_MODEL: database
LOGS_MODEL_CONFIG: {}
MAIL_DEFAULT_SENDER: support@quay.io
MAIL_PORT: 587
MAIL_USE_AUTH: false
MAIL_USE_TLS: false
PREFERRED_URL_SCHEME: https
REGISTRY_TITLE: Project Quay
REGISTRY_TITLE_SHORT: Project Quay
REPO_MIRROR_INTERVAL: 30
REPO_MIRROR_TLS_VERIFY: true
SEARCH_MAX_RESULT_PAGE_COUNT: 10
SEARCH_RESULTS_PER_PAGE: 10
SECRET_KEY: 5655f996-2901-4bb9-a981-bb3f944f4e8f
SECURITY_SCANNER_INDEXING_INTERVAL: 30
SERVER_HOSTNAME: $SRC_REGISTRY
SETUP_COMPLETE: true
SUPER_USERS:
    - admin
TAG_EXPIRATION_OPTIONS:
    - 0s
    - 1d
    - 1w
    - 2w
    - 4w
TEAM_RESYNC_STALE_TIME: 30m
TESTING: false
USE_CDN: false
USER_EVENTS_REDIS:
    host: $BA_IP
    password: pass
    port: 6379
USER_RECOVERY_TOKEN_LIFETIME: 30m
USERFILES_LOCATION: default
EOF

chmod a+rx -R $SRC_REGISTRY_BASE/config


podman run -p 443:8443 --name=quay -v $SRC_REGISTRY_BASE/config:/conf/stack:Z -v $SRC_REGISTRY_BASE/storage:/datastorage:Z -d quay.io/projectquay/quay:3.8.2



echo "you must execute this command at root"
echo "======================================================================== "
echo "cp $SRC_REGISTRY_BASE/certs/rootCA.crt /etc/pki/ca-trust/source/anchors/ "
echo "update-ca-trust extract"
echo "======================================================================== "


fi




