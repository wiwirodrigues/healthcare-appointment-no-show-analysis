-- =======================================================
-- HEALTHCARE APPOINTMENT NO-SHOW ANALYSIS
-- 03 - PATIENT HISTORY & RISK ANALYSIS
-- =======================================================

USE appointments;

-- Track historical patient behavior using window functions
SELECT 
    PatientId,
    AppointmentID,
    AppointmentDay,
    No_show,
    COUNT(*) OVER (
        PARTITION BY PatientId
        ORDER BY AppointmentDay
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS Prior_appointments,
    SUM(
        CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END
    ) OVER (
        PARTITION BY PatientId
        ORDER BY AppointmentDay
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS Prior_no_shows
FROM appointments
ORDER BY PatientId, AppointmentDay;

-- Create a view for appointment risk analysis
CREATE OR REPLACE VIEW v_appointment_risk AS
WITH patient_history AS (
    SELECT 
        PatientId,
        AppointmentID,
        AppointmentDay,
        Neighbourhood,
        lead_time_days,
        SMS_received,
        Scholarship,
        No_show,
        COUNT(*) OVER (
            PARTITION BY PatientId
            ORDER BY AppointmentDay
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS Prior_appointments,
        SUM(
            CASE WHEN No_show = 'Yes' THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY PatientId
            ORDER BY AppointmentDay
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS Prior_no_shows
    FROM appointments
)
SELECT 
    PatientId,
    AppointmentID,
    AppointmentDay,
    Neighbourhood,
    lead_time_days,
    SMS_received,
    Scholarship,
    No_show,
    Prior_appointments,
    Prior_no_shows
FROM patient_history;

-- Inspect the view
SELECT *
FROM v_appointment_risk;

-- Basic lead-time risk tier
SELECT 
    PatientId,
    AppointmentID,
    AppointmentDay,
    Neighbourhood,
    lead_time_days,
    No_show,
    CASE 
        WHEN lead_time_days = 0 THEN 'New Patient - Monitor'
        WHEN lead_time_days >= 8 THEN 'High Risk'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_tier
FROM appointments;

-- Final dataset exported to Power BI
SELECT 
    PatientId,
    AppointmentID,
    AppointmentDay,
    Neighbourhood,
    lead_time_days,
    SMS_received,
    Scholarship,
    No_show,
    Prior_appointments,
    COALESCE(Prior_no_shows, 0) AS Prior_no_shows,
    CASE 
        WHEN Prior_appointments = 0 THEN 'New Patient - Monitor'
        WHEN (
            COALESCE(Prior_no_shows, 0) /
            NULLIF(Prior_appointments, 0)
        ) >= 0.5
        OR lead_time_days >= 8
            THEN 'High Risk'
        WHEN (
            COALESCE(Prior_no_shows, 0) /
            NULLIF(Prior_appointments, 0)
        ) >= 0.2
        OR lead_time_days BETWEEN 4 AND 7
            THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_tier
FROM v_appointment_risk;
