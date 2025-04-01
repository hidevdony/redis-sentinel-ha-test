FROM registry:2

# 환경 변수 설정
ENV REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry
ENV REGISTRY_HTTP_ADDR=0.0.0.0:5000

# 필요한 패키지 설치 (기본 이미지에 이미 필요한 것들이 대부분 포함되어 있습니다)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 볼륨 설정 - 레지스트리 데이터 유지를 위한 볼륨
VOLUME ["/var/lib/registry"]

# 포트 노출
EXPOSE 5000

# 진입점 및 명령 설정
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/etc/docker/registry/config.yml"]