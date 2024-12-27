#!/bin/bash

TARGET_INTERFACE=eth0
tc qdisc add dev ${TARGET_INTERFACE} clsact

tc filter add dev ${TARGET_INTERFACE} ingress bpf da obj /root/monitor.o sec "tc_tls_dns"
tc filter add dev ${TARGET_INTERFACE} egress bpf da obj /root/monitor.o sec "tc_tls_dns"