#!/usr/bin/bash

DEVICE_MODEL="../../quickstart/edge/cloudcore/manifests/samples/devices/SensorTile-BLE-Device-Model.yaml"
DEVICE_INSTANCE="../../quickstart/edge/cloudcore/manifests/samples/devices/SensorTile-BLE-Instance_tb.yaml"
CLUSTER=fluidos-provider-1-edge

echo "1. Make sure that a BT device is availale over HCI"
echo "2. Make sure that a BT IoT device is flashed with the FW and powered on"
echo "2. Assuming that Fluidos edge provider cluster is \"$CLUSTER\""
echo "Installing bluez"

set -e
check_file $DEVICE_MODEL
check_file $DEVICE_INSTANCE
set +e

if [ ! $(dpkg-query -W bluez &>/dev/null) ]; then 
  sudo apt-get update
  sudo apt-get install -y bluez
else
  echo "   bluez is already installed"
fi

sudo hciconfig hci0 down
sudo hciconfig hci0 up
timeout -s INT 10s sudo hcitool lescan --discovery=g > bleDev
STWIN_MAC=$(cat bleDev | grep -i "bluenrg" | awk 'NR==1 {print $1}')
rm bleDev
if [ -z "${STWIN_MAC}" ]; then 
  echo "Device not found"; 
  exit -1
else 
  echo "Found device, MAC: $STWIN_MAC"; 
fi

echo "Updating device instantiation file"
STWIN_MACID=$(echo $STWIN_MAC | sed 's/\://g' | sed 's/.*/\L&/g')
sed -i 's, macAddress: .*, macAddress: '"$STWIN_MAC"',' $DEVICE_INSTANCE
sed -i '/metadata:/{n;s/name: stwinkt1b-.*/name: stwinkt1b-'"$STWIN_MACID"'/}' $DEVICE_INSTANCE

# Register BT LED
echo "Registering BT device $STWIN_MAC"
export KUBECONFIG=./$CLUSTER-config
kubectl apply -f $DEVICE_MODEL
kubectl apply -f $DEVICE_INSTANCE

echo "Done"

function check_file() { 
  local FILENAME=$1
  if [ ! -f $FILENAME ]; then 
    echo "File $FILENAME not found, exiting"
    return -2
  else
    return 0
  fi
}
