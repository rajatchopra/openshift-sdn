set -ex

source /etc/openshift-sdn/config.env
network_ip=${OPENSHIFT_SDN_GLOBAL_SUBNET}
tap_ip=${OPENSHIFT_SDN_TAP1_ADDR}
new_ip=$(gen_addr.py)

net_container=$(docker run --net=none -d kubernetes/pause)
pid=$(docker inspect --format "{{.State.Pid}}" ${net_container})
iportname=cont${pid}

ovs-vsctl add-port br0 ${iportname} -- set Interface ${iportname} type=internal

ovs_port=$(ovs-ofctl -O OpenFlow13 dump-ports-desc br0  | grep ${iportname} | cut -d "(" -f 1 | tr -d ' ')
ovs-ofctl -O OpenFlow13 add-flow br0 "table=0,cookie=0x${ovs_port},priority=100,ip,nw_dst=${new_ip},actions=output:${ovs_port}"
ovs-ofctl -O OpenFlow13 add-flow br0 "table=0,cookie=0x${ovs_port},priority=100,arp,nw_dst=${new_ip},actions=output:${ovs_port}"

mkdir -p /var/run/netns
ln -s /proc/$pid/ns/net /var/run/netns/$pid
ip link set ${iportname} netns $pid
ip netns exec $pid ip link set dev ${iportname} name eth0
ip netns exec $pid ip link set dev eth0 up
ip netns exec $pid ip addr add $new_ip/16 dev eth0
ip netns exec $pid ip route add default via $tap_ip
ip netns exec $pid ip link set eth0 up


docker_args=$@
#docker run --net=container:${net_container} $docker_args
cidfile=/tmp/osdn-cid_$RANDOM
docker run --cidfile $cidfile --net=container:${net_container} $docker_args
cid=$(cat $cidfile)
docker wait $cid || true
docker rm -f $cid || true
ip netns exec $pid ip link set dev eth0 down
ip netns exec $pid ip link set dev eth0 name ${iportname}
ovs-vsctl del-port $iportname
docker rm -f $net_container
rm -f /var/run/netns/$pid
ovs-ofctl -O OpenFlow13 del-flows br0 "table=0,cookie=0x${ovs_port}/0xffffffff"
