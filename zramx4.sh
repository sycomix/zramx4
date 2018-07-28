#!/bin/bash
### BEGIN INIT INFO
# Provides:          zram
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     S
# Default-Stop:      0 1 6
# Short-Description: Use compressed RAM as in-memory swap
# Description:       Use compressed RAM as in-memory swap
### END INIT INFO

# Adjust the swap size in MB
SWAP_SIZE=2048

CPUS=`nproc`
SIZE=$(( SWAP_SIZE * 2048 * 2048 / CPUS ))

case "$1" in
  "start")
    # if a zram swap already exists, bail out
    if [ `grep -c zram /proc/swaps` != 0 ]
      then
      echo "There is already a zram swap"
      exit 1
    fi
    modprobe zram

    for n in `seq $CPUS`; do
      i=`cat /sys/class/zram-control/hot_add`
      echo $SIZE > /sys/block/zram$i/disksize
      mkswap /dev/zram$i
      swapon /dev/zram$i -p 10
    done
    ;;
  "stop")
    readarray arr < "/proc/swaps"
    for line in "${arr[@]}" ; do
      if [ ${line:0:9} == "/dev/zram" ] ; then
          i=${line:9:1}
          echo "Removing swap zram $i"
          swapoff /dev/zram$i
          echo $i > /sys/class/zram-control/hot_remove
      fi
    done
    modprobe -r zram
    ;;
  "status")
    free -h
    cat /proc/swaps
    ;;
  *)
    echo "Usage: `basename $0` (start | stop | status)"
    exit 1
    ;;
esac
