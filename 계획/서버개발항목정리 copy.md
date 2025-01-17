팀장님, 안녕하세요.  
아래는 **상세 기능 목록**(개발환경 구축, DB 설계, 웹서버, 소켓서버, Worker 계층 등)을 바탕으로 **전체 일정을 갱신**한 내용입니다.  
**문서 버전 V1.0** 기준이며, **최대 20일 이내** 완료를 목표로 작성했습니다.  
(투입 인력‧우선순위‧인프라 환경 등에 따라 실제 일정은 변동될 수 있습니다.)

---

## 1. 전체 일정 개요

| 순번 | 작업 내용                                                                          |    예상 기간    |
| :--: | :--------------------------------------------------------------------------------- | :-------------: |
|  1   | **개발환경 구축**                                                                  |      Day 1      |
|  2   | **데이터베이스(및 Redis) 설계**                                                    |      Day 2      |
|  3   | **웹서버 개발** <br>(인증, 관리서버 인터페이스, 공통 API, REST API, 모니터링 Push) |  Day 3 ~ Day 7  |
|  4   | **소켓서버 개발** <br>(연결/재연결, 큐서버 발행/구독, 메시지 브로드캐스트)         |  Day 8 ~ Day 9  |
|  5   | **상태관리/답지/부정행위/로그 관리(Worker) 개발**                                  | Day 10 ~ Day 14 |
|  6   | **통합 테스트 & 안정화**                                                           | Day 15 ~ Day 20 |

---

## 2. 상세 일정 및 작업 항목

### 2.1 Day 1: 개발환경 구축 (1일)

1. **개발 서버 구축**

    - 서버 OS(리눅스/윈도우 등) 설치 및 기본 설정
    - 필수 패키지(Git, 방화벽, Nginx/Apache 등) 설치

2. **데이터베이스 설치**

    - RDBMS(MySQL/MariaDB/PostgreSQL 등) 설치 및 기본 스키마 생성

3. **Redis 설치**

    - 캐시/세션/실시간 상태 저장용 Redis 설치
    - 보안 설정(비밀번호, Bind IP 등)

4. **큐 서버 설치**

    - 메시지 큐(RabbitMQ/Kafka/ActiveMQ 등) 설치
    - 기본 큐·Exchange 설정, 모니터링 플러그인 활성화(필요 시)

5. **프로젝트 구성**

    - **소켓서버 프로젝트** 초기 세팅 (Node.js, Python, Java 등)
    - **웹서버 프로젝트** 초기 세팅 (Spring Boot, Node.js, Django 등)

6. **개발환경 가이드 작성**
    - 폴더 구조, 브랜치 전략, CI/CD 구성 문서화

---

### 2.2 Day 2: 데이터베이스(및 Redis) 설계 (1일)

1. **DB 스키마 설계**

    - 시험(계획), 수험자, 감독관, 시험실, 부정행위, 로그, 답지 이력 등
    - PK/FK 설정, 인덱스 전략

2. **Redis 구조 설계**

    - **마스터 데이터**: 계획/수험자/감독관/시험실
    - **시행 데이터**: 계획상태, 수험자 상태, 소켓 상태, 시험실 상태, 부정행위 상태, 답지 상태 등
    - Key Naming Convention, 만료 정책(시험 종료 시점 등)

3. **문서화**
    - ERD 다이어그램 작성
    - Redis Key/Value 구조 및 Hash/Sorted Set 사용처 기재

---

### 2.3 Day 3 ~ Day 7: 웹서버 개발 (5일)

> **주요 기능**: 인증, 관리서버 인터페이스, 공통 API, REST API, 모니터링 Push 등

1. **인증**

    - 수험자 인증 로직(로그인/토큰 발급)
    - Redis 세션 or JWT 기반 권한 검증

2. **관리서버 인터페이스**

    - 시행정보 API (시험 계획/설정)
    - 시행상태 API (시험 진행 상태)
    - 시험결과 API (답안/채점/결과)

3. **공통 기능**

    - 파일 업로드/다운로드 API
    - 로그/에러 핸들링 구조

