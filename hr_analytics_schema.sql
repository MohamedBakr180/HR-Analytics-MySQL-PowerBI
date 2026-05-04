-- ============================================================
-- TalentBridge Solutions — HR Analytics Database Schema
-- Author: Mohamed Khaled
-- Tools: MySQL 8.0
-- Description: HR Analytics database covering attrition,
--              recruitment, workforce planning, and compensation
-- ============================================================

CREATE DATABASE IF NOT EXISTS hr_analytics;
USE hr_analytics;

-- Departments table
CREATE TABLE departments (
    department_id   INT           NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(100)  NOT NULL,
    location        VARCHAR(100),
    manager_id      INT,
    PRIMARY KEY (department_id)
);

-- Jobs table
CREATE TABLE jobs (
    job_id          INT           NOT NULL AUTO_INCREMENT,
    job_title       VARCHAR(100)  NOT NULL,
    min_salary      DECIMAL(10,2) NOT NULL,
    max_salary      DECIMAL(10,2) NOT NULL,
    job_level       VARCHAR(20),
    PRIMARY KEY (job_id)
);

-- Employees table
CREATE TABLE employees (
    employee_id     INT           NOT NULL AUTO_INCREMENT,
    first_name      VARCHAR(50)   NOT NULL,
    last_name       VARCHAR(50)   NOT NULL,
    gender          VARCHAR(10),
    birth_date      DATE,
    hire_date       DATE          NOT NULL,
    email           VARCHAR(100)  UNIQUE,
    phone           VARCHAR(20),
    department_id   INT,
    job_id          INT,
    manager_id      INT,
    employment_type VARCHAR(20),
    status          VARCHAR(20)   DEFAULT 'Active',
    country         VARCHAR(50),
    city            VARCHAR(50),
    PRIMARY KEY (employee_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (job_id)        REFERENCES jobs(job_id),
    FOREIGN KEY (manager_id)    REFERENCES employees(employee_id)
);

-- Salaries table
CREATE TABLE salaries (
    salary_id       INT           NOT NULL AUTO_INCREMENT,
    employee_id     INT           NOT NULL,
    salary_amount   DECIMAL(10,2) NOT NULL,
    effective_date  DATE          NOT NULL,
    end_date        DATE,
    salary_type     VARCHAR(20)   DEFAULT 'Monthly',
    currency        VARCHAR(10)   DEFAULT 'USD',
    PRIMARY KEY (salary_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Performance reviews table
CREATE TABLE performance_reviews (
    review_id       INT           NOT NULL AUTO_INCREMENT,
    employee_id     INT           NOT NULL,
    review_date     DATE          NOT NULL,
    reviewer_id     INT,
    rating          DECIMAL(3,1)  NOT NULL,
    goals_met       TINYINT(1),
    comments        TEXT,
    review_period   VARCHAR(20),
    PRIMARY KEY (review_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (reviewer_id) REFERENCES employees(employee_id)
);

-- Attrition table
CREATE TABLE attrition (
    attrition_id        INT          NOT NULL AUTO_INCREMENT,
    employee_id         INT          NOT NULL,
    exit_date           DATE         NOT NULL,
    exit_reason         VARCHAR(100),
    exit_type           VARCHAR(50),
    exit_interview_done TINYINT(1)   DEFAULT 0,
    regrettable         TINYINT(1)   DEFAULT 0,
    rehire_eligible     TINYINT(1)   DEFAULT 1,
    years_of_service    DECIMAL(4,1),
    PRIMARY KEY (attrition_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Recruitment table
CREATE TABLE recruitment (
    requisition_id    INT          NOT NULL AUTO_INCREMENT,
    job_id            INT          NOT NULL,
    department_id     INT          NOT NULL,
    open_date         DATE         NOT NULL,
    close_date        DATE,
    status            VARCHAR(20)  DEFAULT 'Open',
    hiring_manager_id INT,
    recruiter_id      INT,
    positions_needed  INT          DEFAULT 1,
    filled_positions  INT          DEFAULT 0,
    source_channel    VARCHAR(50),
    PRIMARY KEY (requisition_id),
    FOREIGN KEY (job_id)            REFERENCES jobs(job_id),
    FOREIGN KEY (department_id)     REFERENCES departments(department_id),
    FOREIGN KEY (hiring_manager_id) REFERENCES employees(employee_id),
    FOREIGN KEY (recruiter_id)      REFERENCES employees(employee_id)
);

-- Candidates table
CREATE TABLE candidates (
    candidate_id      INT          NOT NULL AUTO_INCREMENT,
    requisition_id    INT          NOT NULL,
    first_name        VARCHAR(50)  NOT NULL,
    last_name         VARCHAR(50)  NOT NULL,
    email             VARCHAR(100),
    phone             VARCHAR(20),
    application_date  DATE         NOT NULL,
    source_channel    VARCHAR(50),
    stage             VARCHAR(50)  DEFAULT 'Applied',
    stage_date        DATE,
    outcome           VARCHAR(20),
    offer_amount      DECIMAL(10,2),
    hired_as_employee INT          DEFAULT 0,
    employee_id       INT,
    PRIMARY KEY (candidate_id),
    FOREIGN KEY (requisition_id) REFERENCES recruitment(requisition_id),
    FOREIGN KEY (employee_id)    REFERENCES employees(employee_id)
);