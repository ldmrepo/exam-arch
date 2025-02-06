## Step 1. 기본 엔터티 (의존성 없는 테이블)

```mermaid
erDiagram
    exam_users {
      SERIAL user_id PK
      VARCHAR user_name
      VARCHAR full_name
      VARCHAR email
      USER_ROLE role
      AUTH_TYPE auth_type
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    exam_packages {
      SERIAL exam_package_id PK
      VARCHAR name
      TEXT description
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
```

> **설명:**  
>
> - **exam_users**와 **exam_packages**는 다른 테이블에 의존하지 않는 기본 엔터티입니다.

---

## Step 2. 1차 종속 엔터티  

(예: 시험지, 시험 계획, 시험 접근 키 등)

```mermaid
erDiagram
    exam_packages ||--|{ exam_papers : "포함"
    exam_packages ||--|{ exam_plans : "소속"
    exam_plans ||--|{ exam_access_keys : "생성"
    exam_users ||--|{ exam_access_keys : "소유"

    exam_papers {
      SERIAL exam_paper_id PK
      INTEGER exam_package_id FK
      VARCHAR title
      INTEGER duration_minutes
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_plans {
      SERIAL exam_plan_id PK
      VARCHAR name
      TIMESTAMP start_time
      TIMESTAMP end_time
      INTEGER exam_package_id FK
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_access_keys {
      SERIAL exam_access_key_id PK
      INTEGER exam_plan_id FK
      INTEGER user_id FK
      VARCHAR access_key UK
      TIMESTAMP expires_at
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
```

> **설명:**  
>
> - **exam_papers**와 **exam_plans**는 **exam_packages**에 의존하며,  
> - **exam_access_keys**는 **exam_plans**와 **exam_users**를 참조합니다.

---

## Step 3. 시험 시나리오 및 문제 관련 엔터티

```mermaid
erDiagram
    exam_plans ||--|{ exam_scenarios : "구성"
    exam_scenarios ||--|{ exam_scenario_transitions : "분기"
    exam_scenarios ||--|{ exam_scenario_metadata : "메타데이터"
    
    exam_papers ||--|{ questions : "포함"
    questions ||--|{ question_options : "옵션"

    exam_scenarios {
      SERIAL exam_scenario_id PK
      INTEGER exam_plan_id FK
      INTEGER step_order
      STEP_TYPE step_type
      VARCHAR name
      INTEGER duration_seconds
      STEP_TRANSITION step_transition
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_scenario_transitions {
      SERIAL scenario_transition_id PK
      INTEGER from_scenario_id FK
      INTEGER to_scenario_id FK
      TEXT condition_expr
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_scenario_metadata {
      SERIAL exam_scenario_metadata_id PK
      INTEGER exam_scenario_id FK
      VARCHAR key
      JSONB value
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    questions {
      SERIAL question_id PK
      INTEGER exam_paper_id FK
      QUESTION_TYPE question_type
      TEXT text
      TEXT correct_answer
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    question_options {
      SERIAL question_option_id PK
      INTEGER question_id FK
      VARCHAR option_label
      TEXT option_text
      BOOLEAN is_correct
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
```

> **설명:**  
>
> - **exam_scenarios**는 **exam_plans**에 속하며,  
>   - 분기 정보는 **exam_scenario_transitions**로 관리하고,  
>   - 추가 정보는 **exam_scenario_metadata**에 저장합니다.  
> - **questions**는 **exam_papers**의 하위 항목이며,  
>   - 객관식 보기는 **question_options**로 관리됩니다.

---

## Step 4. 그룹, 진행 상태, 세션 및 로그 관련 엔터티

```mermaid
erDiagram
    exam_plans ||--|{ exam_groups : "소속"
    exam_groups ||--|{ exam_group_members : "구성"
    exam_plans ||--|{ exam_progresses : "진행"
    exam_plans ||--|{ exam_participant_statuses : "참여"
    exam_groups ||--|{ exam_proctor_statuses : "관리"
    
    exam_users ||--|{ exam_group_members : "멤버"
    exam_users ||--|{ exam_proctor_statuses : "감독"
    
    exam_groups {
      SERIAL exam_group_id PK
      VARCHAR name
      INTEGER exam_plan_id FK
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_group_members {
      SERIAL exam_group_member_id PK
      INTEGER exam_group_id FK
      INTEGER user_id FK
      USER_ROLE group_role
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_progresses {
      SERIAL exam_progress_id PK
      INTEGER exam_plan_id FK
      EXAM_PROGRESS_STATUS status
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_participant_statuses {
      SERIAL exam_participant_status_id PK
      INTEGER exam_plan_id FK
      INTEGER user_id FK
      INTEGER current_exam_scenario_id FK
      TIMESTAMP start_time
      TIMESTAMP end_time
      PARTICIPANT_STATUS status
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_proctor_statuses {
      SERIAL exam_proctor_status_id PK
      INTEGER proctor_id FK
      INTEGER exam_group_id FK
      PROCTOR_STATUS status
      TIMESTAMP start_time
      TIMESTAMP end_time
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_sessions {
      SERIAL exam_session_id PK
      INTEGER user_id FK
      AUTH_STATUS auth_status
      VARCHAR auth_token
      VARCHAR socket_session_id
      inet ip_address
      TEXT user_agent
      TIMESTAMP last_activity
      TIMESTAMP expires_at
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_access_logs {
      SERIAL exam_access_log_id PK
      INTEGER user_id FK
      inet ip_address
      TEXT user_agent
      TIMESTAMP login_time
      TIMESTAMP logout_time
      INTEGER exam_session_id FK
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_users ||--|{ exam_sessions : "소유"
    exam_users ||--|{ exam_access_logs : "로그 기록"
```