4. **REST API**

    - **계획정보 API**: 등록·수정·삭제·조회
    - **수험자정보/감독관정보/시험실정보 API**
    - **수험자 API**
        - 상태 변경/조회, 답지 등록/조회, 부정행위 등록/조회, 로그 등록/조회 등
    - **감독관 API**
        - 상태 조회/변경, 부정행위 등록/조회, 로그 등록/조회, 제어 등록/조회 등

5. **모니터링 Push** (Redis 연동)
    - 소켓상태, 서버상태, 시험실상태, 시험진행상태, 수험자/감독관 상태, 부정행위 상태 등록·변경

---

### 2.4 Day 8 ~ Day 9: 소켓서버 개발 (2일)

> **주요 기능**: 연결/재연결 관리, 큐서버 발행/구독, 메시지 개별 전송 및 브로드캐스트

1. **연결/재연결 관리**

    - WebSocket 라이프사이클(연결, 재연결, 종료) 핸들러
    - Heartbeat(Keep-Alive) 로직

2. **큐서버 발행/구독 서비스**

    - 소켓서버 -> 메시지 큐 발행
        - 예) 수험자 상태 변경, 부정행위 이벤트
    - 메시지 큐 -> 소켓서버 구독
        - Worker에서 발행된 상태 변경을 소켓서버가 받아서 브로드캐스트

3. **메시지 전송**
    - 개별(특정 수험자/감독관) 전송
    - 브로드캐스트(전체), 그룹(시험실 단위) 전송
    - Redis Pub/Sub 연동(필요 시)

---

### 2.5 Day 10 ~ Day 14: Worker 계층 개발 (5일)

> **주요 기능**: 상태관리(Queue Worker), 답지관리(Worker), 부정행위관리(Worker), 로그관리(Worker)

1. **상태관리(Queue Worker)**

    - 계획 상태 등록·변경 (Redis/RDB)
    - 수험자 상태 등록·변경 (Redis/RDB)
    - 감독관 상태 등록·변경 (Redis/RDB)
    - 시험실 상태 등록·변경 (Redis/RDB)
    - 모니터링 집계 등록·변경 (Redis/RDB)

2. **답지관리(Worker)**

    - 답지 상태 등록·변경 (Redis/RDB/File)
    - 답안 등록·변경 (Redis/RDB/File)
    - 답안 통계 집계 (Redis/RDB)

3. **부정행위관리(Worker)**

    - 부정행위 등록·변경 (Redis/RDB)
    - 부정행위 제어·처리 (Redis/RDB)
    - 부정행위 통계 집계 (Redis/RDB)

4. **로그관리(Worker)**
    - 시스템/수험자/감독관 로그 등록 (RDB)
    - 로그 통계 집계 (RDB)

---

### 2.6 Day 15 ~ Day 20: 통합 테스트 & 안정화 (6일)

1. **통합 테스트**

    - 웹서버 ↔ 소켓서버 ↔ 큐서버 ↔ Worker ↔ DB/Redis 전체 시나리오
    - 정상 흐름 + 장애(큐 지연, 서버 다운 등) 대응 테스트

2. **성능 테스트**

    - 메시지 큐 처리량, WebSocket 동시 접속, REST API 부하 테스트
    - Redis, DB 모니터링 및 튜닝

3. **안정화**
    - 버그 수정, 예외처리 보강
    - 보안(HTTPS/WSS, 인증/권한) 적용
    - 로그/모니터링 알람 강화
    - 배포 스크립트(CI/CD) 점검

---

## 3. 결론 및 참고

-   **일정 요약**

    -   Day 1: 개발환경 구축
    -   Day 2: DB/Redis 설계
    -   Day 3~7: 웹서버 개발
    -   Day 8~9: 소켓서버 개발
    -   Day 10~14: Worker(상태·답지·부정행위·로그) 개발
    -   Day 15~20: 통합 테스트 & 안정화

-   **병행 작업**: 일부 작업(웹서버와 Worker, 소켓서버 등)은 인원이 충분하거나 모듈 간 의존성이 낮으면 동시 진행 가능
-   **보안 및 확장성**: 요구사항에 맞춰 Redis 클러스터링, DB 이중화, 메시지 큐 분산 구성 등을 고려
-   **추가 기능**: AI 기반 부정행위 탐지(영상·음성 처리), 고도화된 시험 통계, 대용량 파일 업로드 전략 등은 별도 일정으로 확장 가능
