package com.example.demo;

import com.example.demo.RedisService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.Date;

@SpringBootApplication
public class DemoApplication implements CommandLineRunner {

    private final RedisService redisService;

    public DemoApplication(RedisService redisService) {
        this.redisService = redisService;
    }

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println("Starting Redis operations test...");


        int counter = 0;

        while(true) {
            // 키 생성
            String key = "test:key:" + counter;
            String value = "This is test value " + counter + " at " + new Date();

            // Redis에 데이터 저장
            redisService.set(key, value);
            System.out.println("Stored: " + key + " = " + value);

            // Redis에서 데이터 조회
            String retrievedValue = redisService.get(key);
            System.out.println("Retrieved: " + key + " = " + retrievedValue);

            // 이전 카운터의 데이터 조회 (있는 경우)
            if (counter > 0) {
                String previousKey = "test:key:" + (counter - 1);
                String previousValue = redisService.get(previousKey);
                System.out.println("Previous: " + previousKey + " = " + previousValue);
            }

            // 카운터 증가
            counter++;

            // 간단한 통계 표시
            if (counter % 5 == 0) {
                System.out.println("=== Stats after " + counter + " operations ===");
                // 여기에 필요한 통계 로직을 추가할 수 있습니다
            }

            // 10초 대기
            System.out.println("Waiting for 10 seconds...");
            Thread.sleep(10000);
        }
    }
}