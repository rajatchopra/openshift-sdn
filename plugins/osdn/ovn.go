
package osdn

import (
	utilexec "k8s.io/kubernetes/pkg/util/exec"
)

func (oc *OvsController) OVNStartMaster() error {
	// Start the OVN master and the pod watchers
	_, err := utilexec.New().Command("openshift-ovn-master-setup", oc.localIP).CombinedOutput()
	return err
}

func (oc *OvsController) OVNStartNode() error {
	// Start the OVN node
	_, err := utilexec.New().Command("openshift-ovn-node-setup", oc.localIP).CombinedOutput()
	return err
}
