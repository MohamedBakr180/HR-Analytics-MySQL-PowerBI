-- ============================================================
-- TalentBridge Solutions — HR Analytics Views
-- Author: Mohamed Khaled
-- Tool: MySQL 8.0
-- Description: 4 analytical views powering the Power BI dashboards
--              covering attrition, recruitment, workforce planning,
--              and compensation & performance analysis
-- ============================================================

USE hr_analytics;

-- ------------------------------------------------------------
-- VIEW 1: Attrition Analysis
-- Purpose: Combines employee, department, job, and attrition
--          data into one flat table for attrition analysis.
--          Covers all 1,000 employees — active ones show NULL
--          in attrition columns, terminated ones show exit data.
-- Powers: Attrition & Retention dashboard
-- ------------------------------------------------------------
CREATE VIEW vw_attrition_analysis AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.gender,
    e.hire_date,
    e.status,
    e.employment_type,
    e.city,
    d.department_name,
    j.job_title,
    j.job_level,
    a.exit_date,
    a.exit_reason,
    a.exit_type,
    a.regrettable,
    a.rehire_eligible,
    a.years_of_service,
    a.exit_interview_done,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE())   AS tenure_years,
    TIMESTAMPDIFF(MONTH, e.hire_date, CURDATE())  AS tenure_months,
    YEAR(a.exit_date)                             AS exit_year,
    MONTH(a.exit_date)                            AS exit_month
FROM employees e
LEFT JOIN departments d  ON e.department_id = d.department_id
LEFT JOIN jobs j         ON e.job_id        = j.job_id
LEFT JOIN attrition a    ON e.employee_id   = a.employee_id;


-- ------------------------------------------------------------
-- VIEW 2: Recruitment Funnel
-- Purpose: Combines recruitment requisitions with candidate data.
--          Calculates hiring metrics per opening including
--          days to fill, hire rate, and pipeline counts.
--          Open requisitions use department avg fill time
--          instead of CURDATE() to avoid date inflation.
-- Powers: Recruitment & Hiring dashboard
-- ------------------------------------------------------------
CREATE VIEW vw_recruitment_funnel AS
SELECT
    r.requisition_id,
    r.open_date,
    r.close_date,
    r.status                                            AS requisition_status,
    r.positions_needed,
    r.filled_positions,
    r.source_channel                                    AS req_source_channel,
    d.department_name,
    j.job_title,
    j.job_level,
    e_mgr.first_name                                    AS hiring_manager_first,
    e_mgr.last_name                                     AS hiring_manager_last,
    CASE
        WHEN r.close_date IS NOT NULL
        THEN DATEDIFF(r.close_date, r.open_date)
        WHEN d.department_name = 'Engineering'      THEN 75
        WHEN d.department_name = 'Finance'          THEN 45
        WHEN d.department_name = 'Sales'            THEN 35
        WHEN d.department_name = 'Marketing'        THEN 32
        WHEN d.department_name = 'Customer Support' THEN 30
        WHEN d.department_name = 'Human Resources'  THEN 18
        ELSE 30
    END                                                 AS days_to_fill,
    COUNT(c.candidate_id)                               AS total_applicants,
    SUM(CASE WHEN c.outcome = 'Hired'    THEN 1 ELSE 0 END) AS hired_count,
    SUM(CASE WHEN c.outcome = 'Rejected' THEN 1 ELSE 0 END) AS rejected_count,
    SUM(CASE WHEN c.outcome = 'Withdrew' THEN 1 ELSE 0 END) AS withdrew_count,
    SUM(CASE WHEN c.stage  = 'Interview' THEN 1 ELSE 0 END) AS reached_interview,
    ROUND(
        SUM(CASE WHEN c.outcome = 'Hired' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(c.candidate_id), 0) * 100, 1
    )                                                   AS hire_rate_pct
FROM recruitment r
LEFT JOIN departments d       ON r.department_id      = d.department_id
LEFT JOIN jobs j              ON r.job_id             = j.job_id
LEFT JOIN employees e_mgr     ON r.hiring_manager_id  = e_mgr.employee_id
LEFT JOIN candidates c        ON r.requisition_id     = c.requisition_id
GROUP BY
    r.requisition_id, r.open_date, r.close_date, r.status,
    r.positions_needed, r.filled_positions, r.source_channel,
    d.department_name, j.job_title, j.job_level,
    e_mgr.first_name, e_mgr.last_name;


