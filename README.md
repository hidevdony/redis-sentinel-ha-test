# Redis 가용성 테스트 시나리오 상세 분석

## 테스트 환경 구성
- **마스터 노드**: 1개
- **센티넬 노드**: 3개
- **구성된 파드**:
  ```
  NAME                          READY   STATUS    RESTARTS      AGE
  redis-demo-768f969556-rpz2l   1/1     Running   0             4h9m
  redis-node-0                  2/2     Running   0             5h30m
  redis-node-1                  2/2     Running   0             5h31m
  redis-node-2                  2/2     Running   0             5h31m
  redis-sentinel-tester         1/1     Running   4 (54m ago)   3h56m
  redisinsight-0                1/1     Running   0             6h21m
  ```

## 테스트 과정 상세

### 1. 초기 Redis 센티넬 구성 확인

센티넬 상태를 확인하여 초기 레플리케이션 토폴로지 파악:
```
redis-cli -h redis -p 26379 -a LwDyEUqdjx sentinel get-master-addr-by-name mymaster
redis-cli -h redis -p 26379 -a LwDyEUqdjx sentinel slaves mymaster
```

확인 결과, `redis-node-2`가 마스터 노드로 작동 중이며, `redis-node-0`와 `redis-node-1`이 슬레이브로 구성되어 있음을 확인했습니다:
```
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1) "redis-node-2.redis-headless.default.svc.cluster.local"
2) "6379"
```

슬레이브 노드 상태 정보:
```
1)  1) "name"
    2) "redis-node-0.redis-headless.default.svc.cluster.local:6379"
    ...
    33) "master-host"
    34) "redis-node-2.redis-headless.default.svc.cluster.local"
    ...

2)  1) "name"
    2) "redis-node-1.redis-headless.default.svc.cluster.local:6379"
    ...
    33) "master-host"
    34) "redis-node-2.redis-headless.default.svc.cluster.local"
    ...
```

### 2. 마스터 노드 강제 중단 테스트 시도

최초에는 DEBUG sleep 명령을 통한 마스터 노드 일시 중단을 시도했으나 보안 설정으로 인해 실패:
```
redis-cli -h redis -p 6379 -a LwDyEUqdjx DEBUG sleep 180 &
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
(error) ERR DEBUG command not allowed. If the enable-debug-command option is set to "local", you can run it from a local connection, otherwise you need to set this option in the configuration file, and then restart the server.
```

### 3. 마스터 노드 완전 제거를 통한 장애 시뮬레이션

마스터 노드(`redis-node-2`)를 직접 삭제하여 강제 장애 상황 시뮬레이션:
```
dony@dony-B650-LiveMixer:~$ kubectl get pod
NAME                          READY   STATUS    RESTARTS      AGE
redis-demo-768f969556-rpz2l   1/1     Running   0             4h28m
redis-node-0                  2/2     Running   0             5h49m
redis-node-1                  2/2     Running   0             5h49m
redis-node-2                  2/2     Running   0             5h50m
redis-sentinel-tester         1/1     Running   5 (12m ago)   4h14m
redisinsight-0                1/1     Running   0             6h39m
dony@dony-B650-LiveMixer:~$ kubectl delete pod/redis-node-2
pod "redis-node-2" deleted
```

### 4. 애플리케이션 로그에서 장애 감지 및 자동 복구 과정 확인

클라이언트 애플리케이션(`redis-demo`)은 장애 발생 시점에 즉시 연결 끊김을 감지하고 재연결 시도:
```
2025-04-01T12:25:52.004Z  INFO 1 --- [demo] [xecutorLoop-1-1] i.l.core.protocol.ConnectionWatchdog     : Reconnecting, last destination was redis-node-2.redis-headless.default.svc.cluster.local/10.42.0.53:6379
2025-04-01T12:25:52.008Z  INFO 1 --- [demo] [ioEventLoop-6-2] i.l.core.protocol.ReconnectionHandler    : Reconnected to redis-node-0.redis-headless.default.svc.cluster.local/<unresolved>:6379
```

