#! /bin/bash

# This script will create(remove) veth/host attached to namespace
# and corresponding tap interface.
# Most of the code was copied from a script written by Tohru Kitamura. Thanks!!

if [[ $(id -u) -ne 0 ]] ; then echo "Please run with sudo" ; exit 1 ; fi

set -e

if [ -n "$SUDO_UID" ]; then
    uid=$SUDO_UID
else
    uid=$UID
fi

run () {
    echo "$@"
    "$@" || exit 1
}

silent () {
    "$@" 2> /dev/null || true
}

create_network () {
    echo "create_network"
    # Create network namespaces
    run ip netns add host1
    run ip netns add host2

    # Create veth
    run ip link add veth1 type veth peer name vtap1
    run ip link add veth2 type veth peer name vtap2

    # Connect veth between host1 and host2
    run ip link set veth1 netns host1
    run ip link set veth2 netns host2
    run ip link set dev vtap1 up
    run ip link set dev vtap2 up

    # Set IP address
    run ip netns exec host1 ip addr add 172.20.0.1/24 dev veth1
    run ip netns exec host2 ip addr add 172.20.0.2/24 dev veth2
    run ip netns exec host1 ip addr add 10.0.0.1/32 dev lo
    run ip netns exec host2 ip addr add 10.0.0.2/32 dev lo

    # Link up loopback and veth
    run ip netns exec host1 ip link set veth1 up
    run ip netns exec host1 ifconfig lo up
    run ip netns exec host2 ip link set veth2 up
    run ip netns exec host2 ifconfig lo up

    run ip link set dev vtap1 up
    run ip link set dev vtap2 up
}

destroy_network () {
    echo "destroy_network"
    silent ip netns exec host1 ip link del veth1
    silent ip netns exec host2 ip link del veth2
    silent ip netns del host1
    silent ip netns del host2
}

while getopts "cd" ARGS;
do
    case $ARGS in
    c ) create_network
        exit 1;;
    d ) destroy_network
        exit 1;;
    esac
done
