./mvnw clean package -DskipTests

# 이미지 빌드
sudo docker build -t localhost:5000/redis-demo:latest .

# 로컬 레지스트리에 푸시 (로컬 레지스트리가 필요한 경우)
sudo docker push localhost:5000/redis-demo:latest

kubectl apply -f yaml/demo.yaml