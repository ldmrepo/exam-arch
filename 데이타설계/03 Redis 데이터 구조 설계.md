# Redis 데이터 구조 설계

## 1. 마스터 데이터

### 1.1 시험 계획 정보

```redis
# Hash - 시험 계획 정보
plan:{planId}:info
{
    "planName": "2024년 1회차 시험",
    "startDatetime": "2024-01-01T09:00:00Z",
    "endDatetime": "2024-01-01T12:00:00Z"
}

# Set - 시험별 그룹 목록
plan:{planId}:groups -> Set of groupIds
```

### 1.2 시험 단계 정보

```redis
# Hash - 시험 단계 정보
plan:{planId}:stage:{stageId}:info
{
    "stageName": "1교시",
    "timeLimit": 3600,
    "autoMoveYn": "Y",
    "testCode": "TEST001",
    "testTime": 60
}

# Set - 시험별 단계 목록
plan:{planId}:stages -> Set of stageIds
```

### 1.3 시험 그룹 정보

```redis
# Hash - 그룹 정보
plan:{planId}:group:{groupId}:info
{
    "groupName": "A그룹",
    "groupDesc": "이공계열",
    "startDatetime": "2024-01-01T09:00:00Z",
    "endDatetime": "2024-01-01T12:00:00Z"
}
```

### 1.4 감독관 정보

```redis
# Hash - 감독관 정보
plan:{planId}:supervisor:{supervisorId}:info
{
    "groupId": "group123",
    "supervisorName": "홍길동"
}

# Set - 그룹별 감독관 목록
plan:{planId}:group:{groupId}:supervisors -> Set of supervisorIds
```

### 1.5 수험자 정보

```redis
# Hash - 수험자 정보
plan:{planId}:examinee:{examineeId}:info
{
    "groupId": "group123",
    "examineeName": "김수험"
}

# Set - 그룹별 수험자 목록
plan:{planId}:group:{groupId}:examinees -> Set of examineeIds
```

## 2. 진행 데이터

### 2.0 소켓 세션 데이터

````redis
# Hash - 수험자 소켓 세션 정보
plan:{planId}:socket:examinee:{socketId}
{
    "examineeId": "E12345",
    "groupId": "G001",
    "connectionTime": "2024-01-01T09:00:00Z",
    "lastHeartbeat": "2024-01-01T09:05:00Z",
    "clientIp": "192.168.1.100",
    "deviceInfo": {
        "os": "Windows 10",
        "browser": "Chrome 120.0",
        "screenResolution": "1920x1080"
    }
}

# Hash - 감독관 소켓 세션 정보
plan:{planId}:socket:supervisor:{socketId}
{
    "supervisorId": "S12345",
    "groupId": "G001",
    "connectionTime": "2024-01-01T08:30:00Z",
    "lastHeartbeat": "2024-01-01T09:05:00Z",
    "clientIp": "192.168.1.200",
    "deviceInfo": {
        "os": "Windows 10",
        "browser": "Chrome 120.0",
        "screenResolution": "1920x1080"
    }
}

# Set - 수험자ID로 소켓ID 조회
plan:{planId}:examinee:{examineeId}:sockets -> Set of socketIds

# Set - 감독관ID로 소켓ID 조회
plan:{planId}:supervisor:{supervisorId}:sockets -> Set of socketIds

# Set - 그룹별 연결된 수험자 소켓
plan:{planId}:group:{groupId}:examinee:sockets -> Set of socketIds

# Set - 그룹별 연결된 감독관 소켓
plan:{planId}:group:{groupId}:supervisor:sockets -> Set of socketIds

# Sorted Set - 소켓 세션 하트비트 관리 (마지막 하트비트 시간으로 정렬)
plan:{planId}:socket:heartbeats -> ZSET of socketIds ordered by lastHeartbeat

