#!/bin/bash -ue

# Run geth
nohup /usr/local/bin/geth-entry.sh &>/dev/null &

# Initialize database
service postgresql restart

zksync db-setup

# Deploy contracts (they must be already compiled, as we mounted prepared directory)
zksync deploy-erc20 dev
# `deploy-contracts` command from makefile triggers contracts rebuild which we don't want.
pushd $ZKSYNC_HOME > /dev/null
f deploy-contracts.sh
popd > /dev/null

# Run server genesis
zksync genesis

# Ensure that all the required binaries are compiled
pushd $ZKSYNC_HOME > /dev/null
f cargo build --bin zksync_server --release
f cargo build --bin dummy_prover --release
f cargo build --bin dev-ticker-server --release
popd > /dev/null

echo "Launching dev-ticker-server..."
nohup f $ZKSYNC_HOME/target/release/dev-ticker-server &>/dev/null &
sleep 1

echo "Launching server..."
nohup f $ZKSYNC_HOME/target/release/zksync_server &>$ZKSYNC_HOME/server.log &
sleep 1

echo "Launching dummy-prover..."
nohup f $ZKSYNC_HOME/target/release/dummy_prover "dummy-prover-instance" &>$ZKSYNC_HOME/dummy_prover.log &

# Wait for server to start
sleep 10

echo "Done!"
