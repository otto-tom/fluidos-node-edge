// Copyright 2022-2024 FLUIDOS Project
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

import (
	"encoding/json"
	"fmt"
)

// SensorFlavor represents a Sensor Flavor description.
type SensorFlavor struct {
	// Characteristics of the Sensor Flavor
	Characteristics SensorCharacteristics `json:"characteristics"`
	// Policies of the Sensor Flavor
	Access SensorAccess `json:"access"`
}

// GetFlavorType returns the type of the Flavor.
func (sensor *SensorFlavor) GetFlavorType() FlavorTypeIdentifier {
	return TypeSensor
}

// SensorCharacteristics represents the characteristics of a Sensor Flavor,.
type SensorCharacteristics struct {
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
	Accuracy string `json:"accuracy,omitempty"`
	// Sensor consumption of the Sensor Flavor.
	Consumption string `json:"consumption,omitempty"`
	//TODO: add Security standards
	// Sensor latency of the Sensor Flavor.
	Latency string `json:"latency,omitempty"`
	// Sensor additional properties of the Sensor Flavor.
	AdditionalProperties SensorAdditionalProperties `json:"extraProperties,omitempty"`
}

type SensorType struct {
	SensorCategory string `json:"category"`
	SensorType     string `json:"type"`
}

type SensorAdditionalProperties struct {
	// Sensor type
	Unit SensorUnits `json:"units"`
}

type SensorUnits struct {
	// Sensor measurement unit
	Measurement string `json:"measurement"`
	// Sensor consumption unit
	Consumption string `json:"consumption"`
	// Sensor sampling rate unit
	SamplingRate string `json:"sampling"`
}

// SensorAccess represents sensor access information to be used by the router.
type SensorAccess struct {
	// Type is access type
	Type string `json:"type"`
	// Source is the source resource endpoint (rules.kubeedge.io/v1 -> RuleEndpoint)
	Source string `json:"source"`
	// Resource is the source resource endpoint
	Resource Resource `json:"resource"`
}

type Resource struct {
	// Topic is the topic from which sensor data comes from name
	Topic string `json:"topic"`
	// Node is the name of the node that sends the sensor data
	Node string `json:"node"`
}

// ParseSensorFlavor parses the Sensor Flavor.
func ParseSensorFlavor(flavorType FlavorType) (*SensorFlavor, error) {
	sensor := &SensorFlavor{}
	// Check type of the Flavor
	if flavorType.TypeIdentifier != TypeSensor {
		return nil, fmt.Errorf("flavor type is not a Sensor")
	}

	// Unmarshal the raw data into the Sensor struct
	if err := json.Unmarshal(flavorType.TypeData.Raw, sensor); err != nil {
		return nil, err
	}

	return sensor, nil
}
