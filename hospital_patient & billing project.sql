

-- hospital patient visit&billing project 

-- 1. UPDATE OPERATIONS
-- 1.1 Increase paid_amount by 5% for Insurance payments
UPDATE hospital_visits
SET paid_amount = paid_amount * 1.05
WHERE payment_method = 'Insurance';

-- 1.2 Set age = NULL where age < 1
UPDATE hospital_visits
SET age = NULL
WHERE age < 1;

-- 2. DELETE OPERATIONS
-- 2.1 Delete records where billing_amount = 0
DELETE FROM hospital_visits
WHERE billing_amount = 0;

-- 2.2 Delete visits of manually marked invalid patients
UPDATE hospital_visits
SET patient_name = 'INVALID_PATIENT'
WHERE patient_id = 'PAT0001';

DELETE FROM hospital_visits
WHERE patient_name = 'INVALID_PATIENT';

-- 3.1 Total revenue, paid revenue, outstanding revenue
SELECT SUM(billing_amount) AS total_revenue,
    SUM(paid_amount) AS paid_revenue,
    SUM(billing_amount - paid_amount) AS outstanding_revenue
FROM hospital_visits;

-- 3.2 Revenue by doctor
SELECT doctor_name, SUM(billing_amount) AS revenue FROM hospital_visits
GROUP BY doctor_name
ORDER BY revenue DESC;

-- 3.3 Revenue by department
SELECT department, SUM(billing_amount) AS revenue FROM hospital_visits
GROUP BY department
ORDER BY revenue DESC;

-- 3.4 Top 10 patients by spending
SELECT patient_name, SUM(billing_amount) AS total_spent FROM hospital_visits
GROUP BY patient_name
ORDER BY total_spent DESC
LIMIT 10;
-- 4. GROUPING & FILTERING

-- 4.1 Monthly revenue trend
SELECT DATE_FORMAT(visit_date, '%Y-%m') AS month,
    SUM(billing_amount) AS monthly_revenue
FROM hospital_visits
GROUP BY DATE_FORMAT(visit_date, '%Y-%m')
ORDER BY month;

-- 4.2 Average billing per visit type
SELECT visit_type, AVG(billing_amount) AS avg_billing FROM hospital_visits
GROUP BY visit_type;

-- 4.3 Count of visits requiring follow-up
SELECT COUNT(*) AS followup_visits
FROM hospital_visits
WHERE follow_up_flag = 1;

-- 5. JOINS 
-- 5.1 Patient + doctor + department list
SELECT 
    p1.visit_id,
   p1.patient_name,
    p1.doctor_name,
    p1.department,
    p1.visit_date
FROM hospital_visits p1 JOIN hospital_visits p2 on p1.visit_id=p2.visit_id;

-- 5.2 Procedures 
SELECT visit_id,
    diagnosis_description AS procedure_name,
    billing_amount FROM hospital_visits;

-- 6. SUBQUERIES
-- 6.1 Patients whose visit count is above average
SELECT patient_name, COUNT(*) AS visit_count
FROM hospital_visits
GROUP BY patient_name
HAVING COUNT(*) >
       (SELECT AVG(cnt) FROM (SELECT COUNT(*) AS cnt 
		FROM hospital_visits 
		GROUP BY patient_name) t);

-- 6.2 Visits where billing > patient's own avg billing
SELECT * FROM hospital_visits h
 WHERE billing_amount > ( SELECT AVG(billing_amount)
    FROM hospital_visits
    WHERE patient_id = h.patient_id
);
-- 6.3 Doctors with revenue above avg doctor revenue
SELECT doctor_name, SUM(billing_amount) AS doctor_revenue FROM hospital_visits
GROUP BY doctor_name
HAVING SUM(billing_amount) > (
   SELECT AVG(dr_rev)
    FROM (
        SELECT SUM(billing_amount) AS dr_rev
        FROM hospital_visits
        GROUP BY doctor_name
    ) t
);

