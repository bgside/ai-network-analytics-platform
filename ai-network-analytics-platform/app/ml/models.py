import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest, RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import joblib
import os
from typing import Dict, List, Tuple, Optional
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class NetworkAnomalyDetector:
    """Machine learning model for network anomaly detection."""

    def __init__(self, model_path: str = "./models"):
        self.model_path = model_path
        self.model = None
        self.scaler = StandardScaler()
        self.feature_columns = [
            'packet_rate', 'error_rate', 'latency_p95',
            'throughput', 'cpu_usage', 'memory_usage'
        ]
        self.is_trained = False

    def load_model(self) -> bool:
        """Load pre-trained model from disk."""
        try:
            model_file = os.path.join(self.model_path, 'anomaly_detector.joblib')
            if os.path.exists(model_file):
                self.model = joblib.load(model_file)
                logger.info("Anomaly detection model loaded successfully")
                return True
            else:
                logger.warning("No pre-trained model found")
                return False
        except Exception as e:
            logger.error(f"Error loading model: {e}")
            return False

    def train_model(self, training_data: pd.DataFrame) -> bool:
        """Train the anomaly detection model."""
        try:
            # Prepare features
            X = training_data[self.feature_columns].values

            # Scale features
            X_scaled = self.scaler.fit_transform(X)

            # Train Isolation Forest model
            self.model = IsolationForest(
                n_estimators=100,
                contamination=0.1,
                random_state=42
            )

            self.model.fit(X_scaled)

            # Save model
            os.makedirs(self.model_path, exist_ok=True)
            joblib.dump(self.model, os.path.join(self.model_path, 'anomaly_detector.joblib'))
            joblib.dump(self.scaler, os.path.join(self.model_path, 'scaler.joblib'))

            self.is_trained = True
            logger.info("Anomaly detection model trained and saved")
            return True

        except Exception as e:
            logger.error(f"Error training model: {e}")
            return False

    def predict_anomalies(self, data: pd.DataFrame) -> np.ndarray:
        """Predict anomalies in network data."""
        if not self.model or not self.is_trained:
            raise ValueError("Model not trained or loaded")

        try:
            X = data[self.feature_columns].values
            X_scaled = self.scaler.transform(X)

            # Predict anomalies (-1 for anomalies, 1 for normal)
            predictions = self.model.predict(X_scaled)

            # Convert to anomaly scores (0 for normal, 1 for anomaly)
            anomaly_scores = np.where(predictions == -1, 1, 0)

            return anomaly_scores

        except Exception as e:
            logger.error(f"Error predicting anomalies: {e}")
            return np.zeros(len(data))


class NetworkPerformancePredictor:
    """Machine learning model for network performance prediction."""

    def __init__(self, model_path: str = "./models"):
        self.model_path = model_path
        self.model = None
        self.scaler = StandardScaler()
        self.is_trained = False

    def train_model(self, training_data: pd.DataFrame) -> bool:
        """Train the performance prediction model."""
        try:
            # Features for prediction
            feature_columns = [
                'packet_rate', 'error_rate', 'cpu_usage',
                'memory_usage', 'bandwidth_usage'
            ]

            # Target variable (future latency)
            target_column = 'latency_p95'

            X = training_data[feature_columns].values
            y = training_data[target_column].values

            # Scale features
            X_scaled = self.scaler.fit_transform(X)

            # Train Random Forest model
            self.model = RandomForestRegressor(
                n_estimators=200,
                max_depth=15,
                random_state=42
            )

            self.model.fit(X_scaled, y)

            # Save model
            os.makedirs(self.model_path, exist_ok=True)
            joblib.dump(self.model, os.path.join(self.model_path, 'performance_predictor.joblib'))
            joblib.dump(self.scaler, os.path.join(self.model_path, 'scaler.joblib'))

            self.is_trained = True
            logger.info("Performance prediction model trained and saved")
            return True

        except Exception as e:
            logger.error(f"Error training performance model: {e}")
            return False

    def predict_performance(self, data: pd.DataFrame) -> np.ndarray:
        """Predict future network performance."""
        if not self.model or not self.is_trained:
            raise ValueError("Performance model not trained or loaded")

        try:
            feature_columns = [
                'packet_rate', 'error_rate', 'cpu_usage',
                'memory_usage', 'bandwidth_usage'
            ]

            X = data[feature_columns].values
            X_scaled = self.scaler.transform(X)

            predictions = self.model.predict(X_scaled)
            return predictions

        except Exception as e:
            logger.error(f"Error predicting performance: {e}")
            return np.zeros(len(data))


# Global model instances
anomaly_detector = NetworkAnomalyDetector()
performance_predictor = NetworkPerformancePredictor()


def load_models() -> None:
    """Load all ML models on startup."""
    global anomaly_detector, performance_predictor

    # Try to load existing models
    anomaly_detector.load_model()
    performance_predictor.load_model()

    logger.info("ML models loaded")


def train_sample_models() -> None:
    """Train models with sample data for demonstration."""
    # Create sample training data
    np.random.seed(42)
    n_samples = 1000

    sample_data = pd.DataFrame({
        'packet_rate': np.random.normal(1000, 200, n_samples),
        'error_rate': np.random.normal(0.01, 0.005, n_samples),
        'latency_p95': np.random.normal(50, 15, n_samples),
        'throughput': np.random.normal(500, 100, n_samples),
        'cpu_usage': np.random.normal(60, 20, n_samples),
        'memory_usage': np.random.normal(70, 15, n_samples),
        'bandwidth_usage': np.random.normal(40, 10, n_samples)
    })

    # Add some anomalies for training
    anomaly_indices = np.random.choice(n_samples, size=int(n_samples * 0.1), replace=False)
    sample_data.loc[anomaly_indices, 'packet_rate'] *= 3
    sample_data.loc[anomaly_indices, 'error_rate'] *= 10
    sample_data.loc[anomaly_indices, 'latency_p95'] *= 2

    # Train models
    anomaly_detector.train_model(sample_data)
    performance_predictor.train_model(sample_data)

    logger.info("Sample models trained successfully")


def analyze_network_data(data: Dict) -> Dict:
    """Analyze network data using ML models."""
    try:
        # Convert to DataFrame
        df = pd.DataFrame([data])

        # Detect anomalies
        anomaly_scores = anomaly_detector.predict_anomalies(df)

        # Predict performance
        performance_predictions = performance_predictor.predict_performance(df)

        return {
            "anomaly_score": float(anomaly_scores[0]) if len(anomaly_scores) > 0 else 0.0,
            "predicted_latency": float(performance_predictions[0]) if len(performance_predictions) > 0 else 0.0,
            "analysis_timestamp": datetime.utcnow().isoformat(),
            "model_confidence": 0.85  # Placeholder confidence score
        }

    except Exception as e:
        logger.error(f"Error analyzing network data: {e}")
        return {
            "error": str(e),
            "analysis_timestamp": datetime.utcnow().isoformat()
        }