> **설명:**  
>
> - **exam_groups**와 **exam_group_members**는 시험 그룹 관련 정보를 관리하며,  
> - **exam_progresses**와 **exam_participant_statuses**는 시험 진행 및 수험자 상태를 나타냅니다.  
> - **exam_proctor_statuses**는 감독관의 상태를 기록합니다.  
> - **exam_sessions**와 **exam_access_logs**는 사용자 세션 및 접근 로그를 관리합니다.

---

## Step 5. 로그 및 응답, 부정행위 관련 엔터티

```mermaid
erDiagram
    exam_participant_statuses ||--|{ exam_participant_scenario_logs : "기록"
    exam_scenarios ||--|{ exam_participant_scenario_logs : "참조"
    
    exam_participant_statuses ||--|{ exam_participant_responses : "응답"
    questions ||--|{ exam_participant_responses : "응답"
    
    exam_participant_statuses ||--|{ exam_misconduct_logs : "부정행위"
    exam_users ||--|{ exam_misconduct_logs : "검토"
    
    exam_misconduct_logs ||--|{ exam_proctor_misconduct_action_logs : "조치"
    exam_users ||--|{ exam_proctor_misconduct_action_logs : "수행"
    
    exam_participant_statuses ||--|{ exam_participant_time_logs : "시간 조정"
    exam_proctor_time_logs ||--|{ exam_participant_time_logs : "참조"
    exam_scenarios ||--|{ exam_participant_time_logs : "참조"
    
    exam_event_logs {
      SERIAL exam_event_log_id PK
      INTEGER exam_participant_status_id FK
      EVENT_TYPE event_type
      TEXT event_description
      TIMESTAMP event_timestamp
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_participant_responses {
      SERIAL exam_participant_response_id PK
      INTEGER exam_participant_status_id FK
      INTEGER question_id FK
      TEXT response_text
      BOOLEAN is_correct
      DECIMAL score
      TIMESTAMP submitted_at
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_misconduct_logs {
      SERIAL exam_misconduct_log_id PK
      INTEGER exam_participant_status_id FK
      MISCONDUCT_TYPE detected_type
      DECIMAL confidence_score
      TIMESTAMP log_timestamp
      INTEGER reviewed_by_proctor_id FK
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_proctor_misconduct_action_logs {
      SERIAL exam_proctor_misconduct_action_log_id PK
      INTEGER exam_misconduct_log_id FK
      INTEGER proctor_id FK
      ACTION_TYPE action_type
      TEXT action_description
      TIMESTAMP action_timestamp
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_proctor_time_logs {
      SERIAL exam_proctor_time_log_id PK
      INTEGER exam_plan_id FK
      INTEGER exam_scenario_id FK
      INTEGER exam_group_id FK
      INTEGER exam_participant_status_id FK
      INTEGER proctor_id FK
      INTEGER extra_time_minutes
      TEXT adjustment_reason
      TIMESTAMP applied_at
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
    
    exam_participant_time_logs {
      SERIAL exam_participant_time_log_id PK
      INTEGER exam_participant_status_id FK
      INTEGER exam_proctor_time_log_id FK
      INTEGER exam_scenario_id FK
      TIMESTAMP previous_end_time
      TIMESTAMP new_end_time
      INTEGER extra_time_minutes
      TEXT adjustment_reason
      TIMESTAMP applied_at
      TIMESTAMP created_at
      TIMESTAMP updated_at
    }
```

> **설명:**  
>
> - **exam_participant_scenario_logs**는 수험자의 시나리오 이동을 기록합니다.  
> - **exam_participant_responses**는 수험자의 문제 응답을 저장합니다.  
> - **exam_misconduct_logs**와 **exam_proctor_misconduct_action_logs**는 부정행위 기록과 이에 대한 조치를 관리합니다.  
> - **exam_proctor_time_logs**와 **exam_participant_time_logs**는 감독관에 의한 시간 조정 내역을 기록합니다.  
> - **exam_event_logs** (코드에 포함되지 않은 경우 별도로 추가 가능)도 이벤트 발생 시각을 기록합니다.

---

