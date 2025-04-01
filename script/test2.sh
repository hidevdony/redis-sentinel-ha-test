# Redis Sentinel configuration - update with your Kubernetes service names
SENTINEL_HOST="redis-sentinel-svc"  # Change to your Kubernetes Sentinel service name
SENTINEL_PORT="26379"
REDIS_SERVICE_NAME="mymaster"  # Service name configured in sentinel.conf
REDIS_PASSWORD="your_password"  # Set your Redis password here

redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT $AUTH_PARAM SET $key $value)