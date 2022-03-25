#!/bin/bash

clear -x
. Functions

subs=( "Dev2" "Stage2" "US2" "CA2" "INTU2" )
if [ -z $1 ]
then
  read -p "Choose the subscription ($(join ', ' ${subs[*]}) or Enter to quit): " sub
else
  sub=$1
fi

if [[ ! " ${subs[*]} " =~ " ${sub} " ]]; then
  if [ -z $sub ]; then
    echo "Quit"
  else
    echo "Invalid subscription: $sub"
  fi
  exit 1
fi


[ -z $sub ] && { echo "Error: subscript not found"; exit; }

repo=CSV
[ -d $repo ] || mkdir -p $repo
tmp="/tmp/$sub-nsg-list"
csv="$repo/$sub-report.csv"
echo '' | tee $csv

az account set --subscription $sub

az network nsg list | jq '[ .[] | {"name":.name,"rg":.resourceGroup} ]' > $tmp

body='["Name","Resource Group","Source Port","Source Address","Access","Protocol","Direction","Destination Port","Destination Address"],(.[] | [.name,.resourceGroup,.sourcePortRange,.sourceAddressPrefix,.access,.protocol,.direction,.destinationPortRange,.destinationAddressPrefix]) | @csv';

ce "OUTGOING CONNECTIONS / IMCOMING CONNECTIONS"
jq -c '.[]' $tmp | while read i; do
  rg=$(kv '.rg')
  nsg=$(kv '.name')
  echo "NSG: $nsg,RG: $rg"
  az network nsg rule list --nsg-name $nsg -g $rg | jq -r "$body"
  echo
done | tee -a $csv

ce 
ce "PORTs"

tmp="/tmp/$sub-port-list"
az network application-gateway list | jq '[ .[] | {name:.name,rg:.resourceGroup} ]' > $tmp
body='["Application","Resource Group","Port"],(.[] | [(if .hostName != null then .hostName else .name end),.resourceGroup,(if .protocol == "Https" then "443" else "80" end)]) | @csv'
jq -c '.[]' $tmp | while read i
do
  rg=$(kv '.rg')
  gw=$(kv '.name')
  az network application-gateway http-listener list --gateway-name $gw -g $rg | jq -r "$body"
done | tee -a $csv
body='.[].backendHttpSettingsCollection[] | [.name,.resourceGroup,.port] | @csv';
az network application-gateway list | jq -r "$body" | tee -a $csv

ce 
ce "IPs"

tmp="/tmp/$sub-dns-list"
az network dns zone list | jq '[.[] | {name:.name,rg:.resourceGroup}]' > $tmp

jq -c '.[]' $tmp | while read i
do
  rg=$(kv '.rg')
  zone=$(kv '.name')
  file=/tmp/$sub-dns-$zone-file
  tmp=/tmp/dns-tmp
  json=/tmp/json-$zone
  rm -rf $json
  echo "RG: $rg,Zone: $zone"
  echo 'Host,IP Address,RG,Zone'
  az network dns record-set list -g $rg -z $zone | jq '.[].fqdn' | sed 's/"//g' > $file
  while read -r i; do echo "---- $i,"'%s'",$rg,$zone"; dig +short $i; done < $file > $tmp
  cat $tmp | perl -nle 'if (/^-+ (.*)/ig) {$t=$1} elsif (/^((\d+(\.|$)){4})/) {printf "$t\n",$1}' | sort -u
  while read -r i; do echo "---- $i"; dig +short $i; done < $file > $tmp
  cat $tmp | perl -nle 'if (/^-+ (.*)/ig) {$u=$1} elsif (/^((\d+(\.|$)){4})/) {print qq({"ip":"$1","url":"$u"})}' | jq -r . | jq -s '.' > $json

  echo
  echo "URLs"
  echo '"URL","IP Address","Port"'
  jq -c '.[]' $json | while read i 
  do
    ip=$(kv '.ip')
    url=$(kv '.url')
    res=$(/usr/bin/nc -w3 -zv $url 443 2>&1)
    if [[ "$res" =~ succeeded ]];
    then
      echo "https://$url,$ip,\"80,443\""
    fi
  done 
  echo

done | tee -a $csv



