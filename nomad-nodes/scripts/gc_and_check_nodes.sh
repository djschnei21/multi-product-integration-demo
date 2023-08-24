#!/bin/bash

while true; do
  # Trigger Nomad System GC
  curl -X PUT -H "X-Nomad-Token: $NOMAD_TOKEN" $NOMAD_SERVER_URL/v1/system/gc

  # Check if all nodes have been removed
  nodes=$(curl -H "X-Nomad-Token: $NOMAD_TOKEN" $NOMAD_SERVER_URL/v1/nodes | jq 'length')
  if [ "$nodes" -eq "0" ]; then
    break
  fi

  # Wait for 10 seconds
  sleep 10
done
