USE club_collab;

-- First, let's check what students and events we have
-- We'll add volunteer logs for existing students

-- Add volunteer logs with verified hours for students
-- Student 1: Alice Johnson (assuming Student_ID = 1)
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
VALUES 
(1, 1, 'Event Coordinator', 8.5, 1, '2025-05-01'),
(1, 2, 'Setup Team Lead', 6.0, 1, '2025-05-02'),
(1, 3, 'Registration Desk', 4.5, 1, '2025-05-03');

-- Student 2: Bob Smith
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
VALUES 
(2, 1, 'Technical Support', 7.0, 1, '2025-05-01'),
(2, 2, 'Audio/Visual Setup', 5.5, 1, '2025-05-02'),
(2, 3, 'Stage Manager', 6.0, 1, '2025-05-03');

-- Student 3: Carol Davis
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
VALUES 
(3, 1, 'Volunteer Coordinator', 9.0, 1, '2025-05-01'),
(3, 2, 'Logistics Manager', 7.5, 1, '2025-05-02');

-- Student 4: David Wilson
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
VALUES 
(4, 1, 'Marketing Team', 5.0, 1, '2025-05-01'),
(4, 3, 'Social Media Manager', 4.0, 1, '2025-05-03');

-- Student 5: Emma Brown
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
VALUES 
(5, 2, 'Hospitality Team', 6.5, 1, '2025-05-02'),
(5, 3, 'Guest Relations', 5.5, 1, '2025-05-03');

-- Student 6: Frank Miller
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
VALUES 
(6, 1, 'Security Team', 8.0, 1, '2025-05-01'),
(6, 2, 'Crowd Management', 7.0, 1, '2025-05-02'),
(6, 3, 'Safety Officer', 6.5, 1, '2025-05-03');

-- Student 7: Grace Lee
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date)
VALUES 
(7, 1, 'Photography Team', 4.5, 1, '2025-05-01'),
(7, 2, 'Documentation', 5.0, 1, '2025-05-02');

-- Add some memberships to link students to clubs
INSERT INTO Membership (Student_ID, Club_ID, Role, Join_Date)
VALUES 
(1, 1, 'Executive', '2025-01-15'),
(2, 1, 'Volunteer', '2025-01-20'),
(3, 2, 'Executive', '2025-01-18'),
(4, 2, 'Member', '2025-02-01'),
(5, 3, 'Volunteer', '2025-01-25'),
(6, 3, 'Executive', '2025-01-22'),
(7, 1, 'Member', '2025-02-05')
ON DUPLICATE KEY UPDATE Role=VALUES(Role);

-- Manually award some badges to show variety
-- Bronze badges (5 hours)
INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 1, Badge_ID, '2025-05-01', 5.0 FROM Badge WHERE Hours_Required = 5 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 2, Badge_ID, '2025-05-01', 5.0 FROM Badge WHERE Hours_Required = 5 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 3, Badge_ID, '2025-05-01', 5.0 FROM Badge WHERE Hours_Required = 5 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 6, Badge_ID, '2025-05-01', 5.0 FROM Badge WHERE Hours_Required = 5 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

-- Silver badges (10 hours)
INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 1, Badge_ID, '2025-05-02', 10.0 FROM Badge WHERE Hours_Required = 10 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 2, Badge_ID, '2025-05-02', 10.0 FROM Badge WHERE Hours_Required = 10 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 3, Badge_ID, '2025-05-02', 10.0 FROM Badge WHERE Hours_Required = 10 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 6, Badge_ID, '2025-05-02', 10.0 FROM Badge WHERE Hours_Required = 10 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

-- Gold badge (20 hours) - only for top volunteers
INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
SELECT 6, Badge_ID, '2025-05-03', 20.0 FROM Badge WHERE Hours_Required = 20 LIMIT 1
ON DUPLICATE KEY UPDATE Earned_Date=VALUES(Earned_Date);

-- Update club currency balances based on volunteer hours
-- This will be done automatically by triggers, but let's ensure clubs have some initial balance
UPDATE Club SET Currency_Balance = 0 WHERE Currency_Balance IS NULL;

-- Verify the data
SELECT 'Volunteer Logs Added:' AS Status, COUNT(*) AS Count FROM Volunteer_Log WHERE Verified_By IS NOT NULL;
SELECT 'Memberships Added:' AS Status, COUNT(*) AS Count FROM Membership;
SELECT 'Badges Awarded:' AS Status, COUNT(*) AS Count FROM Volunteer_Badge;
SELECT 'Leaderboard Entries:' AS Status, COUNT(*) AS Count FROM Volunteer_Leaderboard;
