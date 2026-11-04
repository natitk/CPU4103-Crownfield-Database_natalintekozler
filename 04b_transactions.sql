-- =====================================================
-- 04b_transactions.sql  (INDIVIDUAL - Part D, transactions)
-- Run AFTER 04_security.sql
--
-- Idea: booking an appointment and its follow-up plan must be ALL-OR-NOTHING.
-- If the follow-up plan is rejected (e.g. by the date trigger), the new
-- appointment must not stay behind. This is atomicity (the A in ACID).
-- =====================================================

USE CrownfieldHospital;

DROP PROCEDURE IF EXISTS BookAppointmentWithFollowUp;

DELIMITER $$

CREATE PROCEDURE BookAppointmentWithFollowUp(
    IN p_appointment_id VARCHAR(10),
    IN p_patient_id     VARCHAR(10),
    IN p_clinician_id   VARCHAR(10),
    IN p_clinic_id      VARCHAR(10),
    IN p_date           DATE,
    IN p_time           TIME,
    IN p_followup_id    VARCHAR(10),
    IN p_due_date       DATE,
    IN p_priority       VARCHAR(10)
)
BEGIN
    -- If ANY statement below fails: undo everything, then re-raise the error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO Appointments
        (AppointmentID, PatientID, ClinicianID, ClinicID, AppointmentDate, AppointmentTime)
    VALUES
        (p_appointment_id, p_patient_id, p_clinician_id, p_clinic_id, p_date, p_time);

    INSERT INTO FollowUpPlans
        (FollowUpID, AppointmentID, DueDate, Priority, FollowUpStatus, Notes)
    VALUES
        (p_followup_id, p_appointment_id, p_due_date, p_priority, 'Pending', 'Booked by procedure');

    COMMIT;
END$$

DELIMITER ;

-- The receptionist can book through the procedure without holding
-- INSERT rights on FollowUpPlans (the procedure runs with its owner's rights).
GRANT EXECUTE ON PROCEDURE CrownfieldHospital.BookAppointmentWithFollowUp TO 'role_receptionist';


-- =====================================================
-- DEMO A: FAILED booking -> ROLLBACK (run these two lines one at a time)
-- The follow-up due date (2026-11-01) is BEFORE the appointment date
-- (2026-12-01), so the trigger rejects it and the whole booking is undone.
-- =====================================================

-- CALL BookAppointmentWithFollowUp('A901','OP002','C002','CL001','2026-12-01','09:00:00','F901','2026-11-01','Routine');
-- Expected: Error 1644 - Follow-up due date cannot be before the appointment date

-- SELECT COUNT(*) AS A901_rows FROM Appointments WHERE AppointmentID = 'A901';
-- Expected: 0  (the appointment was rolled back with the failed follow-up)


-- =====================================================
-- DEMO B: SUCCESSFUL booking -> COMMIT (run these one at a time)
-- =====================================================

-- CALL BookAppointmentWithFollowUp('A902','OP002','C002','CL001','2026-12-01','09:00:00','F902','2026-12-29','Routine');

-- SELECT a.AppointmentID, a.AppointmentDate, f.FollowUpID, f.DueDate
-- FROM Appointments AS a
-- INNER JOIN FollowUpPlans AS f ON f.AppointmentID = a.AppointmentID
-- WHERE a.AppointmentID = 'A902';
-- Expected: 1 row (both inserts were committed together)


-- =====================================================
-- CLEANUP after Demo B, so the data returns to its original state
-- (delete the child row first, then the parent row - referential integrity)
-- =====================================================

-- DELETE FROM FollowUpPlans WHERE FollowUpID = 'F902';
-- DELETE FROM Appointments  WHERE AppointmentID = 'A902';