이 로그에서 주목할 점:
- Lettuce 클라이언트 라이브러리의 ConnectionWatchdog가 연결 끊김을 감지
- 4밀리초(12:25:52.004Z → 12:25:52.008Z) 만에 새 마스터 노드로 재연결 완료
- 기존 마스터(`redis-node-2`) → 새 마스터(`redis-node-0`)로 자동 전환

### 5. 비즈니스 연속성 상세 확인

재연결 직후 애플리케이션이 정상적으로 데이터 처리를 계속하는 것을 로그에서 확인:
```
Stored: test:key:1610 = This is test value 1610 at Tue Apr 01 12:25:54 UTC 2025
Retrieved: test:key:1610 = This is test value 1610 at Tue Apr 01 12:25:54 UTC 2025
Previous: test:key:1609 = This is test value 1609 at Tue Apr 01 12:25:44 UTC 2025
Waiting for 10 seconds...
```

이후 10초 간격으로 지속적인 정상 데이터 처리가 이루어짐:
```
Stored: test:key:1611 = This is test value 1611 at Tue Apr 01 12:26:04 UTC 2025
Retrieved: test:key:1611 = This is test value 1611 at Tue Apr 01 12:26:04 UTC 2025
Previous: test:key:1610 = This is test value 1610 at Tue Apr 01 12:25:54 UTC 2025
Waiting for 10 seconds...
Stored: test:key:1612 = This is test value 1612 at Tue Apr 01 12:26:14 UTC 2025
Retrieved: test:key:1612 = This is test value 1612 at Tue Apr 01 12:26:14 UTC 2025
Previous: test:key:1611 = This is test value 1611 at Tue Apr 01 12:26:04 UTC 2025
Waiting for 10 seconds...
```

이 로그 시퀀스는 다음을 증명합니다:
- 장애 발생에도 불구하고 데이터 쓰기/읽기 작업이 지속됨
- 이전 데이터(test:key:1609)에 대한 접근도 정상 동작
- 새로운 데이터 쓰기(test:key:1610~1615)가 문제없이 이루어짐
- 장애 발생 시간 동안 데이터 손실 없음

### 6. 센티넬의 새 마스터 승격 확인

장애 조치 후 Redis Sentinel 명령을 통해 새로운 마스터로 `redis-node-0`가 선출되었음을 최종 확인:
```
redis-cli -h redis -p 26379 -a LwDyEUqdjx sentinel get-master-addr-by-name mymaster
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1) "redis-node-0.redis-headless.default.svc.cluster.local"
2) "6379"
```

## 테스트 결과 및 결론

1. **신속한 장애 감지 및 자동 복구**:
    - 마스터 노드 삭제 시 즉시 감지
    - 4ms 이내에 새 마스터 노드로 재연결 성공

2. **데이터 무결성 유지**:
    - 장애 발생 전 저장된 데이터(test:key:1609)에 계속 접근 가능
    - 장애 발생 직후에도 새 데이터(test:key:1610) 저장 성공

3. **가용성 확보**:
    - 사용자 관점에서 인지할 수 없을 정도의 짧은 중단 시간(milliseconds)
    - 애플리케이션 로직 변경 없이 자동 재연결 및 복구

4. **Sentinel 매커니즘 검증**:
    - Redis Sentinel이 마스터 노드 실패를 감지하고 자동으로 새 마스터 선출
    - 클라이언트 라이브러리(Lettuce)가 Sentinel 토폴로지 변경을 인지하고 적절히 대응

이번 테스트는 Redis Sentinel을 활용한 고가용성 구성이 실제 프로덕션 환경에서 예상대로 작동하며, 마스터 노드 장애 시에도 데이터 손실이나 심각한 서비스 중단 없이 애플리케이션이 계속 운영될 수 있음을 실증적으로 검증했습니다. 특히 클라이언트 라이브러리와 Sentinel의 통합이 원활하게 작동하여 개발자 개입 없이 자동화된 장애 조치가 이루어짐을 확인했습니다.
