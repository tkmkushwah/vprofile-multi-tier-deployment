#!/bin/bash

echo "==> Starting VProfile Multi-VM Setup on Mac..."

./setup_db.sh
./setup_mc.sh
./setup_rmq.sh
./setup_app.sh
./setup_web.sh

echo "==> All VMs provisioned successfully!"
