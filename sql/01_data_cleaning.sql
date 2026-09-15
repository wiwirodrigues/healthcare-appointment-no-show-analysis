-- =======================================================
-- HEALTHCARE APPOINTMENT NO-SHOW ANALYSIS
-- 01 - DATA CLEANING
-- =======================================================

USE appointments;

-- Inspect the raw data
SELECT *
FROM appointments
LIMIT 10;

-- Standardize column names
ALTER TABLE appointments
CHANGE COLUMN Hipertension Hypertension INT,
CHANGE COLUMN Handcap Disability_count INT,
CHANGE COLUMN `No-show` No_show VARCHAR(3);

-- Inspect disability distribution
SELECT
    Disability_count,
    COUNT(*) AS total_patients
FROM appointments
GROUP BY Disability_count;

-- Inspect original date columns
SELECT
    ScheduledDay,
    AppointmentDay
FROM appointments
LIMIT 10;

-- Create clean date columns
ALTER TABLE appointments
ADD COLUMN scheduled_day_clean DATETIME,
ADD COLUMN appointment_day_clean DATE;

-- Convert date strings to proper date formats
SET SQL_SAFE_UPDATES = 0;

UPDATE appointments
SET
    scheduled_day_clean = STR_TO_DATE(
        REPLACE(REPLACE(ScheduledDay, 'T', ' '), 'Z', ''),
        '%Y-%m-%d %H:%i:%s'
    ),
    appointment_day_clean = STR_TO_DATE(
        REPLACE(REPLACE(AppointmentDay, 'T', ' '), 'Z', ''),
        '%Y-%m-%d %H:%i:%s'
    );

-- Verify date conversion
SELECT
    ScheduledDay,
    scheduled_day_clean,
    AppointmentDay,
    appointment_day_clean
FROM appointments
LIMIT 10;

-- Remove original text date columns
ALTER TABLE appointments
DROP COLUMN ScheduledDay,
DROP COLUMN AppointmentDay;

-- Rename cleaned columns
ALTER TABLE appointments
CHANGE COLUMN scheduled_day_clean ScheduledDay DATETIME,
CHANGE COLUMN appointment_day_clean AppointmentDay DATE;

-- Verify cleaned data
SELECT *
FROM appointments
LIMIT 10;

-- Check for invalid age values
SELECT
    MIN(Age),
    MAX(Age)
FROM appointments;

-- Remove invalid age
DELETE FROM appointments
WHERE Age = -1;

-- Create lead time variable
ALTER TABLE appointments
ADD COLUMN lead_time_days INT;

UPDATE appointments
SET lead_time_days = DATEDIFF(AppointmentDay, DATE(ScheduledDay));

-- Check lead time range
SELECT
    MIN(lead_time_days),
    MAX(lead_time_days)
FROM appointments;

-- Check for negative lead time
SELECT *
FROM appointments
WHERE lead_time_days < 0;

-- Remove invalid negative lead time
DELETE FROM appointments
WHERE lead_time_days < 0;
