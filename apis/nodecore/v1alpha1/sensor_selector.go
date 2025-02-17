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

import "k8s.io/klog/v2"

// SensorFlavorSelector is the selector for a SensorFlavor.
type SensorFlavorSelector struct {
	// Sensor UID filter of the Sensor Flavor.
	UIDFilter *StringFilter `json:"uidFilter,omitempty"`
	// Sensor node filter of the Sensor Flavor.
	NodeFilter *StringFilter `json:"nodeFilter,omitempty"`
	// Sensor type filter of the Sensor Flavor.
	TypeFilter *StringFilter `json:"typeFilter,omitempty"`
	// Sensor model filter of the Sensor Flavor.
	ModelFilter *StringFilter `json:"modelFilter,omitempty"`
	// Sensor manufacturer filter of the Sensor Flavor.
	ManufacturerFilter *StringFilter `json:"manufacturerFilter,omitempty"`
	// Sensor market filter of the Sensor Flavor.
	MarketFilter *StringFilter `json:"marketFilter,omitempty"`
	// Sensor sampling filter rate of the Sensor Flavor.
	SamplingRateFilter *StringFilter `json:"srateFilter,omitempty"`
	// Sensor accuracy filter of the Sensor Flavor.
	AccuracyFilter *StringFilter `json:"accuracyFilter,omitempty"`
	// Sensor consumption filter of the Sensor Flavor.
	ConsumptionFilter *StringFilter `json:"consumptionFilter,omitempty"`
	//TODO: add Security standards filter
	// Sensor latency filter of the Sensor Flavor.
	LatencyFilter *StringFilter `json:"latencyFilter,omitempty"`
}

// GetFlavorTypeSelector returns the type of the Flavor.
func (*SensorFlavorSelector) GetFlavorTypeSelector() FlavorTypeIdentifier {
	return TypeSensor
}

// ParseSensorFlavorSelector parses the SensorFlavorSelector into a map of filters.
// func ParseSensorFlavorSelector(sensorFlavorSelector *SensorFlavorSelector) (map[FilterType]interface{}, error) {
// 	filters := make(map[FilterType]interface{})
// 	if sensorFlavorSelector.TypeFilter != nil {
// 		klog.Info("Parsing Type filter")
// 		// Parse Architecture filter
// 		typeFilterType, typeFilterData, err := ParseStringFilter(sensorFlavorSelector.TypeFilter)
// 		if err != nil {
// 			return nil, err
// 		}
// 		filters[typeFilterType] = typeFilterData
// 	}
// 	if sensorFlavorSelector.ManufacturerFilter != nil {
// 		klog.Info("Parsing Manufacturer filter")
// 		// Parse Manufacturer filter
// 		manufacturerFilterType, manufacturerFilterData, err := ParseStringFilter(sensorFlavorSelector.ManufacturerFilter)
// 		if err != nil {
// 			return nil, err
// 		}
// 		filters[manufacturerFilterType] = manufacturerFilterData
// 	}
// 	if sensorFlavorSelector.MarketFilter != nil {
// 		klog.Info("Parsing Market filter")
// 		// Parse Market filter
// 		marketFilterType, marketFilterData, err := ParseStringFilter(sensorFlavorSelector.MarketFilter)
// 		if err != nil {
// 			return nil, err
// 		}
// 		filters[marketFilterType] = marketFilterData
// 	}
// 	if sensorFlavorSelector.SamplingRateFilter != nil {
// 		klog.Info("Parsing Sampling Rate filter")
// 		// Parse SamplingRate filter
// 		samplingRateFilterType, samplingRateFilterData, err := ParseStringFilter(sensorFlavorSelector.SamplingRateFilter)
// 		if err != nil {
// 			return nil, err
// 		}
// 		filters[samplingRateFilterType] = samplingRateFilterData
// 	}
// 	if sensorFlavorSelector.AccuracyFilter != nil {
// 		klog.Info("Parsing Accuracy filter")
// 		// Parse Accuracy filter
// 		accuracyFilterType, accuracyFilterData, err := ParseStringFilter(sensorFlavorSelector.AccuracyFilter)
// 		if err != nil {
// 			return nil, err
// 		}
// 		filters[accuracyFilterType] = accuracyFilterData
// 	}
// 	if sensorFlavorSelector.ConsumptionFilter != nil {
// 		klog.Info("Parsing Consumption filter")
// 		// Parse Consumption filter
// 		consumptionFilterType, consumptionFilterData, err := ParseStringFilter(sensorFlavorSelector.ConsumptionFilter)
// 		if err != nil {
// 			return nil, err
// 		}
// 		filters[consumptionFilterType] = consumptionFilterData
// 	}
// 	if sensorFlavorSelector.LatencyFilter != nil {
// 		klog.Info("Parsing Latency filter")
// 		// Parse Latency filter
// 		latencyFilterType, latencyFilterData, err := ParseStringFilter(sensorFlavorSelector.LatencyFilter)
// 		if err != nil {
// 			return nil, err
// 		}
// 		filters[latencyFilterType] = latencyFilterData
// 	}

// 	return filters, nil
// }

// ParseSensorFlavorSelector parses the SensorFlavorSelector into a map of filters.
func ParseSensorFlavorSelector(sensorFlavorSelector *SensorFlavorSelector) (map[FilterType]interface{}, error) {
	filters := make(map[FilterType]interface{})

	applyFilter := func(filter *StringFilter, filterName string) error {
		if filter == nil {
			return nil
		}
		klog.Infof("Parsing %s filter", filterName)
		filterType, filterData, err := ParseStringFilter(filter)
		if err != nil {
			return err
		}
		filters[filterType] = filterData
		return nil
	}

	filterMappings := map[string]*StringFilter{
		"UID":          sensorFlavorSelector.UIDFilter,
		"Node":         sensorFlavorSelector.NodeFilter,
		"Type":         sensorFlavorSelector.TypeFilter,
		"Manufacturer": sensorFlavorSelector.ManufacturerFilter,
		"Market":       sensorFlavorSelector.MarketFilter,
		"SamplingRate": sensorFlavorSelector.SamplingRateFilter,
		"Accuracy":     sensorFlavorSelector.AccuracyFilter,
		"Consumption":  sensorFlavorSelector.ConsumptionFilter,
		"Latency":      sensorFlavorSelector.LatencyFilter,
	}

	for name, filter := range filterMappings {
		if err := applyFilter(filter, name); err != nil {
			return nil, err
		}
	}

	return filters, nil
}
