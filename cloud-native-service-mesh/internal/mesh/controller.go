package mesh

import (
	"fmt"
	"log"
	"time"

	"github.com/bgside/cloud-native-service-mesh/internal/database"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ServiceMeshController manages service mesh operations
type ServiceMeshController struct {
	db *gorm.DB
}

// MeshService represents a service in the mesh
type MeshService struct {
	ID          string    `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name" gorm:"not null"`
	Namespace   string    `json:"namespace" gorm:"not null"`
	Version     string    `json:"version"`
	Status      string    `json:"status" gorm:"default:active"`
	CreatedAt   time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

// TrafficPolicy represents traffic management policies
type TrafficPolicy struct {
	ID          string    `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name" gorm:"not null"`
	ServiceID   string    `json:"service_id" gorm:"not null"`
	PolicyType  string    `json:"policy_type" gorm:"not null"` // loadbalancer, circuitbreaker, retry
	Config      string    `json:"config" gorm:"type:jsonb"`
	Enabled     bool      `json:"enabled" gorm:"default:true"`
	CreatedAt   time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// NewController creates a new service mesh controller
func NewController() *ServiceMeshController {
	return &ServiceMeshController{
		db: database.GetDB(),
	}
}

// RegisterService registers a new service in the mesh
func (c *ServiceMeshController) RegisterService(name, namespace, version string) (*MeshService, error) {
	service := &MeshService{
		ID:        uuid.New().String(),
		Name:      name,
		Namespace: namespace,
		Version:   version,
		Status:    "registering",
	}

	if err := c.db.Create(service).Error; err != nil {
		return nil, fmt.Errorf("failed to register service: %w", err)
	}

	log.Printf("Service registered: %s/%s v%s", namespace, name, version)
	return service, nil
}

// GetServices returns all registered services
func (c *ServiceMeshController) GetServices() ([]MeshService, error) {
	var services []MeshService
	if err := c.db.Find(&services).Error; err != nil {
		return nil, fmt.Errorf("failed to get services: %w", err)
	}
	return services, nil
}

// GetServiceByID returns a service by ID
func (c *ServiceMeshController) GetServiceByID(id string) (*MeshService, error) {
	var service MeshService
	if err := c.db.First(&service, "id = ?", id).Error; err != nil {
		return nil, fmt.Errorf("failed to get service: %w", err)
	}
	return &service, nil
}

// UpdateServiceStatus updates the status of a service
func (c *ServiceMeshController) UpdateServiceStatus(id, status string) error {
	if err := c.db.Model(&MeshService{}).Where("id = ?", id).Update("status", status).Error; err != nil {
		return fmt.Errorf("failed to update service status: %w", err)
	}
	return nil
}

// CreateTrafficPolicy creates a new traffic policy
func (c *ServiceMeshController) CreateTrafficPolicy(name, serviceID, policyType string, config map[string]interface{}) (*TrafficPolicy, error) {
	policy := &TrafficPolicy{
		ID:         uuid.New().String(),
		Name:       name,
		ServiceID:  serviceID,
		PolicyType: policyType,
		Config:     fmt.Sprintf("%v", config),
		Enabled:    true,
	}

	if err := c.db.Create(policy).Error; err != nil {
		return nil, fmt.Errorf("failed to create traffic policy: %w", err)
	}

	log.Printf("Traffic policy created: %s for service %s", name, serviceID)
	return policy, nil
}

// GetTrafficPolicies returns all traffic policies for a service
func (c *ServiceMeshController) GetTrafficPolicies(serviceID string) ([]TrafficPolicy, error) {
	var policies []TrafficPolicy
	if err := c.db.Where("service_id = ?", serviceID).Find(&policies).Error; err != nil {
		return nil, fmt.Errorf("failed to get traffic policies: %w", err)
	}
	return policies, nil
}

// GetMeshHealth returns the overall health of the service mesh
func (c *ServiceMeshController) GetMeshHealth() map[string]interface{} {
	var totalServices int64
	var activeServices int64

	c.db.Model(&MeshService{}).Count(&totalServices)
	c.db.Model(&MeshService{}).Where("status = ?", "active").Count(&activeServices)

	health := map[string]interface{}{
		"total_services":   totalServices,
		"active_services":  activeServices,
		"mesh_status":      "healthy",
		"last_updated":     time.Now().UTC().Format(time.RFC3339),
	}

	if activeServices == 0 && totalServices > 0 {
		health["mesh_status"] = "degraded"
	} else if totalServices == 0 {
		health["mesh_status"] = "empty"
	}

	return health
}
