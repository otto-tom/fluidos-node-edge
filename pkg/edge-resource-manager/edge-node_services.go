// Copyright 2022-2025 FLUIDOS Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package edgeresourcemanager

import (
	b64 "encoding/base64"
	"encoding/json"
	"strings"

	devicesv1alpha2 "github.com/kubeedge/kubeedge/pkg/apis/devices/v1alpha2"

	"github.com/fluidos-project/node/pkg/utils/models"
)

// GetSensorInfos returns the NodeInfo struct for a given node and its metrics.
func GetSensorInfos(device *devicesv1alpha2.Device) ([]*models.SensorInfo, error) {

	var sensorInfo []*models.SensorInfo = forgeSensorInfo(device)

	return sensorInfo, nil
}

func GetCharacteristicUUID(device *devicesv1alpha2.Device, targetProperty string) (string, bool) {
	for _, visitor := range device.Spec.PropertyVisitors {
		if strings.EqualFold(targetProperty, visitor.PropertyName) {
			if visitor.Bluetooth != nil {
				return visitor.Bluetooth.CharacteristicUUID, true
			}
		}
	}
	return "", false
}

func GetMacNoColons(device *devicesv1alpha2.Device) string {
	rawMAC := device.Spec.Protocol.Bluetooth.MACAddress
	return strings.ReplaceAll(rawMAC, ":", "")
}

// forgeNodeInfo creates from params a new NodeInfo struct.
// TODO: Validate sensor info struct read from device instance
func forgeSensorInfo(device *devicesv1alpha2.Device) []*models.SensorInfo {

	var sensorInfo []*models.SensorInfo
	var sensorData []*models.SensorInfo

	// Sensonrs attached to the device information
	sensorsBase64 := device.ObjectMeta.Annotations["sensors"]
	sensorsDec, _ := b64.StdEncoding.DecodeString(sensorsBase64)
	json.Unmarshal(sensorsDec, &sensorData)

	// Additional required information
	charUuid, _ := GetCharacteristicUUID(device, sensorData[0].Type.SensorCategory)
	devMac := GetMacNoColons(device)
	node := device.Spec.NodeSelector.NodeSelectorTerms[0].MatchExpressions[0].Values

	for _, v := range sensorData {
		topic := "sensor/" + devMac + "/" + charUuid + "/" + v.Model
		// return
		sensorInfo = append(sensorInfo, &models.SensorInfo{
			UID:          v.UID,
			Node:         node[0],
			Name:         v.Name,
			Model:        v.Model,
			Manufacturer: v.Manufacturer,
			Market:       v.Market,
			Type: models.SensorInfoType{
				SensorCategory: v.Type.SensorCategory,
				SensorType:     v.Type.SensorType,
			},
			SamplingRate: v.SamplingRate,
			Accuracy:     v.Accuracy,
			Consumption:  v.Consumption,
			Latency:      v.Latency,
			Properties: models.SensorInfoProp{
				Unit: models.SensorInfoUnits{
					Measurement:  v.Properties.Unit.Measurement,
					Consumption:  v.Properties.Unit.Consumption,
					SamplingRate: v.Properties.Unit.SamplingRate,
					Latency:      v.Properties.Unit.Latency,
				},
			},
			Access: models.SensorInfoAccess{
				Type:   v.Access.Type,
				Source: v.Access.Source,
				Resource: models.SensorInfoResource{
					Topic: topic,
					Node:  node[0],
				},
			},
		})
	}

	return sensorInfo
}