-- 7. WINDOW FUNCTIONS
-- 7.1 Running total of daily revenue
SELECT visit_date,
    SUM(billing_amount) OVER (ORDER BY visit_date) AS running_total_revenue FROM hospital_visits;

-- 7.2 Rank doctors by revenue
SELECT 
    doctor_name,
    SUM(billing_amount) AS revenue,
    RANK() OVER (ORDER BY SUM(billing_amount) DESC) AS doctor_rank FROM hospital_visits
GROUP BY doctor_name;

-- 7.3 Lag/Lead revenue per day
SELECT visit_date,
    SUM(billing_amount) AS daily_revenue,
    LAG(SUM(billing_amount)) OVER (ORDER BY visit_date) AS previous_day_revenue,
    LEAD(SUM(billing_amount)) OVER (ORDER BY visit_date) AS next_day_revenue FROM hospital_visits
GROUP BY visit_date
ORDER BY visit_date;

-- 8. VIEWS

-- Monthly_Billing_Summary view.
create view monthly_billing as 
select year(str_to_date(visit_date,'%d-%m-%Y')) as year, month(str_to_date(visit_date,'%d-%m-%Y')) as date, sum(billing_amount) as monthly_revenue
from hospital_visits
group by year(str_to_date(visit_date,'%d-%m-%Y'))
, month(str_to_date(visit_date,'%d-%m-%Y')) ;
select * from monthly_billing;

-- 8.2 Doctor Performance View
CREATE VIEW Doctor_Perf AS                          
SELECT
    doctor_name,
    COUNT(*) AS total_visits,
    SUM(billing_amount) AS total_revenue,
    AVG(billing_amount) AS avg_billing
FROM hospital_visits
GROUP BY doctor_name;
select * from Doctor_Perf;

-- 8.3 High Value Patients View
CREATE VIEW High_Value_Patients AS
SELECT *
FROM hospital_visits
WHERE billing_amount > 2000;
select * from High_Value_Patients;

-- 9. STORED PROCEDURES
-- 9.1 settle_payment
DELIMITER $$
CREATE PROCEDURE settle_pmt(IN p_visit_id VARCHAR(50), IN p_amount DECIMAL(10,2))
BEGIN
    UPDATE hospital_visits
    SET paid_amount = paid_amount + p_amount
    WHERE visit_id = p_visit_id;
END$$
DELIMITER ;

-- 9.2 add_followup
DELIMITER $$
CREATE PROCEDURE followup(IN p_visit_id VARCHAR(50))
BEGIN
    UPDATE hospital_visits
    SET follow_up_flag = 1
    WHERE visit_id = p_visit_id;
END$$
DELIMITER ;

-- 10. TRIGGERS
-- 10.1 Audit Log Table
CREATE TABLE IF NOT EXISTS auditlog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    visit_id VARCHAR(50),
    old_amount DECIMAL(10,2),
    new_amount DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
select * from auditlog;

-- 10.1 Trigger: Log billing updates
DELIMITER $$
CREATE TRIGGER billingupdate
BEFORE UPDATE ON hospital_visits
FOR EACH ROW
BEGIN
    IF OLD.billing_amount <> NEW.billing_amount THEN
        INSERT INTO audit_log(visit_id, old_amount, new_amount)
        VALUES (OLD.visit_id, OLD.billing_amount, NEW.billing_amount);
    END IF;
END$$
DELIMITER ;

-- 10.2 Trigger: Auto-calc outstanding_amount

ALTER TABLE hospital_visits
ADD outstanding_amount DECIMAL(10,2);

DELIMITER $$
CREATE TRIGGER compute_outstanding
BEFORE INSERT ON hospital_visits
FOR EACH ROW
BEGIN
    SET NEW.outstanding_amount = NEW.billing_amount - NEW.paid_amount;
END$$
DELIMITER ;
