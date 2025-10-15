package config

import (
	"log"
	"os"

	"github.com/spf13/viper"
)

// Config holds all configuration for the service mesh controller
type Config struct {
	Port        string `mapstructure:"PORT"`
	Debug       bool   `mapstructure:"DEBUG"`
	LogLevel    string `mapstructure:"LOG_LEVEL"`
	DatabaseURL string `mapstructure:"DATABASE_URL"`

	JWT struct {
		Secret string `mapstructure:"JWT_SECRET"`
		Expiry string `mapstructure:"JWT_EXPIRY"`
	} `mapstructure:",squash"`

	Istio struct {
		Namespace string `mapstructure:"ISTIO_NAMESPACE"`
		Gateway   string `mapstructure:"ISTIO_GATEWAY"`
	} `mapstructure:",squash"`
}

// Load loads configuration from environment variables and config files
func Load() *Config {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")

	// Set default values
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("DEBUG", true)
	viper.SetDefault("LOG_LEVEL", "info")
	viper.SetDefault("DATABASE_URL", "postgres://mesh:mesh_password@localhost:5432/service_mesh?sslmode=disable")
	viper.SetDefault("JWT_SECRET", "your-jwt-secret-key")
	viper.SetDefault("JWT_EXPIRY", "24h")
	viper.SetDefault("ISTIO_NAMESPACE", "istio-system")
	viper.SetDefault("ISTIO_GATEWAY", "istio-gateway")

	// Enable reading from environment variables
	viper.AutomaticEnv()

	// Read configuration file (optional)
	if err := viper.ReadInConfig(); err != nil {
		log.Printf("No config file found, using environment variables and defaults: %v", err)
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		log.Fatalf("Unable to decode config into struct: %v", err)
	}

	return &config
}
