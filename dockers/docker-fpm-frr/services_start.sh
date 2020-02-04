#!/usr/bin/env bash

mkdir -p /etc/frr

CONFIG_TYPE=`sonic-cfggen -d -v 'DEVICE_METADATA["localhost"]["docker_routing_config_mode"]'`

if [ "$CONFIG_TYPE" == "separated" ]; then
    sonic-cfggen -d -y /etc/sonic/deployment_id_asn_map.yml -t /usr/share/sonic/templates/bgpd.conf.j2 > /etc/frr/bgpd.conf
    sonic-cfggen -d -t /usr/share/sonic/templates/zebra.conf.j2 > /etc/frr/zebra.conf
    sonic-cfggen -d -t /usr/share/sonic/templates/staticd.conf.j2 > /etc/frr/staticd.conf
    echo "no service integrated-vtysh-config" > /etc/frr/vtysh.conf
    rm -f /etc/frr/frr.conf
elif [ "$CONFIG_TYPE" == "unified" ]; then
    sonic-cfggen -d -y /etc/sonic/deployment_id_asn_map.yml -t /usr/share/sonic/templates/frr.conf.j2 >/etc/frr/frr.conf
    echo "service integrated-vtysh-config" > /etc/frr/vtysh.conf
    rm -f /etc/frr/bgpd.conf /etc/frr/zebra.conf /etc/frr/staticd.conf
elif [ "$CONFIG_TYPE" == "split" ] || [ -z "$CONFIG_TYPE" ]; then
    echo "service integrated-vtysh-config" > /etc/frr/vtysh.conf
    rm -f /etc/frr/bgpd.conf /etc/frr/zebra.conf /etc/frr/staticd.conf
fi

sonic-cfggen -d -t /usr/share/sonic/templates/isolate.j2 > /usr/sbin/bgp-isolate
chown root:root /usr/sbin/bgp-isolate
chmod 0755 /usr/sbin/bgp-isolate

sonic-cfggen -d -t /usr/share/sonic/templates/unisolate.j2 > /usr/sbin/bgp-unisolate
chown root:root /usr/sbin/bgp-unisolate
chmod 0755 /usr/sbin/bgp-unisolate

mkdir -p /var/sonic
echo "# Config files managed by sonic-config-engine" > /var/sonic/config_status

rm -f /var/run/rsyslogd.pid

service rsyslog start
service frr start

/usr/bin/supervisord
