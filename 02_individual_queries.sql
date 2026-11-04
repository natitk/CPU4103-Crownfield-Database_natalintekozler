-- =====================================================
-- 02_individual_queries.sql  (INDIVIDUAL - Part C, queries 1-4)
-- Run AFTER 01_schema.sql, 01b_group_data.sql and 01c_my_extra_data.sql
-- Queries 5 (stored procedure) and 6 (trigger) are in 03_procedure_and_trigger.sql
-- Run each query on its own (select it, then Execute).
-- =====================================================

USE CrownfieldHospital;

-- Q1 (GROUP BY + HAVING): Which clinicians have at least one High or Urgent
-- follow-up plan, and how many appointments do they have?
SELECT c.ClinicianName,
       COUNT(a.AppointmentID) AS TotalAppointments,
       SUM(f.Priority IN ('High','Urgent')) AS HighOrUrgentFollowUps
FROM Clinicians AS c
INNER JOIN Appointments AS a ON a.ClinicianID = c.ClinicianID
INNER JOIN FollowUpPlans AS f ON f.AppointmentID = a.AppointmentID
GROUP BY c.ClinicianID, c.ClinicianName
HAVING SUM(f.Priority IN ('High','Urgent')) >= 1
ORDER BY HighOrUrgentFollowUps DESC, c.ClinicianName;


-- Q2 (INNER JOIN, 7 tables): In October 2026, which patient was seen with which
-- diagnosis, by which clinician and specialty, at which clinic?
SELECT a.AppointmentDate,
       a.AppointmentTime,
       p.PatientName,
       d.DiagnosisName,
       c.ClinicianName,
       s.SpecialtyName,
       cl.ClinicName
FROM Appointments AS a
INNER JOIN Patients AS p ON p.PatientID = a.PatientID
INNER JOIN AppointmentDiagnoses AS ad ON ad.AppointmentID = a.AppointmentID
INNER JOIN Diagnoses AS d ON d.DiagnosisID = ad.DiagnosisID
INNER JOIN Clinicians AS c ON c.ClinicianID = a.ClinicianID
INNER JOIN Specialties AS s ON s.SpecialtyID = c.SpecialtyID
INNER JOIN Clinics AS cl ON cl.ClinicID = a.ClinicID
WHERE a.AppointmentDate BETWEEN '2026-10-01' AND '2026-10-31'
ORDER BY a.AppointmentDate, a.AppointmentTime;


-- Q3 (LEFT JOIN): Which registered patients have no appointment booked yet?
SELECT p.PatientID, p.PatientName, p.Postcode, a.AppointmentID
FROM Patients AS p
LEFT JOIN Appointments AS a ON a.PatientID = p.PatientID
WHERE a.AppointmentID IS NULL
ORDER BY p.PatientID;


-- Q4 (CTE + subquery): Which follow-up plans are scheduled further out than
-- the average follow-up interval?
WITH FollowUpGap AS (
    SELECT f.FollowUpID,
           p.PatientName,
           a.AppointmentDate,
           f.DueDate,
           f.Priority,
           DATEDIFF(f.DueDate, a.AppointmentDate) AS DaysUntilFollowUp
    FROM FollowUpPlans AS f
    INNER JOIN Appointments AS a ON a.AppointmentID = f.AppointmentID
    INNER JOIN Patients AS p ON p.PatientID = a.PatientID
)
SELECT FollowUpID, PatientName, AppointmentDate, DueDate, Priority, DaysUntilFollowUp
FROM FollowUpGap
WHERE DaysUntilFollowUp > (SELECT AVG(DaysUntilFollowUp) FROM FollowUpGap)
ORDER BY DaysUntilFollowUp DESC;
