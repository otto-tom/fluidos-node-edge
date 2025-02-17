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
	"context"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/rest"
	"k8s.io/klog/v2"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/handler"
	"sigs.k8s.io/controller-runtime/pkg/webhook"

	nodecorev1alpha1 "github.com/fluidos-project/node/apis/nodecore/v1alpha1"
	"github.com/fluidos-project/node/pkg/utils/flags"

	models "github.com/fluidos-project/node/pkg/utils/models"
	"github.com/fluidos-project/node/pkg/utils/resourceforge"

	edgeclientset "github.com/kubeedge/kubeedge/pkg/client/clientset/versioned"
	"github.com/kubeedge/kubeedge/tests/e2e/utils"
)

// ClusterRole
// +kubebuilder:rbac:groups=nodecore.fluidos.eu,resources=flavors,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=core,resources=nodes,verbs=get;list;watch
// +kubebuilder:rbac:groups=core,resources=configmaps,verbs=get;list;watch
// +kubebuilder:rbac:groups=core,resources=endpoints,verbs=get;list;watch
// +kubebuilder:rbac:groups=metrics.k8s.io,resources=pods,verbs=get;list;watch
// +kubebuilder:rbac:groups=metrics.k8s.io,resources=nodes,verbs=get;list;watch

// NodeReconciler reconciles a Node object and creates Flavor objects.
type EdgeNodeReconciler struct {
	client.Client
	Scheme              *runtime.Scheme
	EnableAutoDiscovery bool
	WebhookServer       webhook.Server
}

// Reconcile reconciles a Node object to create Flavor objects.
func (r *EdgeNodeReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := ctrl.LoggerFrom(ctx, "node", req.NamespacedName)
	ctx = ctrl.LoggerInto(ctx, log)

	klog.Info("This is the EDGE NODE CONTROLLER Reconcile!")

	// Check if AutoDiscovery is enabled
	if !r.EnableAutoDiscovery {
		klog.Info("AutoDiscovery is disabled")
		return ctrl.Result{}, nil
	}

	// Check if the webhook server is running
	if err := r.WebhookServer.StartedChecker()(nil); err != nil {
		klog.Info("Webhook server not started yet, requeuing the request")
		return ctrl.Result{Requeue: true}, nil
	}

	// Set for labels over the node
	labelSelector := labels.Set{flags.ResourceNodeLabel: "true"}.AsSelector()

	// Fetch the Node instance
	var node corev1.Node
	if err := r.Get(ctx, req.NamespacedName, &node); err != nil {
		if client.IgnoreNotFound(err) != nil {
			klog.Info("Node not found")
			return ctrl.Result{}, nil
		}
	}

	// Check if the node has the label
	if !labelSelector.Matches(labels.Set(node.GetLabels())) {
		klog.Infof("Node %s does not have the label %s", node.Name, flags.ResourceNodeLabel)
		return ctrl.Result{}, nil
	}

	klog.Infof("Node %s has the label %s", node.Name, flags.ResourceNodeLabel)

	// Try in-cluster config first
	config, err := rest.InClusterConfig()
	if err != nil {
		klog.Fatalf("Failed to get in-cluster config: %v", err)
	}

	// Create the KubeEdge clientset using the in-cluster config
	clientset, err := edgeclientset.NewForConfig(config)
	if err != nil {
		klog.Fatalf("Failed to create KubeEdge clientset: %v", err)
	}

	// Get device list
	// FIXME: No error check
	deviceInstanceList, _ := utils.ListDevice(clientset, "default")

	klog.Infof("\033[7mTotal devices found:\033[0m %d\n", len(deviceInstanceList))

	return ctrl.Result{}, nil
}

func (r *EdgeNodeReconciler) createFlavor(ctx context.Context, sensorInfo *models.SensorInfo,
	nodeIdentity nodecorev1alpha1.NodeIdentity, ownerReferences []metav1.OwnerReference) (flavor *nodecorev1alpha1.Flavor, err error) {
	// Forge the Flavor from the NodeInfo and NodeIdentity
	flavorResult := resourceforge.ForgeSensorFlavorFromMetrics(sensorInfo, nodeIdentity, ownerReferences)

	// Create the Flavor
	err = r.Create(ctx, flavorResult)
	if err != nil {
		return nil, err
	}
	klog.Infof("Flavor created: %s", flavorResult.Name)

	return flavorResult, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *EdgeNodeReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&corev1.Node{}).
		Watches(&nodecorev1alpha1.Flavor{}, &handler.EnqueueRequestForObject{}).
		Complete(r)
}
