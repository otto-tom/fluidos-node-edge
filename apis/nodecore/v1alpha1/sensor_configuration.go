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

package v1alpha1

// K8SliceConfiguration is the partition of the flavor K8Slice.
type SensorConfiguration struct {
	// Sensor UID of the Sensor Flavor
	UID string `json:"uid"`
	// Node serving the sensor of the Sensor Flavor
	Node string `json:"node"`
	// Sensor type of the Sensor Flavor.
	Type SensorType `json:"type"`
	// Sensor model of the Sensor Flavor.
	Model string `json:"model"`
	// Sensor manufacturer of the Sensor Flavor.
	Manufacturer string `json:"manufacturer"`
	// Sensor market of the Sensor Flavor.
	Market string `json:"market,omitempty"`
	// Sensor sampling rate of the Sensor Flavor.
	SamplingRate string `json:"srate,omitempty"`
	// Sensor accuracy of the Sensor Flavor.
	// +kubebuilder:validation:Type=array
	// +kubebuilder:validation:Items=type=string
	Accuracy []string `json:"accuracy,omitempty"`
	// Sensor consumption of the Sensor Flavor.
	Consumption string `json:"consumption,omitempty"`
	//TODO: add Security standards
	// Sensor latency of the Sensor Flavor.
	Latency string `json:"latency,omitempty"`
	// Sensor additional properties of the Sensor Flavor.
	AdditionalProperties SensorAdditionalProperties `json:"extraProperties,omitempty"`
}
