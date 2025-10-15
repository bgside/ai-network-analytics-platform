package api

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"github.com/bgside/cloud-native-service-mesh/internal/mesh"
)

// SetupRoutes configures all API routes
func SetupRoutes(router *gin.Engine, meshController *mesh.ServiceMeshController) {
	api := router.Group("/api/v1")
	{
		// Service management routes
		api.POST("/services", registerService(meshController))
		api.GET("/services", getServices(meshController))
		api.GET("/services/:id", getServiceByID(meshController))
		api.PUT("/services/:id/status", updateServiceStatus(meshController))

		// Traffic policy routes
		api.POST("/policies", createTrafficPolicy(meshController))
		api.GET("/policies/:serviceId", getTrafficPolicies(meshController))

		// Mesh health and monitoring
		api.GET("/mesh/health", getMeshHealth(meshController))
		api.GET("/mesh/services", getServices(meshController))
	}
}

// Service handlers

func registerService(controller *mesh.ServiceMeshController) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Name      string `json:"name" binding:"required"`
			Namespace string `json:"namespace" binding:"required"`
			Version   string `json:"version"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		service, err := controller.RegisterService(req.Name, req.Namespace, req.Version)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, service)
	}
}

func getServices(controller *mesh.ServiceMeshController) gin.HandlerFunc {
	return func(c *gin.Context) {
		services, err := controller.GetServices()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"services": services})
	}
}

func getServiceByID(controller *mesh.ServiceMeshController) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		service, err := controller.GetServiceByID(id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Service not found"})
			return
		}

		c.JSON(http.StatusOK, service)
	}
}

func updateServiceStatus(controller *mesh.ServiceMeshController) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")

		var req struct {
			Status string `json:"status" binding:"required"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		err := controller.UpdateServiceStatus(id, req.Status)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Service status updated"})
	}
}

// Traffic policy handlers

func createTrafficPolicy(controller *mesh.ServiceMeshController) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Name      string                 `json:"name" binding:"required"`
			ServiceID string                 `json:"service_id" binding:"required"`
			PolicyType string                `json:"policy_type" binding:"required"`
			Config    map[string]interface{} `json:"config"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		policy, err := controller.CreateTrafficPolicy(req.Name, req.ServiceID, req.PolicyType, req.Config)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, policy)
	}
}

func getTrafficPolicies(controller *mesh.ServiceMeshController) gin.HandlerFunc {
	return func(c *gin.Context) {
		serviceID := c.Param("serviceId")

		policies, err := controller.GetTrafficPolicies(serviceID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"policies": policies})
	}
}

// Mesh health handler

func getMeshHealth(controller *mesh.ServiceMeshController) gin.HandlerFunc {
	return func(c *gin.Context) {
		health := controller.GetMeshHealth()
		c.JSON(http.StatusOK, health)
	}
}
