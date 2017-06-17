# MEMO: IS-IS Testing

Tested using Ubuntu 16.04

## Install and configure quagga

Reference: https://wiki.ubuntu.com/JonathanFerguson/Quagga

```
sudo apt-get install quagga
> Setting up quagga (0.99.24.1-2ubuntu1.2)

# HACK:
sudo chown root:root /var/log/quagga

# Create configuration file(s)
# For automatic startup, store isisd.conf, zebra.conf under /etc/quagga/
# Below example is when using namespace.
sudo vi isisd-1.conf
sudo vi isisd-2.conf
sudo vi zebra-1.conf
sudo vi zebra-2.conf

# Change the owner and the mode of the configuration files:
# chmod to 640 if you are actually running in service deployment
sudo chown quagga:quagga isisd-1.conf && sudo chmod 644 isisd-1.conf  
sudo chown quagga:quagga isisd-2.conf && sudo chmod 644 isisd-2.conf  
sudo chown quagga:quagga zebra-1.conf && sudo chmod 644 zebra-1.conf
sudo chown quagga:quagga zebra-2.conf && sudo chmod 644 zebra-2.conf

# Run zebrad and isisd in namespace
export PATH=/usr/lib/quagga:$PATH
sudo -s
ip netns exec host1 zebra -d -f ./zebra-1.conf -u root -i /var/run/zebra-1.pid -z /var/run/host1.vty
ip netns exec host2 zebra -d -f ./zebra-2.conf -u root -i /var/run/zebra-2.pid -z /var/run/host2.vty
ip netns exec host1 isisd -d -f ./isisd-1.conf -u root -i /var/run/isisd-1.pid -z /var/run/host1.vty
ip netns exec host2 isisd -d -f ./isisd-2.conf -u root -i /var/run/isisd-2.pid -z /var/run/host2.vty

# Create Bridge to connect tap of host1/host2
sudo ./namespace-hosts.sh
sudo -s
ip link add br1 type bridge
ip link set br1 up
ip link set dev vtap1 master br1
ip link set dev vtap2 master br1
```

## Confirm Zebra and isisd are running

```
# 2601:zebra, 2608: isisd
sudo -s
ip netns exec host1 telnet localhost 2601
ip netns exec host2 telnet localhost 2601
ip netns exec host1 telnet localhost 2608
ip netns exec host2 telnet localhost 2608
```

## LOGS

```
> Before connecting bridge
# ip netns exec host1 telnet localhost 2601
Hello, this is Quagga (version 0.99.24.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.
User Access Verification
Password:
Zebra-1> show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, P - PIM, A - Babel,
       > - selected route, * - FIB route

C>* 10.0.0.1/32 is directly connected, lo
C>* 127.0.0.0/8 is directly connected, lo
C>* 172.20.0.0/24 is directly connected, veth1

Zebra-2> show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, P - PIM, A - Babel,
       > - selected route, * - FIB route

C>* 10.0.0.2/32 is directly connected, lo
C>* 127.0.0.0/8 is directly connected, lo
C>* 172.20.0.0/24 is directly connected, veth2

> After connecting vtap via bridge

Zebra-1> show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, P - PIM, A - Babel,
       > - selected route, * - FIB route

C>* 10.0.0.1/32 is directly connected, lo
I>* 10.0.0.2/32 [115/20] via 172.20.0.2, veth1, 00:14:14
C>* 127.0.0.0/8 is directly connected, lo
I   172.20.0.0/24 [115/20] via 172.20.0.2 inactive, 00:14:14
C>* 172.20.0.0/24 is directly connected, veth1

Zebra-2> show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, P - PIM, A - Babel,
       > - selected route, * - FIB route

I>* 10.0.0.1/32 [115/20] via 172.20.0.1, veth2, 00:14:22
C>* 10.0.0.2/32 is directly connected, lo
C>* 127.0.0.0/8 is directly connected, lo
I   172.20.0.0/24 [115/20] via 172.20.0.1 inactive, 00:14:22
C>* 172.20.0.0/24 is directly connected, veth2

lab-isis-1> show isis neighbor
Area 0:
  System Id           Interface   L  State        Holdtime SNPA
  lab-isis-2          veth1       1  Up           29       da0e.6193.e212
  lab-isis-2          veth1       2  Up           29       da0e.6193.e212

lab-isis-2> show isis neighbor
Area 0:
  System Id           Interface   L  State        Holdtime SNPA
  lab-isis-1          veth2       1  Up           28       0687.0775.a390
  lab-isis-1          veth2       2  Up           28       0687.0775.a390

lab-isis-1> show isis database
Area 0:
IS-IS Level-1 link-state database:
LSP ID                  PduLen  SeqNumber   Chksum  Holdtime  ATT/P/OL
lab-isis-1.00-00     *     93   0x00000005  0x08ac     786    0/0/0
lab-isis-2.00-00           93   0x00000005  0x8d22     806    0/0/0
lab-isis-2.02-00           51   0x00000001  0x873d     759    0/0/0
    3 LSPs

IS-IS Level-2 link-state database:
LSP ID                  PduLen  SeqNumber   Chksum  Holdtime  ATT/P/OL
lab-isis-1.00-00     *     93   0x00000005  0x0aa8     791    0/0/0
lab-isis-2.00-00           93   0x00000005  0x8f1e     789    0/0/0
lab-isis-2.02-00           51   0x00000001  0x8939     765    0/0/0
    3 LSPs

lab-isis-2> show isis database
Area 0:
IS-IS Level-1 link-state database:
LSP ID                  PduLen  SeqNumber   Chksum  Holdtime  ATT/P/OL
lab-isis-1.00-00           93   0x00000005  0x08ac     762    0/0/0
lab-isis-2.00-00     *     93   0x00000005  0x8d22     782    0/0/0
lab-isis-2.02-00     *     51   0x00000001  0x873d     735    0/0/0
    3 LSPs

IS-IS Level-2 link-state database:
LSP ID                  PduLen  SeqNumber   Chksum  Holdtime  ATT/P/OL
lab-isis-1.00-00           93   0x00000005  0x0aa8     767    0/0/0
lab-isis-2.00-00     *     93   0x00000005  0x8f1e     765    0/0/0
lab-isis-2.02-00     *     51   0x00000001  0x8939     741    0/0/0
    3 LSPs
```

