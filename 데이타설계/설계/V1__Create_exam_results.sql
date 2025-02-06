-- ENUM 타입들 (필요 시 변경/추가/삭제)
CREATE TYPE user_role AS ENUM ('EXAMINEE', 'PROCTOR', 'CHIEF_PROCTOR');
CREATE TYPE auth_type AS ENUM ('PASSWORD', 'ACCESS_KEY');
CREATE TYPE step_type AS ENUM ('LOGIN', 'SYSTEM_CHECK', 'CUSTOM', 'FACE_AUTH', 'EXAM', 'FINISH');
CREATE TYPE step_transition AS ENUM ('MANUAL', 'AUTO');
CREATE TYPE question_type AS ENUM ('MULTIPLE_CHOICE', 'SHORT_ANSWER');
CREATE TYPE participant_status AS ENUM ('IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE proctor_status AS ENUM ('WAITING', 'MONITORING', 'COMPLETED');
/* user_type 제거 (통합) */
CREATE TYPE auth_status AS ENUM ('UNAUTHENTICATED', 'AUTHENTICATED', 'EXPIRED');
CREATE TYPE event_type AS ENUM ('NAVIGATION', 'WARNING', 'SUBMISSION', 'CHEATING_DETECTED');
CREATE TYPE exam_progress_status AS ENUM ('PREPARING', 'IN_PROGRESS', 'PAUSED', 'COMPLETED');
CREATE TYPE misconduct_type AS ENUM ('FACE_MISSING', 'MULTIPLE_FACES', 'NOISE_DETECTED', 'SCREEN_SWITCH');
CREATE TYPE action_type AS ENUM ('WARNING', 'FORCE_SUBMISSION', 'EXAM_TERMINATION');

-- exam_users: user_type 대신 user_role만 사용
CREATE TABLE exam_users (
    user_id           SERIAL        PRIMARY KEY,
    user_name         VARCHAR(50)   UNIQUE NOT NULL,
    password_hash     VARCHAR(255),
    full_name         VARCHAR(100)  NOT NULL,
    email             VARCHAR(255)  UNIQUE NOT NULL,
    role              user_role     NOT NULL, -- EXAMINEE / PROCTOR / CHIEF_PROCTOR
    auth_type         auth_type     NOT NULL,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE exam_packages (
    exam_package_id   SERIAL        PRIMARY KEY,
    name              VARCHAR(100)  NOT NULL,
    description       TEXT,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE exam_papers (
    exam_paper_id     SERIAL        PRIMARY KEY,
    exam_package_id   INTEGER       NOT NULL,
    title             VARCHAR(200)  NOT NULL,
    duration_minutes  INTEGER       NOT NULL,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_papers_exam_packages
        FOREIGN KEY (exam_package_id) REFERENCES exam_packages(exam_package_id)
);

CREATE TABLE exam_plans (
    exam_plan_id      SERIAL        PRIMARY KEY,
    name              VARCHAR(200)  NOT NULL,
    start_time        TIMESTAMP     NOT NULL,
    end_time          TIMESTAMP     NOT NULL,
    exam_package_id   INTEGER       NOT NULL,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_plans_exam_packages
        FOREIGN KEY (exam_package_id) REFERENCES exam_packages(exam_package_id),
    CONSTRAINT ck_exam_plans_time CHECK (end_time > start_time)
);

CREATE TABLE exam_access_keys (
    exam_access_key_id  SERIAL      PRIMARY KEY,
    exam_plan_id        INTEGER     NOT NULL,
    user_id             INTEGER     NOT NULL,
    access_key          VARCHAR(100) UNIQUE NOT NULL,
    expires_at          TIMESTAMP,
    created_at          TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_access_keys_exam_plans
        FOREIGN KEY (exam_plan_id) REFERENCES exam_plans(exam_plan_id),
    CONSTRAINT fk_exam_access_keys_exam_users
        FOREIGN KEY (user_id) REFERENCES exam_users(user_id)
);

-- exam_scenarios: next_exam_scenario_id 제거
CREATE TABLE exam_scenarios (
    exam_scenario_id    SERIAL           PRIMARY KEY,
    exam_plan_id        INTEGER          NOT NULL,
    step_order          INTEGER          NOT NULL,
    step_type           step_type        NOT NULL,
    name                VARCHAR(100)     NOT NULL,
    duration_seconds    INTEGER,
    step_transition     step_transition  NOT NULL,
    created_at          TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_scenarios_exam_plans
        FOREIGN KEY (exam_plan_id) REFERENCES exam_plans(exam_plan_id),
    CONSTRAINT uq_exam_scenarios_order
        UNIQUE (exam_plan_id, step_order)
);

-- 시나리오 분기(1:N) 표현용 새 테이블
-- 한 시나리오에서 여러 시나리오로 갈 수 있음
CREATE TABLE exam_scenario_transitions (
    scenario_transition_id  SERIAL     PRIMARY KEY,
    from_exam_scenario_id   INTEGER    NOT NULL,
    to_exam_scenario_id     INTEGER    NOT NULL,
    condition_expr          TEXT,      -- 분기 조건(필요 시)
    created_at              TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_scenario_transitions_from
        FOREIGN KEY (from_exam_scenario_id) REFERENCES exam_scenarios(exam_scenario_id),
    CONSTRAINT fk_scenario_transitions_to
        FOREIGN KEY (to_exam_scenario_id) REFERENCES exam_scenarios(exam_scenario_id)
);

CREATE TABLE exam_scenario_metadata (
    exam_scenario_metadata_id SERIAL    PRIMARY KEY,
    exam_scenario_id          INTEGER   NOT NULL,
    key                       VARCHAR(50)  NOT NULL,
    value                     JSONB      NOT NULL,
    created_at                TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_scenario_metadata
        FOREIGN KEY (exam_scenario_id) REFERENCES exam_scenarios(exam_scenario_id),
    CONSTRAINT uq_exam_scenario_metadata_key
        UNIQUE (exam_scenario_id, key)
);

-- questions 테이블
-- SHORT_ANSWER용 correct_answer만 유지 (객관식은 question_options에서 관리)
CREATE TABLE questions (
    question_id       SERIAL          PRIMARY KEY,
    exam_paper_id     INTEGER         NOT NULL,
    question_type     question_type   NOT NULL,  -- MULTIPLE_CHOICE / SHORT_ANSWER
    text              TEXT            NOT NULL,  -- 실제 문제
    correct_answer    TEXT,                      -- 서술형(Short Answer)인 경우
    created_at        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_questions_exam_papers
        FOREIGN KEY (exam_paper_id) REFERENCES exam_papers(exam_paper_id)
);

-- 객관식 보기 (Multiple Choice) 관리 테이블
CREATE TABLE question_options (
    question_option_id  SERIAL    PRIMARY KEY,
    question_id         INTEGER   NOT NULL,
    option_label        VARCHAR(10),   -- 예: "A", "B", "1", ...
    option_text         TEXT,          -- 보기 내용
    is_correct          BOOLEAN        DEFAULT FALSE, -- 다중정답 가능
    created_at          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_question_options_questions
        FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- 그룹/그룹멤버
CREATE TABLE exam_groups (
    exam_group_id     SERIAL         PRIMARY KEY,
    name              VARCHAR(100)   NOT NULL,
    exam_plan_id      INTEGER        NOT NULL,
    created_at        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_groups_exam_plans
        FOREIGN KEY (exam_plan_id) REFERENCES exam_plans(exam_plan_id)
);

CREATE TABLE exam_group_members (
    exam_group_member_id  SERIAL       PRIMARY KEY,
    exam_group_id         INTEGER      NOT NULL,
    user_id               INTEGER      NOT NULL,
    group_role            user_role    NOT NULL,   -- EXAMINEE / PROCTOR / CHIEF_PROCTOR
    created_at            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_group_members_exam_groups
        FOREIGN KEY (exam_group_id) REFERENCES exam_groups(exam_group_id),
    CONSTRAINT fk_exam_group_members_exam_users
        FOREIGN KEY (user_id) REFERENCES exam_users(user_id),
    CONSTRAINT uq_exam_group_members_unique
        UNIQUE (exam_group_id, user_id)
);

CREATE TABLE exam_progresses (
    exam_progress_id   SERIAL                PRIMARY KEY,
    exam_plan_id       INTEGER               NOT NULL,
    status             exam_progress_status  NOT NULL DEFAULT 'PREPARING',
    created_at         TIMESTAMP             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP             NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_progresses_exam_plans
        FOREIGN KEY (exam_plan_id) REFERENCES exam_plans(exam_plan_id),
    CONSTRAINT uq_exam_progresses_exam_plan
        UNIQUE (exam_plan_id)
);

CREATE TABLE exam_participant_statuses (
    exam_participant_status_id  SERIAL             PRIMARY KEY,
    exam_plan_id                INTEGER            NOT NULL,
    user_id                     INTEGER            NOT NULL,
    current_exam_scenario_id    INTEGER,
    start_time                  TIMESTAMP          NOT NULL,
    end_time                    TIMESTAMP,
    status                      participant_status NOT NULL DEFAULT 'IN_PROGRESS',
    created_at                  TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_participant_statuses_exam_plans
        FOREIGN KEY (exam_plan_id) REFERENCES exam_plans(exam_plan_id),
    CONSTRAINT fk_exam_participant_statuses_exam_users
        FOREIGN KEY (user_id) REFERENCES exam_users(user_id),
    CONSTRAINT fk_exam_participant_statuses_exam_scenarios
        FOREIGN KEY (current_exam_scenario_id) REFERENCES exam_scenarios(exam_scenario_id)
);

CREATE TABLE exam_proctor_statuses (
    exam_proctor_status_id   SERIAL         PRIMARY KEY,
    proctor_id               INTEGER        NOT NULL,
    exam_group_id            INTEGER        NOT NULL,
    status                   proctor_status NOT NULL DEFAULT 'WAITING',
    start_time               TIMESTAMP      NOT NULL,
    end_time                 TIMESTAMP,
    created_at               TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_proctor_statuses_exam_users
        FOREIGN KEY (proctor_id) REFERENCES exam_users(user_id),
    CONSTRAINT fk_exam_proctor_statuses_exam_groups
        FOREIGN KEY (exam_group_id) REFERENCES exam_groups(exam_group_id)
);

CREATE TABLE exam_sessions (
    exam_session_id    SERIAL       PRIMARY KEY,
    user_id            INTEGER      NOT NULL,
    auth_status        auth_status  NOT NULL DEFAULT 'UNAUTHENTICATED',
    auth_token         VARCHAR(500),
    socket_session_id  VARCHAR(100),
    ip_address         inet,        -- VARCHAR(45) → inet로 변경
    user_agent         TEXT,
    last_activity      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at         TIMESTAMP    NOT NULL,
    created_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_sessions_exam_users
        FOREIGN KEY (user_id) REFERENCES exam_users(user_id)
);

CREATE TABLE exam_access_logs (
    exam_access_log_id  SERIAL      PRIMARY KEY,
    user_id             INTEGER     NOT NULL,
    -- user_type 제거 (중복 개념), 필요 시 exam_users.role 참조
    ip_address          inet        NOT NULL, -- VARCHAR(45) → inet
    user_agent          TEXT,
    login_time          TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logout_time         TIMESTAMP,
    exam_session_id     INTEGER,
    created_at          TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_access_logs_exam_users
        FOREIGN KEY (user_id) REFERENCES exam_users(user_id),
    CONSTRAINT fk_exam_access_logs_exam_sessions
        FOREIGN KEY (exam_session_id) REFERENCES exam_sessions(exam_session_id)
);

CREATE TABLE exam_participant_scenario_logs (
    exam_participant_scenario_log_id  SERIAL   PRIMARY KEY,
    exam_participant_status_id        INTEGER   NOT NULL,
    exam_scenario_id                  INTEGER   NOT NULL,
    entered_at                        TIMESTAMP NOT NULL,
    exited_at                         TIMESTAMP,
    elapsed_time_seconds              INTEGER,
    auto_transition                   BOOLEAN   NOT NULL DEFAULT FALSE,
    forced_exit                       BOOLEAN   NOT NULL DEFAULT FALSE,
    created_at                        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_participant_scenario_logs_status
        FOREIGN KEY (exam_participant_status_id) REFERENCES exam_participant_statuses(exam_participant_status_id),
    CONSTRAINT fk_exam_participant_scenario_logs_scenarios
        FOREIGN KEY (exam_scenario_id) REFERENCES exam_scenarios(exam_scenario_id)
);

CREATE TABLE exam_proctor_time_logs (
    exam_proctor_time_log_id      SERIAL      PRIMARY KEY,
    exam_plan_id                  INTEGER     NOT NULL,
    exam_scenario_id              INTEGER     NOT NULL,
    exam_group_id                 INTEGER,
    exam_participant_status_id    INTEGER,
    proctor_id                    INTEGER     NOT NULL,
    extra_time_minutes            INTEGER     NOT NULL,
    adjustment_reason             TEXT        NOT NULL,
    applied_at                    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_proctor_time_logs_exam_plans
        FOREIGN KEY (exam_plan_id) REFERENCES exam_plans(exam_plan_id),
    CONSTRAINT fk_exam_proctor_time_logs_exam_scenarios
        FOREIGN KEY (exam_scenario_id) REFERENCES exam_scenarios(exam_scenario_id),
    CONSTRAINT fk_exam_proctor_time_logs_exam_groups
        FOREIGN KEY (exam_group_id) REFERENCES exam_groups(exam_group_id),
    CONSTRAINT fk_exam_proctor_time_logs_participant_statuses
        FOREIGN KEY (exam_participant_status_id) REFERENCES exam_participant_statuses(exam_participant_status_id),
    CONSTRAINT fk_exam_proctor_time_logs_exam_users
        FOREIGN KEY (proctor_id) REFERENCES exam_users(user_id),
    CONSTRAINT ck_exam_proctor_time_logs_extra
        CHECK (extra_time_minutes > 0)
);

CREATE TABLE exam_event_logs (
    exam_event_log_id             SERIAL      PRIMARY KEY,
    exam_participant_status_id    INTEGER     NOT NULL,
    event_type                    event_type  NOT NULL,
    event_description             TEXT,
    event_timestamp               TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_event_logs_participant_statuses
        FOREIGN KEY (exam_participant_status_id) REFERENCES exam_participant_statuses(exam_participant_status_id)
);

CREATE TABLE exam_participant_responses (
    exam_participant_response_id  SERIAL         PRIMARY KEY,
    exam_participant_status_id    INTEGER         NOT NULL,
    question_id                   INTEGER         NOT NULL,
    response_text                 TEXT,
    is_correct                    BOOLEAN,
    score                         DECIMAL(5,2),
    submitted_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_participant_responses_status
        FOREIGN KEY (exam_participant_status_id) REFERENCES exam_participant_statuses(exam_participant_status_id),
    CONSTRAINT fk_exam_participant_responses_questions
        FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

CREATE TABLE exam_misconduct_logs (
    exam_misconduct_log_id        SERIAL          PRIMARY KEY,
    exam_participant_status_id    INTEGER         NOT NULL,
    detected_type                 misconduct_type NOT NULL,
    confidence_score              DECIMAL(4,3),
    log_timestamp                 TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_by_proctor_id        INTEGER,
    created_at                    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_misconduct_logs_participant_statuses
        FOREIGN KEY (exam_participant_status_id) REFERENCES exam_participant_statuses(exam_participant_status_id),
    CONSTRAINT fk_exam_misconduct_logs_exam_users
        FOREIGN KEY (reviewed_by_proctor_id) REFERENCES exam_users(user_id),
    CONSTRAINT ck_exam_misconduct_logs_confidence
        CHECK (confidence_score >= 0 AND confidence_score <= 1)
);

CREATE TABLE exam_proctor_misconduct_action_logs (
    exam_proctor_misconduct_action_log_id  SERIAL     PRIMARY KEY,
    exam_misconduct_log_id                 INTEGER    NOT NULL,
    proctor_id                             INTEGER    NOT NULL,
    action_type                            action_type NOT NULL,
    action_description                     TEXT        NOT NULL,
    action_timestamp                       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                             TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                             TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_proctor_misconduct_action_logs_misconduct_logs
        FOREIGN KEY (exam_misconduct_log_id) REFERENCES exam_misconduct_logs(exam_misconduct_log_id),
    CONSTRAINT fk_exam_proctor_misconduct_action_logs_exam_users
        FOREIGN KEY (proctor_id) REFERENCES exam_users(user_id)
);

CREATE TABLE exam_participant_time_logs (
    exam_participant_time_log_id     SERIAL      PRIMARY KEY,
    exam_participant_status_id       INTEGER     NOT NULL,
    exam_proctor_time_log_id         INTEGER     NOT NULL,
    exam_scenario_id                 INTEGER     NOT NULL,
    previous_end_time                TIMESTAMP   NOT NULL,
    new_end_time                     TIMESTAMP   NOT NULL,
    extra_time_minutes               INTEGER     NOT NULL,
    adjustment_reason                TEXT        NOT NULL,
    applied_at                       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at                       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exam_participant_time_logs_statuses
        FOREIGN KEY (exam_participant_status_id) REFERENCES exam_participant_statuses(exam_participant_status_id),
    CONSTRAINT fk_exam_participant_time_logs_proctor_time_logs
        FOREIGN KEY (exam_proctor_time_log_id) REFERENCES exam_proctor_time_logs(exam_proctor_time_log_id),
    CONSTRAINT fk_exam_participant_time_logs_exam_scenarios
        FOREIGN KEY (exam_scenario_id) REFERENCES exam_scenarios(exam_scenario_id),
    CONSTRAINT ck_exam_participant_time_logs_end_times
        CHECK (new_end_time > previous_end_time),
    CONSTRAINT ck_exam_participant_time_logs_extra
        CHECK (extra_time_minutes > 0)
);

