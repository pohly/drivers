# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

REGISTRY_NAME = quay.io/k8scsi
IMAGE_VERSION = canary

.PHONY: all flexadapter nfs hostpath iscsi cinder clean hostpath-container

all: flexadapter nfs hostpath iscsi cinder

test:
	go test github.com/kubernetes-csi/drivers/pkg/... -cover
	go vet github.com/kubernetes-csi/drivers/pkg/...
flexadapter: dep
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o _output/flexadapter ./app/flexadapter
nfs: dep
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o _output/nfsplugin ./app/nfsplugin
hostpath: dep
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o _output/hostpathplugin ./app/hostpathplugin
livenessprobe: dep
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o _output/livenessprobe ./app/livenessprobe/cmd

hostpath-container: hostpath
	docker build -t $(REGISTRY_NAME)/hostpathplugin:$(IMAGE_VERSION) -f ./app/hostpathplugin/Dockerfile .
iscsi: dep
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o _output/iscsiplugin ./app/iscsiplugin
cinder: dep
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o _output/cinderplugin ./app/cinderplugin
clean:
	go clean -r -x
	-rm -rf _output

# This ensures that "dep ensure" gets run after an initial checkout
# or after updating the repo such that the dependency list changes.
# To update Gopkg.lock after after making code changes that modify
# dependencies, developers still need to run "dep ensure" manually.
dep: vendor/.stamp
vendor/.stamp: Gopkg.toml Gopkg.lock
	dep ensure -vendor-only
	touch $@
