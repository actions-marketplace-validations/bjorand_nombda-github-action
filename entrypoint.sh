#!/bin/sh

set -e

if test -z "$TIMEOUT"
then
  TIMEOUT=60
fi

START=$(date +%s)

if test -z "$TOKEN"
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::token parameter is empty"
  exit 1
fi

if test -z "$URL"
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::url parameter is empty"
  exit 1
fi

if test -z "$HOOK"
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::hook parameter is empty"
  exit 1
fi

if test -z "$ACTION"
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::action parameter is empty"
  exit 1
fi

# Trigger hook and get job id
out=$(curl -H"Auth-token: ${TOKEN}" -XPOST "${URL}/hooks/${HOOK}/${ACTION}" --show-error)
id=$(echo "$out" | jq -r .id)
if test $? -gt 0 || test "$id" == "" || test "$id" == "null"
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::unable to trigger hook $out"
  exit 1
fi

echo "Started hook $HOOK/$ACTION with id $id"

while true;
do
  now=$(date +%s)
  if test "$now" -gt $((START+TIMEOUT))
  then
    echo "::error url=$URL,hook=$HOOK,action=$ACTION::timeout reached"
    exit 1
  fi

  out=$(curl -sH"Auth-Token: ${TOKEN}" "${URL}/hooks/${HOOK}/${ACTION}/${id}" --show-error)
  if test $? -gt 0
  then
    echo "::error url=$URL,hook=$HOOK,action=$ACTION,job_id=$id::no such job id"
    exit 1
  fi
  completed=$(echo "$out" | jq -r .run.completed)
  if test "$completed" == "true"
  then
    exitCode=$(curl -sfH "Auth-Token: ${TOKEN}" "${URL}/hooks/${HOOK}/${ACTION}/$id" | jq -r .run.exit_code)
    curl -sfH "Auth-Token: ${TOKEN}" "${URL}/hooks/${HOOK}/${ACTION}/${id}/log"
    exit "$exitCode"
  fi
  sleep 0.5
done
