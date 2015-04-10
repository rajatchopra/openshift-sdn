set -ex

source /etc/openshift-sdn/config.env
network_ip=${OPENSHIFT_SDN_GLOBAL_SUBNET}
tap_ip=${OPENSHIFT_SDN_TAP1_ADDR}
new_ip=$(gen_addr.py)

net_container=$(docker run -d kubernetes/pause)
echo $net_container
pid=$(docker inspect --format "{{.State.Pid}}" ${net_container})
ipaddr=$(docker inspect --format "{{.NetworkSettings.IPAddress}}" ${net_container})
ipaddr_sub=$(docker inspect --format "{{.NetworkSettings.IPPrefixLen}}" ${net_container})
veth_host=$(jq .network_state.veth_host /var/lib/docker/execdriver/native/${net_container}/state.json | tr -d '"')
echo $veth_host
echo $pid
echo $ipaddr/$ipaddr_sub

brctl delif docker0 $veth_host
ovs-vsctl add-port br0 ${veth_host} 

del_ip_cmd="ip addr del $ipaddr/$ipaddr_sub dev eth0"
nsenter -n -t $pid -- $del_ip_cmd

add_ip_cmd="ip addr add $new_ip/16 dev eth0"
nsenter -n -t $pid -- $add_ip_cmd

add_default_cmd="ip route add default via $tap_ip"
nsenter -n -t $pid -- $add_default_cmd

docker_args=$@
#docker run --net=container:${net_container} $docker_args
cidfile=/tmp/osdn-cid_$RANDOM
docker run --cidfile $cidfile --net=container:${net_container} $docker_args
cid=$(cat $cidfile)
docker wait $cid || true
docker rm -f $cid || true
docker rm -f $net_container
ovs-vsctl del-port $veth_host
