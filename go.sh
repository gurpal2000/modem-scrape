#!/bin/bash

set -e

USER="admin"
PASS="xxxxxxxxxx"
MODEM_IP="http://192.168.1.1"

# http://localhost:9091/metrics/job/modem_stats/instance/192.168.10.20
TARGET=$1

NOW=`date +%Y-%m-%d.%H:%M:%S`

function getStats() {
  local COOKIE=`echo -n ${USER}:${PASS} | base64`
  echo "`curl --silent -d $'[WAN_DSL_INTF_CFG#1,0,0,0,0,0#0,0,0,0,0,0]0,0\r\n' --referer "$MODEM_IP/" --header "Cookie: Authorization=Basic $COOKIE" --header "Content-Type: text/plain; charset=UTF-8" "$MODEM_IP/cgi?1&5"`"
}

function getStatVal() {
  echo "$1" | grep "$2" | cut -d'=' -f2
}

while true
do
  RES="$(getStats)"

  while [ -z "$RES##*Internal Server Error*}"  ]
  do
    echo "$NOW: contains error"
    sleep 1s
    RES="$(getStats)"
  done

  if [[ "$RES" == *"Internal Server Error"* ]]; then
    echo "$NOW: contains error2"
    sleep 1s
    RES="$(getStats)"
  else
    UCR=`getStatVal "$RES" "upstreamCurrRate"`
    DCR=`getStatVal "$RES" "downstreamCurrRate"`
    UMR=`getStatVal "$RES" "upstreamMaxRate"`
    DMR=`getStatVal "$RES" "downstreamMaxRate"`
    UNM=`getStatVal "$RES" "upstreamNoiseMargin"`
    DNM=`getStatVal "$RES" "downstreamNoiseMargin"`
    UA=`getStatVal "$RES" "upstreamAttenuation"`
    DA=`getStatVal "$RES" "downstreamAttenuation"`
    UP=`getStatVal "$RES" "upstreamPower"`
    DP=`getStatVal "$RES" "downstreamPower"`

    jq -n \
      --arg upstreamCurrRate "$UCR" \
      --arg downstreamCurrRate "$DCR" \
      --arg upstreamMaxRate "$UMR" \
      --arg downstreamMaxRate "$DMR" \
      --arg upstreamNoiseMargin "$UNM" \
      --arg downstreamNoiseMargin "$DNM" \
      --arg upstreamAttenuation "$UA" \
      --arg downstreamAttenuation "$DA" \
      --arg upstreamPower "$UP" \
      --arg downstreamPower "$DP" \
      '$ARGS.named'

    cat << EOF | curl --data-binary @- http://vmapp:9091/metrics/job/modem_stats/instance/192.168.10.17
    # TYPE modem_upstream_curr_rate gauge
    modem_upstream_curr_rate $UCR
    # TYPE modem_downstream_curr_rate gauge
    modem_downstream_curr_rate $DCR
    # TYPE modem_upstream_max_rate gauge
    modem_upstream_max_rate $UMR
    # TYPE modem_downstream_max_rate gauge
    modem_downstream_max_rate $DMR
    # TYPE modem_upstream_noise_margin gauge
    modem_upstream_noise_margin $UNM
    # TYPE modem_downstream_noise_margin gauge
    modem_downstream_noise_margin $DNM
    # TYPE modem_upstream_attenuation gauge
    modem_upstream_attenuation $UA
    # TYPE modem_downstream_attenuation gauge
    modem_downstream_attenuation $DA
    # TYPE modem_upstream_power gauge
    modem_upstream_power $UP
    # TYPE modem_downstream_power gauge
    modem_downstream_power $DP
EOF
  fi

  sleep 15
done
