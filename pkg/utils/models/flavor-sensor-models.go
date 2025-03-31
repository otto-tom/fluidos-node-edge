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

package models

// SensorInfo represents a node and its resources.
type SensorInfo struct {
	UID          string           `json:"uid"`
	Node         string           `json:"node"`
	Name         string           `json:"name"`
	Model        string           `json:"model"`
	Manufacturer string           `json:"manufacturer"`
	Market       string           `json:"market"`
	Type         SensorInfoType   `json:"type"`
	SamplingRate string           `json:"samplingRate"`
	Accuracy     []string         `json:"accuracy"`
	Consumption  string           `json:"consumption"`
	Latency      string           `json:"latency"`
	Properties   SensorInfoProp   `json:"properties,omitempty"`
	Access       SensorInfoAccess `json:"access"`
}

type SensorInfoType struct {
	SensorCategory string   `json:"sensorCategory"`
	SensorType     []string `json:"sensorType"`
}

type SensorInfoProp struct {
	Unit SensorInfoUnits `json:"unit"`
}

type SensorInfoUnits struct {
	Measurement  []string `json:"measurement"`
	Consumption  string   `json:"consumption"`
	SamplingRate string   `json:"samplingRate"`
	Latency      string   `json:"latency"`
}

type SensorInfoAccess struct {
	Type     string             `json:"type"`
	Source   string             `json:"source"`
	Resource SensorInfoResource `json:"resource"`
}

type SensorInfoResource struct {
	Topic string `json:"topic"`
	Node  string `json:"node"`
}

// SensorSelector is the flavor of a Sensor.
type SensorSelector struct {
	// TODO (Sensor): Add filters
}

// GetSelectorType returns the type of the Selector.
func (ss SensorSelector) GetSelectorType() FlavorTypeName {
	return SensorNameDefault
}
