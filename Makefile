# Old-skool build tools.
#
# Targets (see each target for more information):
#   all: Build code.
#   build: Build code.
#   clean: Clean up.

OUT_DIR = _output
OUT_PKG_DIR = Godeps/_workspace/pkg

export GOFLAGS

# Build code.
#
# Args:
#   WHAT: Directory names to build.  If any of these directories has a 'main'
#     package, the build will produce executable files under $(OUT_DIR)/local/go/bin.
#     If not specified, "everything" will be built.
#   GOFLAGS: Extra flags to pass to 'go' when building.
#
# Example:
#   make
#   make all
#   make all WHAT=cmd/kubelet GOFLAGS=-v
all build:
	hack/build.sh $(WHAT)
.PHONY: all build

install:
	rm -f /usr/bin/openshift-sdn
	rm -f /usr/bin/openshift-sdn-simple-setup-node.sh
	cp -f $(OUT_DIR)/local/go/bin/openshift-sdn /usr/bin/
	cp -f $(OUT_DIR)/local/go/bin/openshift-sdn-simple-setup-node.sh /usr/bin/
	cp -f $(OUT_DIR)/local/go/bin/osdn-docker-run.sh /usr/bin/
	cp -f $(OUT_DIR)/local/go/bin/gen_addr.py /usr/bin/
	cp -f $(OUT_DIR)/local/go/bin/jq /usr/bin/

# Remove all build artifacts.
#
# Example:
#   make clean
clean:
	rm -rf $(OUT_DIR) $(OUT_PKG_DIR)
.PHONY: clean

