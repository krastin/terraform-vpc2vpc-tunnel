#!/usr/bin/env bash

## Setup OpenVPN

# initial openvpn setup
ovpn-init --batch --host='$1' --ec2 --no_reroute_gw --no_reroute_dns

# route traffic instead of NATting
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_access" --value "route" ConfigPut

# allow inter-client routing
/usr/local/openvpn_as/scripts/sacli --key "vpn.client.routing.inter_client" --value "true" ConfigPut

# allow routing of private nets in HQ to clients
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.allow_private_nets_to_clients" --value "true" ConfigPut

# allow clients to access IP of VPN concentrator
/usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.gateway_access" --value "true" ConfigPut

## Setup Users

# add site2 user
/usr/local/openvpn_as/scripts/sacli --user 'site2' --key "type" --value "user_connect" UserPropPut

# set password for site2 user
/usr/local/openvpn_as/scripts/sacli --user 'site2' --new_pass 'site2site' SetLocalPassword

# set autologin property to enabled for site2 user (used for non-user machine logins like in a site2site setup)
/usr/local/openvpn_as/scripts/sacli --user 'site2' --key "prop_autologin" --value "true" UserPropPut

# restart openvpn daemon
systemctl restart openvpnas.service
