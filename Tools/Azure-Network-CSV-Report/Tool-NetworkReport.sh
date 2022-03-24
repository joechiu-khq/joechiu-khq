#!/bin/bash

clear -x

tmpfile=/tmp/tempfile
jsonfile=/tmp/jsonfile
nsgfile="/tmp/NSG-$1-rule-list"
csvpath="./CSV"

kv() {
  echo $i | jq -r $1
}

csv() {
  src=$1
  rep=$2
  cat $src | perl -nle '/---/&&next; print join ",", split /\s+/' > $csvpath/$rep.csv
}

shout() {
  echo $yc"$1"$rs
  run=$($1 > $tmpfile)
  res=$(cat $tmpfile)
  rep=$2
  if [ -z "$res" ];
  then
    echo $cc"Not Available"$rs
  else
    cat $tmpfile
    cat $tmpfile > "$csvpath/$rep"
    csv $tmpfile $rep
  fi
  echo
}

shownet() {
  opt=$1
  nn=1
  jq -c '.[]' $jsonfile | while read -r i
  do
    rg=$(kv '.rg')
    vnet=$(kv '.vnet')
    cmd="az network vnet $opt list -g $rg --vnet-name $vnet -o table"
    shout "$cmd" "$2-$nn"
    ((nn=$nn+1))
  done 
}

nsgrule() {
  msg=$1
  jq -c '.[]' $nsgfile | while read -r i
  do
    rg=$(kv '.rg')
    nsg=$(kv '.name')
    cmd="az network nsg rule list --nsg-name $nsg -g $rg -o table"
    shout "$cmd" "$msg"
  done 
}

[ -z $1 ] && { echo "Error: subscription not found"; exit; }
[ -e "$csvpath/$1" ] && rm -rf $csvpath/$1
mkdir -p $csvpath/$1 
csvpath="$csvpath/$1"

az account set --subscription "$1"

echo $bo$cc"Subscription $1"$rs

# Running for CSV files
shout "az group list -o table" rg
shout "az network vnet list -o table" vnet
shout "az network nat gateway list -o table" nat
shout "az network public-ip list -o table" ip
az network vnet list | jq '[.[] | {"vnet":.name,"rg":.resourceGroup}]' > $jsonfile
shownet subnet subnet
shownet peering peering
# az network route-table route list --route-table # do we have route tables?
shout "az network nsg list -o table" nsg
echo $yc"NSG Rules for $1$rs"
az network nsg list | jq '[ .[] | {"name":.name,"rg":.resourceGroup} ]' > $nsgfile
nsgrule "nsgrules"
shout "az network nat gateway list -o table" nat