-- ------------------------------------------------------------
-- VIEW 3: Workforce Overview
-- Purpose: Complete snapshot of the ACTIVE workforce only.
--          Includes age groups, tenure bands, manager names,
--          and current salary. Terminated employees are
--          handled by vw_attrition_analysis instead.
-- Powers: Workforce Planning dashboard
-- ------------------------------------------------------------
CREATE VIEW vw_workforce_overview AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.gender,
    e.birth_date,
    e.hire_date,
    e.status,
    e.employment_type,
    e.city,
    e.country,
    d.department_name,
    j.job_title,
    j.job_level,
    j.min_salary,
    j.max_salary,
    CONCAT(m.first_name, ' ', m.last_name)            AS manager_name,
    TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE())      AS age,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE())       AS tenure_years,
    TIMESTAMPDIFF(MONTH, e.hire_date, CURDATE())      AS tenure_months,
    YEAR(e.hire_date)                                 AS hire_year,
    QUARTER(e.hire_date)                              AS hire_quarter,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()) < 30 THEN 'Under 30'
        WHEN TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()) < 40 THEN '30-39'
        WHEN TIMESTAMPDIFF(YEAR, e.birth_date, CURDATE()) < 50 THEN '40-49'
        ELSE '50+'
    END                                               AS age_group,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 1 THEN '0-1 year'
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 3 THEN '1-3 years'
        WHEN TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) < 5 THEN '3-5 years'
        ELSE '5+ years'
    END                                               AS tenure_band,
    s.salary_amount                                   AS current_salary
FROM employees e
LEFT JOIN departments d   ON e.department_id  = d.department_id
LEFT JOIN jobs j          ON e.job_id         = j.job_id
LEFT JOIN employees m     ON e.manager_id     = m.employee_id
LEFT JOIN salaries s      ON e.employee_id    = s.employee_id
                         AND s.end_date       IS NULL
WHERE e.status = 'Active';


-- ------------------------------------------------------------
-- VIEW 4: Compensation & Performance
-- Purpose: Cross-references every employee's current salary
--          with their job salary range and performance history.
--          Flags pay vs performance mismatches including
--          underpaid high performers and overpaid low performers.
-- Powers: Performance & Compensation dashboard
-- ------------------------------------------------------------
CREATE VIEW vw_compensation_performance AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.gender,
    e.hire_date,
    e.status,
    d.department_name,
    j.job_title,
    j.job_level,
    j.min_salary,
    j.max_salary,
    s.salary_amount                                     AS current_salary,
    ROUND(
        (s.salary_amount - j.min_salary)
        / NULLIF(j.max_salary - j.min_salary, 0) * 100, 1
    )                                                   AS salary_position_pct,
    CASE
        WHEN s.salary_amount < j.min_salary THEN 'Below Range'
        WHEN s.salary_amount > j.max_salary THEN 'Above Range'
        ELSE 'Within Range'
    END                                                 AS salary_range_status,
    ROUND(AVG(pr.rating), 2)                            AS avg_performance_rating,
    MAX(pr.rating)                                      AS highest_rating,
    MIN(pr.rating)                                      AS lowest_rating,
    COUNT(pr.review_id)                                 AS total_reviews,
    SUM(pr.goals_met)                                   AS goals_met_count,
    CASE
        WHEN ROUND(AVG(pr.rating), 2) >= 4.0 THEN 'High Performer'
        WHEN ROUND(AVG(pr.rating), 2) >= 3.0 THEN 'Meets Expectations'
        ELSE 'Needs Improvement'
    END                                                 AS performance_category,
    CASE
        WHEN ROUND(AVG(pr.rating), 2) >= 4.0
         AND s.salary_amount < (j.min_salary + (j.max_salary - j.min_salary) * 0.5)
        THEN 'Underpaid High Performer'
        WHEN ROUND(AVG(pr.rating), 2) < 3.0
         AND s.salary_amount > (j.min_salary + (j.max_salary - j.min_salary) * 0.5)
        THEN 'Overpaid Low Performer'
        ELSE 'Aligned'
    END                                                 AS pay_performance_flag,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE())         AS tenure_years
FROM employees e
LEFT JOIN departments d      ON e.department_id = d.department_id
LEFT JOIN jobs j             ON e.job_id        = j.job_id
LEFT JOIN salaries s         ON e.employee_id   = s.employee_id
                            AND s.end_date      IS NULL
LEFT JOIN performance_reviews pr ON e.employee_id = pr.employee_id
GROUP BY
    e.employee_id, e.first_name, e.last_name, e.gender,
    e.hire_date, e.status, d.department_name, j.job_title,
    j.job_level, j.min_salary, j.max_salary, s.salary_amount,
    e.manager_id;
