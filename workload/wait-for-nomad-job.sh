#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <job-id> [<nomad-addr>] [<nomad-token>]"
  exit 1
fi

JOB_ID="$1"
NOMAD_ADDR="${2}"
NOMAD_TOKEN="${3}"

until [ "$(curl -s --fail -H "X-Nomad-Token: ${NOMAD_TOKEN}" "${NOMAD_ADDR}/v1/job/${JOB_ID}/allocations" | jq -r '.[].ClientStatus' | grep -c "running")" -gt 0 ]; do
  echo "Waiting for job ${JOB_ID} to become healthy..."
  sleep 5
done

echo "Job ${JOB_ID} is healthy."