### 2.1 시험 진행 정보
```redis
# Hash - 시험 진행 상태
plan:{planId}:progress
{
    "statusCode": "IN_PROGRESS"
}
````

### 2.2 그룹 진행 정보

```redis
# Hash - 그룹 진행 상태
plan:{planId}:group:{groupId}:progress
{
    "statusCode": "IN_PROGRESS",
    "assignedExamineeCnt": 100,
    "connectedExamineeCnt": 95,
    "submittedExamineeCnt": 30,
    "assignedSupervisorCnt": 5,
    "connectedSupervisorCnt": 5
}
```

### 2.3 감독관 진행 정보

```redis
# Hash - 감독관 진행 정보
plan:{planId}:supervisor:{supervisorId}:progress
{
    "connStatusCode": "CONNECTED",
    "ipAddr": "192.168.1.100",
    "browserInfo": "Chrome 120.0"
}
```

### 2.4 수험자 진행 정보

```redis
# Hash - 수험자 진행 정보
plan:{planId}:examinee:{examineeId}:progress
{
    "examStatusCode": "IN_PROGRESS",
    "connStatusCode": "CONNECTED",
    "ipAddr": "192.168.1.100",
    "browserInfo": "Chrome 120.0",
    "currentStageId": "stage1"
}
```

### 2.5 부정행위 정보

```redis
# List - 수험자별 부정행위 이력
plan:{planId}:examinee:{examineeId}:violations -> List of violations
[
    {
        "violationTypeCode": "SCREEN_SWITCH",
        "occurrenceDatetime": "2024-01-01T10:15:00Z"
    }
]
```

### 2.6 답안 정보

```redis
# Hash - 답안 정보
plan:{planId}:examinee:{examineeId}:answer:{questionId}
{
    "answerContent": "답안내용",
    "submitDatetime": "2024-01-01T10:30:00Z"
}
```

### 2.7 시스템 정보

```redis
# Hash - 서버별 상태 정보
plan:{planId}:server:{serverId}:status
{
    "serverType": "WEB",
    "statusCode": "RUNNING",
    "cpuUsage": 45.5,
    "memoryUsage": 60.2,
    "networkStatus": "GOOD"
}
```

### 2.8 모니터링 정보

```redis
# Hash - 모니터링 통계
plan:{planId}:monitoring
{
    "monitoringTime": "2024-01-01T10:00:00Z",
    "totalConnCnt": 1000,
    "groupConnCnt": {
        "group1": 500,
        "group2": 500
    },
    "serverLoadStatus": "NORMAL",
    "networkStatus": "GOOD",
    "errorCnt": 5,
    "violationCnt": 2
}
```

### 2.9 표준 메시지 정보

```redis
# Hash - 표준 메시지 정보
plan:{planId}:message:{messageId}:info
{
    "messageType": "USER_ACTION",
    "sourceType": "CLIENT",
    "category": "EXAM",
    "messageCode": "ANS_001",
    "messageName": "답안저장",
    "messageDesc": "답안 저장 메시지",
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
}
```

### 2.10 문항 풀이 정보

#### 2.10.1 답안 정보

```redis
# Hash - 상세 답안 정보
plan:{planId}:examinee:{examineeId}:answer:{questionId}:detail
{
    "answerType": "CHOICE",
    "answerValue": "2",
    "lastModified": "2024-01-01T10:30:00Z"
}
```

#### 2.10.2 답안 변경 이력

```redis
# List - 답안 변경 이력
plan:{planId}:examinee:{examineeId}:answer:{questionId}:history -> List of changes
[
    {
        "answerValue": "1",
        "timestamp": "2024-01-01T10:15:00Z",
        "duration": 300
    }
]
```

#### 2.10.3 문항 메타데이터

```redis
# Hash - 문항별 메타데이터
plan:{planId}:examinee:{examineeId}:question:{questionId}:meta
{
    "visits": 5,
    "totalDuration": 600,
    "effectiveDuration": 550,
    "firstVisit": "2024-01-01T09:10:00Z",
    "lastVisit": "2024-01-01T10:30:00Z",
    "clickCount": 10,
    "scrollCount": 15,
    "inputCount": 3
}
```

#### 2.10.4 풀이 통계

```redis
# Hash - 수험자별 풀이 통계
plan:{planId}:examinee:{examineeId}:solving:stats
{
    "totalQuestions": 50,
    "answeredQuestions": 45,
    "totalDuration": 7200,
    "effectiveDuration": 7000,
    "focusLostCount": 3,
    "pageScrolls": 100,
    "totalClicks": 200
}
```

## 3. TTL(Time To Live) 정책

-   세션 데이터: 30분
-   실시간 모니터링 데이터: 1시간
-   시험 진행 데이터: 해당 시험 종료 후 24시간
-   답안 및 메타데이터: 해당 시험 종료 후 72시간
-   통계 데이터: 해당 시험 종료 후 30일

## 4. 키 네이밍 규칙

-   최상위 구분자로 plan:{planId} 사용
-   하위 구조는 콜론(:)으로 구분
-   계층 구조: plan:{planId}:엔티티:식별자:속성
-   예시: plan:P001:group:G001:info
-   모든 키는 소문자 사용
-   복합 단어는 언더스코어(\_) 사용
