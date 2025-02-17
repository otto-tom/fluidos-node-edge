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
	"fmt"

	devicesv1alpha2 "github.com/kubeedge/kubeedge/pkg/apis/devices/v1alpha2"

	"github.com/fluidos-project/node/pkg/utils/models"
)

// GetSensorInfos returns the NodeInfo struct for a given node and its metrics.
func GetSensorInfos(device *devicesv1alpha2.Device) (*models.SensorInfo, error) {

	desc := device.ObjectMeta.Labels["description"]
	_ = desc
	fmt.Printf("\033[0mDescription:\033[0m %s\n", desc)

	manu := device.ObjectMeta.Labels["manufacturer"]
	_ = manu
	fmt.Printf("\033[0mManufacturer:\033[0m %s\n", manu)

	model := device.ObjectMeta.Labels["model"]
	_ = model
	fmt.Printf("\033[0mModel:\033[0m %s\n", model)

	sensorsBase64 := device.ObjectMeta.Annotations["sensors"]
	fmt.Printf("\033[0mSensors Base64 Encoded:\033[0m %s\n", sensorsBase64)

	sensorsDec, _ := b64.StdEncoding.DecodeString(sensorsBase64)
	fmt.Printf("\033[0mSensors Decoded\033[0m \n %s \n", sensorsDec)

	// devicesv1alpha2.Device

	// metricsStruct := forgeResourceMetrics(nodeMetrics, node)
	sensorInfo := forgeSensorInfo(device)

	return sensorInfo, nil
}

// forgeResourceMetrics creates from params a new ResourceMetrics Struct.
// func forgeResourceMetrics(sensorMetrics *metricsv1beta1.NodeMetrics, node *corev1.Node) *models.ResourceMetrics {
// 	// Get the total and used resources
// 	// cpuTotal := node.Status.Allocatable.Cpu().DeepCopy()
// 	// cpuUsed := nodeMetrics.Usage.Cpu().DeepCopy()
// 	// memoryTotal := node.Status.Allocatable.Memory().DeepCopy()
// 	// memoryUsed := nodeMetrics.Usage.Memory().DeepCopy()
// 	// podsTotal := node.Status.Allocatable.Pods().DeepCopy()
// 	// podsUsed := nodeMetrics.Usage.Pods().DeepCopy()
// 	// ephemeralStorage := nodeMetrics.Usage.StorageEphemeral().DeepCopy()

// 	// // Compute the available resources
// 	// cpuAvail := cpuTotal.DeepCopy()
// 	// memAvail := memoryTotal.DeepCopy()
// 	// podsAvail := podsTotal.DeepCopy()
// 	// cpuAvail.Sub(cpuUsed)
// 	// memAvail.Sub(memoryUsed)
// 	// podsAvail.Sub(podsUsed)

// 	return &models.ResourceMetrics{
// 		CPUTotal:         cpuTotal,
// 		CPUAvailable:     cpuAvail,
// 		MemoryTotal:      memoryTotal,
// 		MemoryAvailable:  memAvail,
// 		PodsTotal:        podsTotal,
// 		PodsAvailable:    podsAvail,
// 		EphemeralStorage: ephemeralStorage,
// 	}
// }

// forgeNodeInfo creates from params a new NodeInfo struct.
func forgeSensorInfo(device *devicesv1alpha2.Device) *models.SensorInfo {
	return &models.SensorInfo{
		UID:  "UID",
		Name: "Name",
	}
}
