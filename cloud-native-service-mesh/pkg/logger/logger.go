package logger

import (
	"log"
	"os"
	"strings"

	"github.com/sirupsen/logrus"
)

// Logger is the global logger instance
var Logger *logrus.Logger

// Init initializes the logger with the specified level
func Init(level string) {
	Logger = logrus.New()

	// Set log level
	logLevel, err := logrus.ParseLevel(strings.ToLower(level))
	if err != nil {
		logLevel = logrus.InfoLevel
	}
	Logger.SetLevel(logLevel)

	// Set output to stdout
	Logger.SetOutput(os.Stdout)

	// Set formatter
	Logger.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: "2006-01-02T15:04:05Z07:00",
	})

	log.Println("Logger initialized with level:", level)
}

// Info logs an info message
func Info(args ...interface{}) {
	if Logger != nil {
		Logger.Info(args...)
	} else {
		log.Println("INFO:", args...)
	}
}

// Warn logs a warning message
func Warn(args ...interface{}) {
	if Logger != nil {
		Logger.Warn(args...)
	} else {
		log.Println("WARN:", args...)
	}
}

// Error logs an error message
func Error(args ...interface{}) {
	if Logger != nil {
		Logger.Error(args...)
	} else {
		log.Println("ERROR:", args...)
	}
}

// Fatal logs a fatal message and exits
func Fatal(args ...interface{}) {
	if Logger != nil {
		Logger.Fatal(args...)
	} else {
		log.Fatal("FATAL:", args...)
	}
}

// Infof logs a formatted info message
func Infof(format string, args ...interface{}) {
	if Logger != nil {
		Logger.Infof(format, args...)
	} else {
		log.Printf("INFO: "+format, args...)
	}
}

// Warnf logs a formatted warning message
func Warnf(format string, args ...interface{}) {
	if Logger != nil {
		Logger.Warnf(format, args...)
	} else {
		log.Printf("WARN: "+format, args...)
	}
}

// Errorf logs a formatted error message
func Errorf(format string, args ...interface{}) {
	if Logger != nil {
		Logger.Errorf(format, args...)
	} else {
		log.Printf("ERROR: "+format, args...)
	}
}

// Fatalf logs a formatted fatal message and exits
func Fatalf(format string, args ...interface{}) {
	if Logger != nil {
		Logger.Fatalf(format, args...)
	} else {
		log.Fatalf("FATAL: "+format, args...)
	}
}
