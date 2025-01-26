MSA 서비스 전체 구성을 다이어그램과 함께 설명하겠습니다.

```mermaid
graph TB
    subgraph Client Layer
        Web[Web Client]
        Mobile[Mobile Client]
        External[External API Client]
    end

    subgraph Gateway Layer
        Gateway[API Gateway]
        LoadBalancer[Load Balancer]
    end

    subgraph Service Layer
        Auth[Auth Service]
        User[User Service]
        Product[Product Service]
        Order[Order Service]
        Payment[Payment Service]
        Notification[Notification Service]
        Socket[WebSocket Service]
    end

    subgraph Message Layer
        Kafka[Kafka]
        Redis[Redis]
    end

    subgraph Storage Layer
        AuthDB[(Auth DB)]
        UserDB[(User DB)]
        ProductDB[(Product DB)]
        OrderDB[(Order DB)]
    end

    subgraph Monitoring
        ELK[ELK Stack]
        Prometheus[Prometheus]
        Grafana[Grafana]
    end

    Web & Mobile & External --> Gateway
    Gateway --> LoadBalancer
    LoadBalancer --> Auth & User & Product & Order & Payment & Notification & Socket
    Auth --> AuthDB
    User --> UserDB
    Product --> ProductDB
    Order --> OrderDB
    Order --> Kafka
    Payment --> Kafka
    Notification --> Redis
    Socket --> Redis

    Auth & User & Product & Order & Payment & Notification & Socket --> ELK
    ELK --> Prometheus
    Prometheus --> Grafana

    classDef client fill:#a7c7e7,stroke:#333
    classDef gateway fill:#ff9999,stroke:#333
    classDef service fill:#98fb98,stroke:#333
    classDef message fill:#dda0dd,stroke:#333
    classDef storage fill:#f0e68c,stroke:#333
    classDef monitoring fill:#ffa07a,stroke:#333

    class Web,Mobile,External client
    class Gateway,LoadBalancer gateway
    class Auth,User,Product,Order,Payment,Notification,Socket service
    class Kafka,Redis message
    class AuthDB,UserDB,ProductDB,OrderDB storage
    class ELK,Prometheus,Grafana monitoring
```
    
핵심 구성:

1. API Gateway (Spring Cloud Gateway)
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: auth-service
          uri: lb://auth-service
          predicates:
            - Path=/api/auth/**
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/users/**
```

2. Service Discovery (Eureka)
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: http://discovery:8761/eureka/
```

3. 서비스 간 통신 (Feign)
```java
@FeignClient(name = "user-service")
public interface UserServiceClient {
    @GetMapping("/api/users/{id}")
    UserDto getUser(@PathVariable("id") Long id);
}
```

4. 메시지 큐 (Kafka)
```java
@Service
public class OrderService {
    @Autowired
    private KafkaTemplate<String, Order> kafkaTemplate;

    public void createOrder(Order order) {
        kafkaTemplate.send("order-topic", order);
    }
}
```

5. 캐시 처리 (Redis)
```java
@Service
public class UserService {
    @Cacheable(value = "users", key = "#id")
    public User getUser(Long id) {
        return userRepository.findById(id);
    }
}
```

6. 모니터링 구성
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

Docker Compose 구성:
```yaml
version: '3'
services:
  gateway:
    image: gateway-service
    ports:
      - "8080:8080"
  auth:
    image: auth-service
    depends_on:
      - redis
      - mysql
  user:
    image: user-service
  kafka:
    image: confluentinc/cp-kafka
  redis:
    image: redis
  prometheus:
    image: prom/prometheus
  grafana:
    image: grafana/grafana
```
