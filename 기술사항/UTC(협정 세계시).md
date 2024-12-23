# UTC(Coordinated Universal Time, 협정 세계시)의 개념

### **1. UTC(협정 세계시) 정의**

1. 기본 개념

    - 국제 표준 시간 기준
    - 경도 0도(그리니치)를 기준으로 하는 시간
    - 모든 시간대의 기준점으로 사용
    - 일광절약시간(DST)의 영향을 받지 않음

2. 표기 방식

```
예시: 2024-01-01T00:00:00Z
- T: 날짜와 시간의 구분자
- Z: UTC 시간임을 나타내는 식별자 (Zulu time)
```

### **2. UTC와 로컬 시간의 관계**

1. 시간대 오프셋

```
서울(UTC+9)의 경우:
- UTC 00:00 = 서울 09:00
- 오프셋: +09:00

LA(UTC-8)의 경우:
- UTC 00:00 = LA 16:00 (전날)
- 오프셋: -08:00
```

2. 변환 예시

```
서울에서 시험 응시:
로컬시간: 2024-01-01 14:30:00 KST
UTC 시간: 2024-01-01 05:30:00Z

LA에서 시험 응시:
로컬시간: 2024-01-01 14:30:00 PST
UTC 시간: 2024-01-01 22:30:00Z
```

### **UTC 시간 처리 코드 예시**

```javascript
// 1. UTC 시간 구하기
const now = new Date()
const utcTime = now.toISOString() // "2024-01-01T00:00:00.000Z"
const utcTimestamp = now.getTime() // 1704067200000

// 2. 로컬 시간 구하기
const localTime = now.toLocaleString() // "2024. 1. 1. 오전 9:00:00"

// 3. 타임존 정보
const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone // "Asia/Seoul"
const offset = -now.getTimezoneOffset() / 60 // 9 (UTC+9)

// 4. UTC -> 로컬 시간 변환
const utcDate = new Date("2024-01-01T00:00:00Z")
const localDate = utcDate.toLocaleString() // "2024. 1. 1. 오전 9:00:00"

// 5. 로컬 -> UTC 변환
const localDate2 = new Date("2024-01-01 09:00:00")
const utcDate2 = localDate2.toISOString() // "2024-01-01T00:00:00.000Z"

// 6. 체류 시간 계산 (밀리초)
const startTime = new Date("2024-01-01T00:00:00Z")
const endTime = new Date("2024-01-01T00:05:30Z")
const duration = endTime - startTime // 330000 (5분 30초)
```

### **3. UTC 사용의 장점**

1. 시간 비교의 정확성

    - 서로 다른 시간대의 이벤트도 정확한 순서 비교 가능
    - 체류시간 계산의 정확성 보장
    - 시간대 변경에 영향받지 않음

2. 데이터 일관성
    - 모든 시간 정보를 단일 기준으로 저장
    - 시간대 변환이 필요할 때만 로컬 시간으로 변환
    - 일광절약시간 적용 여부와 무관

### **4. 실제 적용 예시**

1. 시험 시작 시각 처리

```
시험 시작: 한국 오전 10시

UTC 저장값: 2024-01-01T01:00:00Z

지역별 표시:
- 서울: 2024-01-01 10:00:00 KST
- LA: 2023-12-31 17:00:00 PST
- 런던: 2024-01-01 01:00:00 GMT
```

2. 체류시간 계산

```
문항 진입: 2024-01-01T01:00:00Z
문항 이탈: 2024-01-01T01:05:00Z
체류시간 = 5분

어느 지역에서 응시하더라도 동일한 체류시간 값 산출
```

### **5. 구현 시 고려사항**

1. 시간 정보 저장

    - UTC 시간은 필수로 저장
    - 로컬 시간과 타임존은 참조용으로 저장
    - 시간대 변환 정보 함께 보관

2. 데이터베이스 설정
    - 시간 필드는 UTC 기준으로 저장
    - 타임존 정보는 별도 필드로 관리
    - 시간 비교는 UTC 값으로 수행
