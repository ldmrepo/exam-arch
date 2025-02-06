### **📌 Mermaid ERD 코드**

```mermaid
erDiagram

    %% 사용자 테이블
    user {
        int user_id PK "사용자 ID"
        varchar username "사용자 로그인 ID"
        varchar password_hash "비밀번호 (해시 저장)"
        varchar full_name "사용자 이름"
        varchar email "이메일"
        enum role "사용자 역할 (수험자, 감독관, 총괄감독관)"
        enum auth_type "인증 방식 (아이디/비번, 접속 키)"
    }

    exam_access_key {
        int exam_access_key_id PK "시험 접속 키 ID"
        int exam_plan_id FK "시험 계획 ID"
        int user_id FK "사용자 ID"
        varchar access_key "수험자별 시험 고유 접속 키"
        datetime created_at "키 생성 시간"
        datetime expires_at "키 만료 시간"
    }

    %% 시험 계획 및 진행 관련 테이블
    exam_plan {
        int exam_plan_id PK "시험 계획 ID"
        varchar exam_name "시험명"
        datetime start_datetime "시험 시작 일시"
        datetime end_datetime "시험 종료 일시"
        int exam_package_id FK "시험 패키지 ID"
    }

    exam_scenario {
        int exam_scenario_id PK "시험 시나리오 ID"
        int exam_plan_id FK "시험 계획 ID"
        int step_order "진행 단계 순서"
        enum step_type "단계 유형 (로그인, 시스템 점검, 시험 안내 등)"
        varchar step_name "단계명"
        int duration_seconds "단계 제한 시간 (초)"
        enum step_transition "이동 방식 (수동, 자동)"
        int next_exam_scenario_id FK "다음 단계 ID"
    }

    exam_scenario_metadata {
        int exam_scenario_metadata_id PK "시험 시나리오 추가 정보 ID"
        int exam_scenario_id FK "시험 시나리오 ID"
        varchar metadata_key "추가 정보 키"
        json metadata_value "추가 정보 값 (JSON)"
    }

    %% 시험 그룹 및 역할
    exam_group {
        int exam_group_id PK "시험 그룹 ID"
        varchar group_name "그룹명"
        int exam_plan_id FK "시험 계획 ID"
    }

    exam_group_member {
        int exam_group_member_id PK "시험 그룹 회원 ID"
        int exam_group_id FK "시험 그룹 ID"
        int user_id FK "사용자 ID"
        enum group_role "그룹 내 역할 (수험자, 감독관, 총괄감독관)"
    }

    %% 시험 패키지 및 문항 관리
    exam_package {
        int exam_package_id PK "시험 패키지 ID"
        varchar package_name "패키지명"
        text description "패키지 설명"
    }

    exam_paper {
        int exam_paper_id PK "시험지 ID"
        int exam_package_id FK "시험 패키지 ID"
        varchar paper_title "시험지 제목"
        int duration_minutes "시험 제한 시간 (분)"
    }

    question {
        int question_id PK "문항 ID"
        int exam_paper_id FK "시험지 ID"
        text question_text "문항 내용"
        enum question_type "문항 유형 (객관식, 주관식 등)"
        text correct_answer "정답"
    }

    %% 관계 설정
    user ||--o{ exam_access_key : "사용자 접속 키"
    user ||--o{ exam_group_member : "시험 그룹 가입"
    exam_plan ||--o{ exam_access_key : "시험별 접속 키"
    exam_plan ||--o{ exam_scenario : "시험 시나리오 포함"
    exam_plan ||--o{ exam_group : "시험 그룹 관리"
    exam_plan ||--|{ exam_package : "시험 패키지 연결"
    exam_scenario ||--o{ exam_scenario_metadata : "추가 정보 저장"
    exam_group ||--o{ exam_group_member : "그룹 내 사용자"
    exam_package ||--o{ exam_paper : "시험지 포함"
    exam_paper ||--o{ question : "문항 포함"

```

---

### **📌 ERD 설명**

1. **사용자(`user`)**
   - `exam_access_key`와 연결 (시험별 접속 키 제공)
   - `exam_group_member`와 연결 (시험 그룹 내 사용자 관리)

2. **시험 계획(`exam_plan`)**
   - `exam_access_key`와 연결 (시험별 고유 접속 키)
   - `exam_scenario`와 연결 (시험 진행 단계)
   - `exam_group`과 연결 (시험 그룹 포함)
   - `exam_package`와 연결 (시험 패키지 사용)

3. **시험 진행(`exam_scenario`)**
   - `exam_scenario_metadata`와 연결 (추가 메타데이터 저장)

4. **시험 그룹(`exam_group`)**
   - `exam_group_member`와 연결 (시험 그룹 내 사용자)

5. **시험 패키지(`exam_package`)**
   - `exam_paper`와 연결 (시험지 포함)
   - `question`과 연결 (문항 포함)
