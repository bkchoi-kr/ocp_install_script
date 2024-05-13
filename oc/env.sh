#!/bin/bash

## okd
# WORKING Directory
WORKDIR=$(pwd)
# OCP Release
OCP_RELEASE=4.14.0-0.okd-2024-01-06-084517
#OCP_RELEASE=4.12.0-0.okd-2023-04-16-041331
# local container registry
LOCAL_REGISTRY='bastion.okd4.kcb.home:5000'
# local repository for OCP Cluster Operator container image
LOCAL_REPOSITORY='okd4/release'
# Product repository
PRODUCT_REPO='openshift'
# local and ocp mirror registry pull secret
LOCAL_SECRET_JSON='./pull-secret-private.json'
# release name
RELEASE_NAME="okd"
# architecture
ARCHITECTURE=x86_64
# path to download
REMOVABLE_MEDIA_PATH=$WORKDIR/$OCP_RELEASE


#### ocp
## WORKING Directory
#WORKDIR=$(pwd)
## OCP Release
#OCP_RELEASE=4.12.47
## local container registry
#LOCAL_REGISTRY='bastion.ocp4.sye.home:5000'
## local repository for OCP Cluster Operator container image
#LOCAL_REPOSITORY='ocp4/release'
## Product repository
#PRODUCT_REPO='openshift-release-dev'
## local and ocp mirror registry pull secret
#LOCAL_SECRET_JSON='/DATA/oc/pull-secret-bundle.json'
## release name
#RELEASE_NAME="ocp-release"
## architecture
#ARCHITECTURE=x86_64
## local path to download
#REMOVABLE_MEDIA_PATH=$WORKDIR/$OCP_RELEASE
