#!/bin/bash 

SETNAME="evil_ips"
IPTABLES_CHAIN=INPUT
IPTABLES_RULE_NUM=1

usage() {

  cat <<EOF
   block_list_ips.sh [<options] <URL>  

   Options:

      --ip_set_name  <name>      Name of the ip set (default evil_ips)
      --iptables_rule_num <num>   Number of the rule of the iptables chain (default 1)
      --iptables_chain  <name>    Name of the iptables chain (default INPUT)
      --help                     Print this help text
      
EOF
}

while [ $# -gt 1 ]; do
   case "$1" in
      --ip_set_name)
         if [ $# -lt 2 ]; then
            echo "Missing <name> for --ip_set_name option" >&2
            exit 1
         fi
         shift
         SETNAME=$1
         shift
         ;;
      --iptables_rule_name)
         if [ $# -lt 2 ]; then
            echo "Missing <num> for --iptables_rule_name option" >&2
            exit 1
         fi
         shift
         IPTABLES_RULE_NUM=$1
         shift
         ;;
      --iptables_chain)
         if [ $# -lt 2 ]; then
            echo "Missing <name> for --iptables_chain option" >&2
            exit 1
         fi
         shift
         IPTABLES_CHAIN=$1
         shift
         ;;
      --help)
         usage
         exit 0
         ;;
      *)
      echo "Unknown option $1. Use --help for help" >&2
      exit 1
   esac
done

if [ $# -lt 1 ]; then
   echo "Missung <URL>" >&2
   usage
   exit 1
fi

if [ $1 = "--help" ]; then
   usage
   exit 1
fi

URL=$1
evil_ips=$(curl --compressed -f $URL 2>/dev/null) 
if [ $? -ne 0 ]; then
   echo "Error: Could not download $URL" >&2
   exit 1
fi
if [ -z "$evil_ips" ]; then
   echo "No IP addressed downloaded from $URL"
   exit 0
fi
logger -t "evil_ip_block" "Adding IPs to be blocked."
ipset list $SETNAME &>/dev/null # check if the IP set exists
if [ $? -ne 0 ]; then
   ipset create $SETNAME hash:ip family inet # create new IP set
   iptables -I INPUT 1 -m set --match-set $SETNAME src -j DROP
else
   ipset flush $SETNAME # clear existing IP set
fi
# populate the new or existing empty IP set
for i in $evil_ips ; do 

   if [[ $i =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      ipset -exist add $SETNAME $i
   fi
done

