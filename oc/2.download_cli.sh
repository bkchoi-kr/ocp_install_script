#!/bin/bash

. ./env.sh

mkdir -p $WORKDIR/$OCP_RELEASE

commands=(wget tar)

for cmd in "${commands[@]}"; do
	if command -v  >/dev/null 2>&1; then
		echo "$cmd command is exists."
	else
		echo "$cmd command is not exists!"
		exit 1
	fi
done

# if OCP
if [ "$RELEASE_NAME" == "ocp-release" ]; then
	# download oc, kubectl command
	wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz -O $WORKDIR/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz
	
	# download openshift-install command
	wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_RELEASE/openshift-install-linux-$OCP_RELEASE.tar.gz -O $WORKDIR/$OCP_RELEASE/openshift-install-linux-$OCP_RELEASE.tar.gz

# if okd
elif [ "$RELEASE_NAME" == "okd" ]; then
	# download oc, kubectl command
	wget https://github.com/okd-project/okd/releases/download/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz -O $WORKDIR/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz

	# download openshift-install command
	wget https://github.com/okd-project/okd/releases/download/$OCP_RELEASE/openshift-install-linux-$OCP_RELEASE.tar.gz -O $WORKDIR/$OCP_RELEASE/openshift-install-linux-$OCP_RELEASE.tar.gz
fi

#oc-mirror plug-in
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-4.14/oc-mirror.tar.gz -O $WORKDIR/$OCP_RELEASE/oc-mirror.tar.gz

# Get the current user
current_user=$(whoami)

# Check if the current user is root


# untar tar.gz file
tar xfz $WORKDIR/$OCP_RELEASE/openshift-client-linux-$OCP_RELEASE.tar.gz -C $WORKDIR/$OCP_RELEASE
tar xfz $WORKDIR/$OCP_RELEASE/openshift-install-linux-$OCP_RELEASE.tar.gz -C $WORKDIR/$OCP_RELEASE
tar xfz $WORKDIR/$OCP_RELEASE/oc-mirror.tar.gz -C $WORKDIR/$OCP_RELEASE

# remove README.md
rm -rf $WORKDIR/$OCP_RELEASE/README.md

	if [ "$current_user" != "root" ]; then

	# copy cli to /usr/local/bin
	mkdir -p ~/.local/bin
	cp -av $WORKDIR/$OCP_RELEASE/oc $WORKDIR/$OCP_RELEASE/openshift-install $WORKDIR/$OCP_RELEASE/kubectl $WORKDIR/$OCP_RELEASE/oc-mirror ~/.local/bin


	# butane
	wget https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane -O $WORKDIR/$OCP_RELEASE/butane
	chmod u+x $WORKDIR/$OCP_RELEASE/butane


	chmod u+x ~/.local/bin/oc-mirror

	exit 0

	fi

# copy cli to /usr/local/bin
cp -av $WORKDIR/$OCP_RELEASE/oc $WORKDIR/$OCP_RELEASE/openshift-install $WORKDIR/$OCP_RELEASE/kubectl $WORKDIR/$OCP_RELEASE/oc-mirror /usr/local/bin/


# butane
wget https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane -O $WORKDIR/$OCP_RELEASE/butane
chmod u+x $WORKDIR/$OCP_RELEASE/butane


chmod u+x /usr/local/bin/oc-mirror
