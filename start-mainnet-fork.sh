#!/bin/bash

GAS_LIMIT=10000000

source .env

npx ganache-cli \
	-i 1 \
	-l $GAS_LIMIT \
	-f https://mainnet.infura.io/v3/$INFURA_PROJECT_ID \
	--account $PRIVATE_KEY,100000000000000000000
