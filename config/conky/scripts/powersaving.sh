#!/bin/bash
val=$(cat /sys/module/i915/parameters/enable_psr)
case $val in
    -1) echo "auto" ;;
     0) echo "off" ;;
     1) echo "on (PSR1)" ;;
     2) echo "on (PSR2)" ;;
    *)  echo "unknown:$val" ;;
esac
