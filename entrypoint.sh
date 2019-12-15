#!/bin/sh

# set -e

if test -z $TOKEN
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::token parameter is empty"
  exit 1
fi

if test -z $URL
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::url parameter is empty"
  exit 1
fi

if test -z $HOOK
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::hook parameter is empty"
  exit 1
fi

if test -z $ACTION
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::action parameter is empty"
  exit 1
fi

# Capture output
output=$( sh -c "curl -f -s -H\"Auth-token: ${TOKEN}\" -XPOST ${URL}/hooks/${HOOK}/${ACTION}")
ret=$?
if test $ret -gt 0
then
  echo "::error url=$URL,hook=$HOOK,action=$ACTION::unable to trigger hook: $output"
  exit $ret
fi
echo $output
