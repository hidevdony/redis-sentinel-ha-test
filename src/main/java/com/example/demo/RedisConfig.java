package com.example.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisPassword;
import org.springframework.data.redis.connection.RedisSentinelConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisConfig {

    @Value("${spring.data.redis.sentinel.master}")
    private String master;

    @Value("${spring.data.redis.sentinel.nodes}")
    private String nodes;

    @Value("${spring.data.redis.password}")
    private String password;

    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        RedisSentinelConfiguration sentinelConfig = new RedisSentinelConfiguration();
        sentinelConfig.master(master);

        for (String node : nodes.split(",")) {
            String[] parts = node.split(":");
            String host = parts[0];
            int port = Integer.parseInt(parts[1]);
            sentinelConfig.sentinel(host, port);
        }

        if (password != null && !password.isEmpty()) {
            System.out.println("password = " + password);
            // 마스터 노드에 비밀번호 설정
            sentinelConfig.setPassword(RedisPassword.of(password));

            // 센티널 노드에도 동일한 비밀번호 설정 (필요한 경우)
            sentinelConfig.setSentinelPassword(RedisPassword.of(password));
        }

        // Lettuce 클라이언트 옵션 설정 (필요한 경우)
        LettuceConnectionFactory factory = new LettuceConnectionFactory(sentinelConfig);
        factory.setDatabase(0); // 기본 데이터베이스 인덱스 설정
        factory.afterPropertiesSet(); // 속성 설정 후 초기화

        return factory;
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate() {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(redisConnectionFactory());
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.afterPropertiesSet();
        return template;
    }
}