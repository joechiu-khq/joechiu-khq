# Azure-Network-CSV-Report 
Generate CSV reports by azure cli commands.

## Prerequisites
* Ubuntu / Linux - 18.04LTS or 20.04
* bash
* python 3.8.10
* azure-cli 2.33.1
* jq 1.6

## Installation
* Python3 and pip3
  * sudo apt install python3 python3-pip
* azure-cli 2.33.1
  * sudo pip3 install azure-cli
  * pip3 install azure-cli --user
* jq
  * sudo apt install jq

## Run
* ./Tool-NetworkReport.sh env
  * eq. ./Tool-NetworkReport.sh Stage2

## CSV Reports
CSV reports will be generated into CSV/env and findable as:

<pre>
CSV
└── Stage2
    ├── ip
    ├── ip.csv
    ├── nsg
    ├── nsg.csv
    ├── nsgrules
    ├── nsgrules.csv
    ├── peering-1
    ├── peering-1.csv
    ├── rg
    ├── rg.csv
    ├── subnet-1
    ├── subnet-1.csv
    ├── vnet
    └── vnet.csv
</pre>
