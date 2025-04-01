### 테스트 조건

마스터 노드 1 
센티넬 노드 3

kubectl get pod
NAME                          READY   STATUS    RESTARTS      AGE
redis-demo-768f969556-rpz2l   1/1     Running   0             4h9m
redis-node-0                  2/2     Running   0             5h30m
redis-node-1                  2/2     Running   0             5h31m
redis-node-2                  2/2     Running   0             5h31m
redis-sentinel-tester         1/1     Running   4 (54m ago)   3h56m
redisinsight-0                1/1     Running   0             6h21m

redis 센티넬 정보 정리
redis-cli -h redis -p 26379 -a LwDyEUqdjx sentinel get-master-addr-by-name  mymaster 
redis-cli -h redis -p 26379 -a LwDyEUqdjx sentinel slaves  mymaster
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1)  1) "name"
2) "redis-node-0.redis-headless.default.svc.cluster.local:6379"
3) "ip"
4) "redis-node-0.redis-headless.default.svc.cluster.local"
5) "port"
6) "6379"
7) "runid"
8) "2808c66e439b909ceb365a6457f86217f8aca190"
9) "flags"
10) "slave"
11) "link-pending-commands"
12) "-2"
13) "link-refcount"
14) "1"
15) "last-ping-sent"
16) "0"
17) "last-ok-ping-reply"
18) "756"
19) "last-ping-reply"
20) "756"
21) "down-after-milliseconds"
22) "60000"
23) "info-refresh"
24) "3892"
25) "role-reported"
26) "slave"
27) "role-reported-time"
28) "19990533"
29) "master-link-down-time"
30) "0"
31) "master-link-status"
32) "ok"
33) "master-host"
34) "redis-node-2.redis-headless.default.svc.cluster.local"
35) "master-port"
36) "6379"
37) "slave-priority"
38) "100"
39) "slave-repl-offset"
40) "6079966"
41) "replica-announced"
42) "1"
2)  1) "name"
2) "redis-node-1.redis-headless.default.svc.cluster.local:6379"
3) "ip"
4) "redis-node-1.redis-headless.default.svc.cluster.local"
5) "port"
6) "6379"
7) "runid"
8) "957e73bf393e1cafe160eb7e79994433846d6c9f"
9) "flags"
10) "slave"
11) "link-pending-commands"
12) "0"
13) "link-refcount"
14) "1"
15) "last-ping-sent"
16) "0"
17) "last-ok-ping-reply"
18) "756"
19) "last-ping-reply"
20) "756"
21) "down-after-milliseconds"
22) "60000"
23) "info-refresh"
24) "8619"
25) "role-reported"
26) "slave"
27) "role-reported-time"
28) "20022002"
29) "master-link-down-time"
30) "0"
31) "master-link-status"
32) "ok"
33) "master-host"
34) "redis-node-2.redis-headless.default.svc.cluster.local"
35) "master-port"
36) "6379"
37) "slave-priority"
38) "100"
39) "slave-repl-offset"
40) "6078423"
41) "replica-announced"
42) "1"




### 마스터 노드 확인 및 Kill 진행 
```
redis-cli -h redis -p 26379 -a LwDyEUqdjx sentinel get-master-addr-by-name mymaster
# 3분간 마스터노드 슬립 
redis-cli -h redis -p 6379 -a LwDyEUqdjx DEBUG 180 &
```
### 이 시점에 redis-demo-768f969556-rpz2l 는 마스터 노드로 10초에 한번씩 데이터 입력 및 조회 수행




Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1) "redis-node-2.redis-headless.default.svc.cluster.local"
2) "6379"


### redis-cli sleep 3분
redis-cli -h redis -p 6379 -a LwDyEUqdjx DEBUG sleep 180 &
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
(error) ERR DEBUG command not allowed. If the enable-debug-command option is set to "local", you can run it from a local connection, otherwise you need to set this option in the configuration file, and then restart the server.
root@redis-sentinel-tester:/# ^C
root@redis-sentinel-tester:/# 


### 마스터 노드 삭제 처리
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

### 비즈니스 자동 변경 확인 
.
2025-04-01T12:25:52.004Z  INFO 1 --- [demo] [xecutorLoop-1-1] i.l.core.protocol.ConnectionWatchdog     : Reconnecting, last destination was redis-node-2.redis-headless.default.svc.cluster.local/10.42.0.53:6379
2025-04-01T12:25:52.008Z  INFO 1 --- [demo] [ioEventLoop-6-2] i.l.core.protocol.ReconnectionHandler    : Reconnected to redis-node-0.redis-headless.default.svc.cluster.local/<unresolved>:6379
Stored: test:key:1610 = This is test value 1610 at Tue Apr 01 12:25:54 UTC 2025
Retrieved: test:key:1610 = This is test value 1610 at Tue Apr 01 12:25:54 UTC 2025
Previous: test:key:1609 = This is test value 1609 at Tue Apr 01 12:25:44 UTC 2025
Waiting for 10 seconds...
Stored: test:key:1611 = This is test value 1611 at Tue Apr 01 12:26:04 UTC 2025
Retrieved: test:key:1611 = This is test value 1611 at Tue Apr 01 12:26:04 UTC 2025
Previous: test:key:1610 = This is test value 1610 at Tue Apr 01 12:25:54 UTC 2025
Waiting for 10 seconds...
Stored: test:key:1612 = This is test value 1612 at Tue Apr 01 12:26:14 UTC 2025
Retrieved: test:key:1612 = This is test value 1612 at Tue Apr 01 12:26:14 UTC 2025
Previous: test:key:1611 = This is test value 1611 at Tue Apr 01 12:26:04 UTC 2025
Waiting for 10 seconds...
Stored: test:key:1613 = This is test value 1613 at Tue Apr 01 12:26:24 UTC 2025
Retrieved: test:key:1613 = This is test value 1613 at Tue Apr 01 12:26:24 UTC 2025
Previous: test:key:1612 = This is test value 1612 at Tue Apr 01 12:26:14 UTC 2025
Waiting for 10 seconds...
Stored: test:key:1614 = This is test value 1614 at Tue Apr 01 12:26:34 UTC 2025
Retrieved: test:key:1614 = This is test value 1614 at Tue Apr 01 12:26:34 UTC 2025
Previous: test:key:1613 = This is test value 1613 at Tue Apr 01 12:26:24 UTC 2025
=== Stats after 1615 operations ===
Waiting for 10 seconds...
Stored: test:key:1615 = This is test value 1615 at Tue Apr 01 12:26:44 UTC 2025

### 마스터 노드로 0번으로 승격 확인 
redis-cli -h redis -p 26379 -a LwDyEUqdjx sentinel get-master-addr-by-name  mymaster
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
1) "redis-node-0.redis-headless.default.svc.cluster.local"
2) "6379"
   root@redis-sentinel-tester:/# 
