#!/usr/bin/python

import os
os.system('touch /etc/openshift-sdn/used.log')
used_octet_file = open('/etc/openshift-sdn/used.log', "r")
used_indices = []
raw_indices = used_octet_file.read().split('\n')
for raw_index in raw_indices:
	if raw_index.strip()!='':
		used_indices.append(int(raw_index.strip()))

used_octet_file.close()
config = open('/etc/openshift-sdn/config.env')
cmap = {}
for e in config.readlines():
        ekey,eval = e.split('=')
        cmap[ekey] = eval.strip()
addr = cmap['OPENSHIFT_SDN_TAP1_ADDR'].split('.')

max_index = 2
if len(used_indices)==0:
        max_index = int(addr[3])+1
else:
	max_index = max(used_indices)
new_addr = ".".join(addr[0:3]) + "." + str(int(max_index)+1)

used_octet_file = open('/etc/openshift-sdn/used.log', "a")
used_octet_file.write(str(int(max_index)+1))
used_octet_file.write("\n")
used_octet_file.close()
print new_addr
