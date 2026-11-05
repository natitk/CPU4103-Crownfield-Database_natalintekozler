# CPU4 103 Introduction to Database: Crownfield Eye Hospital MySQL Database

**Student Name:** Natalin Tek Ozler
**Student ID:** G1438117
**Course:** CPU4 103 Introduction to Database

## Summative description

This repository contains the MySQL implementation for the Crownfield Eye Hospital
summative assessment. It holds my individual SQL work. The database was designed in
a group of three. The group shared the ER diagram, the normalised schema and the
data set. My own work is marked **INDIVIDUAL** below.

## Requirements

- MySQL Server 8.0.16 or later (CHECK constraints are enforced from 8.0.16).
- Tested on MySQL 8.0.46 with MySQL Workbench on Windows.
- A MySQL account that can create databases, users and roles (for example `root`).

## Repository structure and run order

Open each file in MySQL Workbench (`File > Open SQL Script`), select everything
(`Ctrl+A`) and press **Execute** (the first lightning icon). Run the files in this
order and wait for each one to finish before the next.

| Order | File | Owner | What it does |
|---|---|---|---|
| 1 | `01_schema.sql` | GROUP (shared) | Creates the database `CrownfieldHospital` and the 11 tables |
| 2 | `01b_group_data.sql` | GROUP (shared) | Loads the Appendix 1 data plus synthetic records |
| 3 | `01c_my_extra_data.sql` | INDIVIDUAL | Adds two test patients with no appointment (for the LEFT JOIN) |
| 4 | `02_individual_queries.sql` | INDIVIDUAL | Part C queries 1-4 |
| 5 | `03_procedure_and_trigger.sql` | INDIVIDUAL | Query 5 (stored procedure) and query 6 (triggers) |
| 6 | `04_security.sql` | INDIVIDUAL | Roles, privileges, demo users, salted password hashing |
| 7 | `04b_transactions.sql` | INDIVIDUAL | Atomic booking procedure (COMMIT / ROLLBACK) |
| - | `05_ERD.png` | GROUP (shared) | ER diagram (Crow's Foot notation) |

File 4 contains several queries. Run **one query at a time** (select it, then
Execute) to see each result.

## My individual contribution

| Part | Where |
|---|---|
| Part C: six queries (GROUP BY + HAVING, INNER JOIN, LEFT JOIN, CTE + subquery, stored procedure, trigger) | `02_individual_queries.sql`, `03_procedure_and_trigger.sql` |
| Part D: four roles and privileges, salted SHA-256 password hashing, secure-coding demo | `04_security.sql` |
| Part D: transaction with rollback | `04b_transactions.sql` |
| Extra test data and the `PatientAccounts` table (my own addition to the group design) | `01c_my_extra_data.sql`, `04_security.sql` |

## How to test the key features

- **Procedure:** `CALL GetClinicianSchedule('C001');` returns 3 rows.
  `CALL GetClinicianSchedule('C999');` raises "Unknown ClinicianID".
- **Trigger:** `UPDATE FollowUpPlans SET DueDate = '2026-01-01' WHERE FollowUpID = 'F001';`
  fails with error 1644 because the date is before the appointment date.
- **Transaction:** the demo calls are in the comments of `04b_transactions.sql`.
  A booking with a follow-up date before the appointment date is rolled back.
  After the successful demo booking, run the cleanup lines in the same file.
- **Roles:** `SHOW GRANTS FOR 'role_doctor';` (also `role_receptionist`, `role_patient`, `role_admin`).

## Demo accounts (teaching data only)

`crown_admin`, `dr_shah`, `recep_amy` and `amina` are demo users created by
`04_security.sql`. Their passwords are in that file and are for this assessment
only. Do not reuse them anywhere.

## Assumptions

- One appointment has one patient, one clinician and one clinic.
- An appointment has at most one follow-up plan and at most one prescription.
- A clinician has one main specialty.
- "None" in the original data means that no medicine was prescribed.
- Dose, route, frequency and duration were not given in Appendix 1, so they are NULL.
- Follow-up due dates are the appointment date plus the original interval.

## Use of generative AI

I used a generative AI tool (Claude, Anthropic) to explain concepts and to draft
some scripts, slides and text. I ran and tested every script myself and checked
the results. The full declaration is in the appendix of my report.
