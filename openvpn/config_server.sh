#!/bin/bash
# Name: config_server.sh
# Owner: Saurav Mitra
# Description: ConfigureOpenVPN Access Server

admin_pw=${VPN_ADMIN_PASSWORD}
pushd /usr/local/openvpn_as/scripts
./sacli --key "vpn.server.daemon.enable" --value "false" ConfigPut
./sacli --key "cs.tls_version_min" --value "1.2" ConfigPut
./sacli --key "vpn.server.tls_version_min" --value "1.2" ConfigPut
/usr/local/openvpn_as/scripts/ovpnpasswd -u ${VPN_ADMIN_USER} -p ${VPN_ADMIN_PASSWORD}
./sacli start
popd
