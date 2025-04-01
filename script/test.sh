#!/bin/bash

# Redis Sentinel configuration - update with your Kubernetes service names
SENTINEL_HOST="redis"  # Change to your Kubernetes Sentinel service name
SENTINEL_PORT="26379"
REDIS_SERVICE_NAME="mymaster"  # Service name configured in sentinel.conf
REDIS_PASSWORD="LwDyEUqdjx"  # Set your Redis password here

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Auth parameter for redis-cli
AUTH_PARAM=""
if [ ! -z "$REDIS_PASSWORD" ]; then
  AUTH_PARAM="-a $REDIS_PASSWORD"
fi

echo -e "${YELLOW}Starting Redis Sentinel High Availability Test${NC}"

# Get current master info
get_master_info() {
  master_info=$(redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT $AUTH_PARAM sentinel get-master-addr-by-name $REDIS_SERVICE_NAME)
  master_host=$(echo "$master_info" | head -n 1)
  master_port=$(echo "$master_info" | tail -n 1)
  echo "$master_host $master_port"
}

# Test write operation
test_write() {
  local host=$1
  local port=$2
  local key=$3
  local value=$4

  result=$(redis-cli -h $host -p $port $AUTH_PARAM SET $key $value)
  if [ "$result" == "OK" ]; then
    echo -e "${GREEN}Write successful: $key=$value${NC}"
    return 0
  else
    echo -e "${RED}Write failed: $key=$value${NC}"
    return 1
  fi
}

# Test read operation
test_read() {
  local host=$1
  local port=$2
  local key=$3
  local expected=$4

  result=$(redis-cli -h $host -p $port $AUTH_PARAM GET $key)
  if [ "$result" == "$expected" ]; then
    echo -e "${GREEN}Read successful: $key=$result${NC}"
    return 0
  else
    echo -e "${RED}Read failed: $key=$result (expected: $expected)${NC}"
    return 1
  fi
}

# Get slaves information
get_slaves_info() {
  slaves_info=$(redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT $AUTH_PARAM sentinel slaves $REDIS_SERVICE_NAME)
  echo "$slaves_info"
}

# Check master node status
check_master_status() {
  local host=$1
  local port=$2
  redis-cli -h $host -p $port $AUTH_PARAM PING >/dev/null 2>&1
  return $?
}

# 1. Check initial status
echo -e "\n${YELLOW}[1] Checking initial status${NC}"
master_info=$(get_master_info)
master_host=$(echo $master_info | cut -d' ' -f1)
master_port=$(echo $master_info | cut -d' ' -f2)

echo "Current master: $master_host:$master_port"
echo "Slave nodes list:"
get_slaves_info | grep -E "ip|port|name" | sort

# 2. Write data to master node
echo -e "\n${YELLOW}[2] Testing write operations to master node${NC}"
test_write $master_host $master_port "test_key" "before_failover"
test_read $master_host $master_port "test_key" "before_failover"

# 3. Simulate master node failure
echo -e "\n${YELLOW}[3] Simulating master node failure${NC}"
echo "Temporarily suspending master node $master_host:$master_port..."

# Option 1: Using DEBUG SLEEP - Master will not respond for 30 seconds
redis-cli -h $master_host -p $master_port $AUTH_PARAM DEBUG sleep 30 &

# Option 2: Using kubectl to delete the master pod (uncomment to use)
# MASTER_POD=$(kubectl get pods -l "app=redis,role=master" -o jsonpath="{.items[0].metadata.name}")
# kubectl delete pod $MASTER_POD &

# 4. Wait for failover detection and completion
echo -e "\n${YELLOW}[4] Waiting for Sentinel failover...${NC}"
failover_timeout=60
for i in $(seq 1 $failover_timeout); do
  echo -n "."
  sleep 1

  # Check master info every 5 seconds
  if [ $((i % 5)) -eq 0 ]; then
    new_master_info=$(get_master_info)
    new_master_host=$(echo $new_master_info | cut -d' ' -f1)
    new_master_port=$(echo $new_master_info | cut -d' ' -f2)

    if [ "$new_master_host $new_master_port" != "$master_host $master_port" ]; then
      echo -e "\n${GREEN}New master detected: $new_master_host:$new_master_port${NC}"
      master_host=$new_master_host
      master_port=$new_master_port
      break
    fi
  fi
done

echo -e "\nCurrent master: $master_host:$master_port"

# 5. Check data consistency and write new data
echo -e "\n${YELLOW}[5] Verifying data consistency after failover${NC}"
# Check existing data
test_read $master_host $master_port "test_key" "before_failover"

# Write new data
test_write $master_host $master_port "test_key2" "after_failover"
test_read $master_host $master_port "test_key2" "after_failover"

# 6. Check final system status
echo -e "\n${YELLOW}[6] Current system status${NC}"
echo "Current master: $master_host:$master_port"
echo "Slave nodes list:"
get_slaves_info | grep -E "ip|port|name" | sort

echo -e "\n${GREEN}Redis Sentinel High Availability Test Completed${NC}"