-- ============================================
-- CLUB COLLABORATION PLATFORM
-- COMPLETE DATABASE SETUP
-- ============================================
-- This file contains everything in one place:
-- 1. Database & Tables
-- 2. Triggers (8 triggers + 1 scheduled event)
-- 3. Views (11 pre-built reports)
-- 4. Stored Procedures (6 analytics queries)
-- 5. Sample Data (20 badges, 7 students, etc.)
-- ============================================

-- ============================================
-- PART 1: DATABASE & TABLES
-- ============================================

CREATE DATABASE IF NOT EXISTS club_collab;
USE club_collab;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Volunteer_Badge;
DROP TABLE IF EXISTS Badge;
DROP TABLE IF EXISTS Phone_Numbers;
DROP TABLE IF EXISTS Contact_Emails;
DROP TABLE IF EXISTS Volunteer_Log;
DROP TABLE IF EXISTS Collaboration;
DROP TABLE IF EXISTS Resource_Booking;
DROP TABLE IF EXISTS Maintenance_Log;
DROP TABLE IF EXISTS Equipment;
DROP TABLE IF EXISTS Event;
DROP TABLE IF EXISTS Membership;
DROP TABLE IF EXISTS Club_Executive;
DROP TABLE IF EXISTS General_Student;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Club;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Club (
    Club_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Department VARCHAR(100) NOT NULL,
    Office_Room VARCHAR(50),
    Founded_Date DATE,
    CONSTRAINT chk_club_name CHECK (LENGTH(Name) > 0)
);

CREATE TABLE Student (
    Student_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Street VARCHAR(200),
    City VARCHAR(50),
    Zip VARCHAR(10),
    Contact_No VARCHAR(20),
    CONSTRAINT chk_email CHECK (Email LIKE '%@%'),
    CONSTRAINT chk_student_name CHECK (LENGTH(Name) > 0)
);

CREATE TABLE General_Student (
    Student_ID INT PRIMARY KEY,
    Year_of_Study INT NOT NULL,
    Major VARCHAR(100) NOT NULL,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    CONSTRAINT chk_year CHECK (Year_of_Study BETWEEN 1 AND 4)
);

CREATE TABLE Club_Executive (
    Student_ID INT PRIMARY KEY,
    Position VARCHAR(50) NOT NULL,
    Term_Start DATE NOT NULL,
    Term_End DATE,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    CONSTRAINT chk_term CHECK (Term_End IS NULL OR Term_End > Term_Start)
);

CREATE TABLE Contact_Emails (
    Club_ID INT NOT NULL,
    Email VARCHAR(100) NOT NULL,
    PRIMARY KEY (Club_ID, Email),
    FOREIGN KEY (Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE,
    CONSTRAINT chk_contact_email CHECK (Email LIKE '%@%')
);

CREATE TABLE Phone_Numbers (
    Student_ID INT NOT NULL,
    Phone_Number VARCHAR(20) NOT NULL,
    PRIMARY KEY (Student_ID, Phone_Number),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    CONSTRAINT chk_phone CHECK (LENGTH(Phone_Number) >= 10)
);

CREATE TABLE Membership (
    Member_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT NOT NULL,
    Club_ID INT NOT NULL,
    Role VARCHAR(50) NOT NULL,
    Join_Date DATE NOT NULL,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE,
    CONSTRAINT chk_role CHECK (Role IN ('Member', 'Volunteer', 'Executive', 'Advisor')),
    UNIQUE (Student_ID, Club_ID)
);

CREATE TABLE Equipment (
    Equip_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Type VARCHAR(50) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Available',
    Owner_Club_ID INT NOT NULL,
    Purchase_Date DATE,
    FOREIGN KEY (Owner_Club_ID) REFERENCES Club(Club_ID) ON DELETE RESTRICT,
    CONSTRAINT chk_status CHECK (Status IN ('Available', 'In-Use', 'Damaged', 'Maintenance')),
    CONSTRAINT chk_equip_type CHECK (Type IN ('Camera', 'Projector', 'Microphone', 'Laptop', 'Speaker', 'Other'))
);

CREATE TABLE Maintenance_Log (
    Equip_ID INT NOT NULL,
    Log_ID INT NOT NULL,
    Date DATE NOT NULL,
    Description TEXT NOT NULL,
    Cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (Equip_ID, Log_ID),
    FOREIGN KEY (Equip_ID) REFERENCES Equipment(Equip_ID) ON DELETE CASCADE,
    CONSTRAINT chk_cost CHECK (Cost >= 0)
);

CREATE TABLE Event (
    Event_ID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(200) NOT NULL,
    Date DATE NOT NULL,
    Venue VARCHAR(200) NOT NULL,
    Primary_Club_ID INT NOT NULL,
    Description TEXT,
    FOREIGN KEY (Primary_Club_ID) REFERENCES Club(Club_ID) ON DELETE RESTRICT,
    CONSTRAINT chk_title CHECK (LENGTH(Title) > 0)
);

CREATE TABLE Collaboration (
    Event_ID INT NOT NULL,
    Partner_Club_ID INT NOT NULL,
    Contribution_Type VARCHAR(100),
    PRIMARY KEY (Event_ID, Partner_Club_ID),
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    FOREIGN KEY (Partner_Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE
);

CREATE TABLE Resource_Booking (
    Booking_ID INT PRIMARY KEY AUTO_INCREMENT,
    Equip_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    Borrow_Time DATETIME NOT NULL,
    Return_Time DATETIME NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Confirmed',
    FOREIGN KEY (Equip_ID) REFERENCES Equipment(Equip_ID) ON DELETE RESTRICT,
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    CONSTRAINT chk_booking_time CHECK (Return_Time > Borrow_Time),
    CONSTRAINT chk_booking_status CHECK (Status IN ('Confirmed', 'Completed', 'Cancelled'))
);

CREATE TABLE Volunteer_Log (
    Log_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    Role VARCHAR(100) NOT NULL,
    Hours_Worked DECIMAL(5, 2) NOT NULL,
    Verified_By INT,
    Verification_Date DATE,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    FOREIGN KEY (Verified_By) REFERENCES Club_Executive(Student_ID) ON DELETE SET NULL,
    CONSTRAINT chk_hours CHECK (Hours_Worked > 0 AND Hours_Worked <= 24),
    CONSTRAINT chk_role_length CHECK (LENGTH(Role) > 0)
);

CREATE TABLE Badge (
    Badge_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT NOT NULL,
    Icon VARCHAR(50) NOT NULL,
    Color VARCHAR(20) NOT NULL,
    Hours_Required DECIMAL(5, 2) NOT NULL,
    Tier VARCHAR(20) NOT NULL,
    CONSTRAINT chk_tier CHECK (Tier IN ('Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond')),
    CONSTRAINT chk_hours_required CHECK (Hours_Required >= 0)
);

CREATE TABLE Volunteer_Badge (
    Student_ID INT NOT NULL,
    Badge_ID INT NOT NULL,
    Earned_Date DATE NOT NULL,
    Total_Hours_At_Earning DECIMAL(6, 2) NOT NULL,
    PRIMARY KEY (Student_ID, Badge_ID),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Badge_ID) REFERENCES Badge(Badge_ID) ON DELETE CASCADE,
    CONSTRAINT chk_total_hours CHECK (Total_Hours_At_Earning >= 0)
);

-- ============================================
-- PART 2: TRIGGERS & SCHEDULED EVENTS
-- ============================================

DELIMITER //

-- 1. Prevent double-booking conflicts (INSERT)
DROP TRIGGER IF EXISTS prevent_double_booking//
CREATE TRIGGER prevent_double_booking
BEFORE INSERT ON Resource_Booking
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT;
    DECLARE equip_status VARCHAR(20);
    
    SELECT Status INTO equip_status FROM Equipment WHERE Equip_ID = NEW.Equip_ID;
    
    IF equip_status IN ('Damaged', 'Maintenance') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot book equipment that is Damaged or under Maintenance.';
    END IF;
    
    SELECT COUNT(*) INTO conflict_count
    FROM Resource_Booking
    WHERE Equip_ID = NEW.Equip_ID
      AND Status = 'Confirmed'
      AND (NEW.Borrow_Time < Return_Time AND NEW.Return_Time > Borrow_Time);
      
    IF conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Double-booking conflict detected. Equipment is already booked for this time slot.';
    END IF;
END//

-- 2. Prevent double-booking conflicts (UPDATE)
DROP TRIGGER IF EXISTS prevent_double_booking_update//
CREATE TRIGGER prevent_double_booking_update
BEFORE UPDATE ON Resource_Booking
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT;
    DECLARE equip_status VARCHAR(20);
    
    IF NEW.Status = 'Confirmed' THEN
        SELECT Status INTO equip_status FROM Equipment WHERE Equip_ID = NEW.Equip_ID;
        
        IF equip_status IN ('Damaged', 'Maintenance') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot confirm booking for equipment that is Damaged or under Maintenance.';
        END IF;
        
        SELECT COUNT(*) INTO conflict_count
        FROM Resource_Booking
        WHERE Equip_ID = NEW.Equip_ID
          AND Booking_ID != NEW.Booking_ID
          AND Status = 'Confirmed'
          AND (NEW.Borrow_Time < Return_Time AND NEW.Return_Time > Borrow_Time);
          
        IF conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Double-booking conflict detected. Equipment is already booked for this time slot.';
        END IF;
    END IF;
END//

-- 3. Automatic cancellation when equipment is damaged
DROP TRIGGER IF EXISTS cancel_bookings_on_damage//
CREATE TRIGGER cancel_bookings_on_damage
AFTER UPDATE ON Equipment
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Damaged' AND OLD.Status != 'Damaged' THEN
        UPDATE Resource_Booking
        SET Status = 'Cancelled'
        WHERE Equip_ID = NEW.Equip_ID
          AND Status = 'Confirmed'
          AND Return_Time > NOW();
    END IF;
END//

-- 4. Prevent logging hours for future events
DROP TRIGGER IF EXISTS validate_volunteer_event_date//
CREATE TRIGGER validate_volunteer_event_date
BEFORE INSERT ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE event_date DATE;
    SELECT Date INTO event_date FROM Event WHERE Event_ID = NEW.Event_ID;
    
    IF event_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot log volunteer hours for future events.';
    END IF;
END//

-- 5. Validate volunteer hours on update
DROP TRIGGER IF EXISTS validate_volunteer_event_date_update//
CREATE TRIGGER validate_volunteer_event_date_update
BEFORE UPDATE ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE event_date DATE;
    SELECT Date INTO event_date FROM Event WHERE Event_ID = NEW.Event_ID;
    
    IF event_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot log volunteer hours for future events.';
    END IF;
END//

-- 6. Auto-award badges when volunteer hours are logged (INSERT)
DROP TRIGGER IF EXISTS auto_award_badges_insert//
CREATE TRIGGER auto_award_badges_insert
AFTER INSERT ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE total_hours DECIMAL(6,2);
    
    SELECT COALESCE(SUM(Hours_Worked), 0) INTO total_hours
    FROM Volunteer_Log
    WHERE Student_ID = NEW.Student_ID;
    
    INSERT IGNORE INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
    SELECT NEW.Student_ID, Badge_ID, CURDATE(), total_hours
    FROM Badge
    WHERE Hours_Required <= total_hours
      AND Badge_ID NOT IN (
          SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = NEW.Student_ID
      );
END//

-- 7. Auto-award badges when volunteer hours are updated
DROP TRIGGER IF EXISTS auto_award_badges_update//
CREATE TRIGGER auto_award_badges_update
AFTER UPDATE ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE total_hours DECIMAL(6,2);
    
    SELECT COALESCE(SUM(Hours_Worked), 0) INTO total_hours
    FROM Volunteer_Log
    WHERE Student_ID = NEW.Student_ID;
    
    INSERT IGNORE INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
    SELECT NEW.Student_ID, Badge_ID, CURDATE(), total_hours
    FROM Badge
    WHERE Hours_Required <= total_hours
      AND Badge_ID NOT IN (
          SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = NEW.Student_ID
      );
END//

-- 8. Ensure executives have membership records
DROP TRIGGER IF EXISTS validate_executive_membership//
CREATE TRIGGER validate_executive_membership
BEFORE INSERT ON Club_Executive
FOR EACH ROW
BEGIN
    DECLARE membership_count INT;
    
    SELECT COUNT(*) INTO membership_count
    FROM Membership
    WHERE Student_ID = NEW.Student_ID AND Role = 'Executive';
    
    IF membership_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student must have an Executive membership record before being added as Club Executive.';
    END IF;
END//

DELIMITER ;

-- 9. Scheduled Event: Automatic status updates
DELIMITER //
DROP EVENT IF EXISTS update_equipment_status//
CREATE EVENT update_equipment_status
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE Equipment e
    SET Status = 'In-Use'
    WHERE Status = 'Available'
      AND EXISTS (
          SELECT 1 FROM Resource_Booking rb
          WHERE rb.Equip_ID = e.Equip_ID
            AND rb.Status = 'Confirmed'
            AND NOW() BETWEEN rb.Borrow_Time AND rb.Return_Time
      );

    UPDATE Resource_Booking
    SET Status = 'Completed'
    WHERE Status = 'Confirmed'
      AND NOW() > Return_Time;

    UPDATE Equipment e
    SET Status = 'Available'
    WHERE Status = 'In-Use'
      AND NOT EXISTS (
          SELECT 1 FROM Resource_Booking rb
          WHERE rb.Equip_ID = e.Equip_ID
            AND rb.Status = 'Confirmed'
            AND NOW() BETWEEN rb.Borrow_Time AND rb.Return_Time
      );
END//

DELIMITER ;

-- ============================================
-- PART 3: DATABASE VIEWS (11 Pre-built Reports)
-- ============================================

-- View 1: Available Volunteers
DROP VIEW IF EXISTS Available_Volunteers;
CREATE VIEW Available_Volunteers AS
SELECT 
    s.Student_ID, s.Name, s.Email,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
    GROUP_CONCAT(DISTINCT c.Name ORDER BY c.Name SEPARATOR ', ') AS Club_Memberships,
    COUNT(DISTINCT m.Club_ID) AS Clubs_Count
FROM Student s
LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
LEFT JOIN Club c ON m.Club_ID = c.Club_ID
WHERE s.Student_ID NOT IN (
    SELECT DISTINCT vl2.Student_ID FROM Volunteer_Log vl2
    JOIN Event e ON vl2.Event_ID = e.Event_ID WHERE e.Date = CURDATE()
)
GROUP BY s.Student_ID, s.Name, s.Email
ORDER BY Total_Hours DESC;

-- View 2: Equipment Dashboard
DROP VIEW IF EXISTS Equipment_Dashboard;
CREATE VIEW Equipment_Dashboard AS
SELECT 
    e.Equip_ID, e.Name, e.Type, e.Status, e.Purchase_Date,
    c.Name AS Owner_Club,
    COUNT(DISTINCT rb.Booking_ID) AS Upcoming_Bookings_Count,
    COALESCE(SUM(ml.Cost), 0) AS Total_Maintenance_Cost,
    (SELECT MIN(rb2.Borrow_Time) FROM Resource_Booking rb2
     WHERE rb2.Equip_ID = e.Equip_ID AND rb2.Status = 'Confirmed' AND rb2.Borrow_Time > NOW()
    ) AS Next_Available_Time,
    DATEDIFF(CURDATE(), e.Purchase_Date) AS Days_Since_Purchase
FROM Equipment e
JOIN Club c ON e.Owner_Club_ID = c.Club_ID
LEFT JOIN Resource_Booking rb ON e.Equip_ID = rb.Equip_ID AND rb.Status = 'Confirmed' AND rb.Borrow_Time > NOW()
LEFT JOIN Maintenance_Log ml ON e.Equip_ID = ml.Equip_ID
GROUP BY e.Equip_ID, e.Name, e.Type, e.Status, e.Purchase_Date, c.Name
ORDER BY e.Status, e.Name;

-- View 3: Club Activity Summary
DROP VIEW IF EXISTS Club_Activity_Summary;
CREATE VIEW Club_Activity_Summary AS
SELECT 
    c.Club_ID, c.Name AS Club_Name, c.Department,
    COUNT(DISTINCT m.Student_ID) AS Total_Members,
    COUNT(DISTINCT e.Equip_ID) AS Equipment_Owned,
    COUNT(DISTINCT ev.Event_ID) AS Events_Organized,
    COUNT(DISTINCT col.Event_ID) AS Events_Collaborated,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Volunteer_Hours,
    RANK() OVER (ORDER BY COALESCE(SUM(vl.Hours_Worked), 0) DESC) AS Performance_Rank
FROM Club c
LEFT JOIN Membership m ON c.Club_ID = m.Club_ID
LEFT JOIN Equipment e ON c.Club_ID = e.Owner_Club_ID
LEFT JOIN Event ev ON c.Club_ID = ev.Primary_Club_ID
LEFT JOIN Collaboration col ON c.Club_ID = col.Partner_Club_ID
LEFT JOIN Volunteer_Log vl ON ev.Event_ID = vl.Event_ID
GROUP BY c.Club_ID, c.Name, c.Department
ORDER BY Performance_Rank;

-- View 4: Student Volunteer Profile
DROP VIEW IF EXISTS Student_Volunteer_Profile;
CREATE VIEW Student_Volunteer_Profile AS
SELECT 
    s.Student_ID, s.Name, s.Email,
    GROUP_CONCAT(DISTINCT c.Name ORDER BY c.Name SEPARATOR ', ') AS Clubs_Joined,
    COUNT(DISTINCT vl.Event_ID) AS Events_Volunteered,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
    COALESCE(AVG(vl.Hours_Worked), 0) AS Average_Hours_Per_Event,
    MAX(vl.Verification_Date) AS Last_Volunteer_Date,
    CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
         THEN 'Yes' ELSE 'No' END AS Is_Executive,
    CASE 
        WHEN COALESCE(SUM(vl.Hours_Worked), 0) >= 100 THEN 'Champion'
        WHEN COALESCE(SUM(vl.Hours_Worked), 0) >= 50 THEN 'Active'
        WHEN COALESCE(SUM(vl.Hours_Worked), 0) >= 20 THEN 'Engaged'
        WHEN COALESCE(SUM(vl.Hours_Worked), 0) >= 5 THEN 'Participant'
        ELSE 'Inactive'
    END AS Engagement_Level
FROM Student s
LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
LEFT JOIN Club c ON m.Club_ID = c.Club_ID
LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
GROUP BY s.Student_ID, s.Name, s.Email
ORDER BY Total_Hours DESC;

-- View 5: Volunteer Leaderboard
DROP VIEW IF EXISTS Volunteer_Leaderboard;
CREATE VIEW Volunteer_Leaderboard AS
SELECT 
    RANK() OVER (ORDER BY COALESCE(SUM(vl.Hours_Worked), 0) DESC) AS Rank_Position,
    s.Student_ID, s.Name,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
    COUNT(DISTINCT vl.Event_ID) AS Events_Count,
    COUNT(DISTINCT vb.Badge_ID) AS Badges_Earned,
    (SELECT MAX(b.Tier) FROM Volunteer_Badge vb2 
     JOIN Badge b ON vb2.Badge_ID = b.Badge_ID WHERE vb2.Student_ID = s.Student_ID
     ORDER BY FIELD(b.Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond') DESC LIMIT 1
    ) AS Highest_Tier,
    CASE 
        WHEN RANK() OVER (ORDER BY COALESCE(SUM(vl.Hours_Worked), 0) DESC) = 1 THEN '🥇'
        WHEN RANK() OVER (ORDER BY COALESCE(SUM(vl.Hours_Worked), 0) DESC) = 2 THEN '🥈'
        WHEN RANK() OVER (ORDER BY COALESCE(SUM(vl.Hours_Worked), 0) DESC) = 3 THEN '🥉'
        ELSE ''
    END AS Medal
FROM Student s
LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
LEFT JOIN Volunteer_Badge vb ON s.Student_ID = vb.Student_ID
GROUP BY s.Student_ID, s.Name
HAVING Total_Hours > 0
ORDER BY Rank_Position;

-- View 6: Badge Statistics
DROP VIEW IF EXISTS Badge_Statistics;
CREATE VIEW Badge_Statistics AS
SELECT 
    b.Badge_ID, b.Name AS Badge_Name, b.Tier, b.Hours_Required,
    b.Description, b.Icon, b.Color,
    COUNT(DISTINCT vb.Student_ID) AS Students_Earned,
    ROUND((COUNT(DISTINCT vb.Student_ID) * 100.0 / 
        (SELECT COUNT(DISTINCT Student_ID) FROM Volunteer_Log)), 2) AS Percentage_Of_Volunteers
FROM Badge b
LEFT JOIN Volunteer_Badge vb ON b.Badge_ID = vb.Badge_ID
GROUP BY b.Badge_ID, b.Name, b.Tier, b.Hours_Required, b.Description, b.Icon, b.Color
ORDER BY FIELD(b.Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'), b.Hours_Required;

-- View 7: Upcoming Events Resources
DROP VIEW IF EXISTS Upcoming_Events_Resources;
CREATE VIEW Upcoming_Events_Resources AS
SELECT 
    e.Event_ID, e.Title, e.Date, e.Venue, c.Name AS Primary_Club,
    COUNT(DISTINCT rb.Equip_ID) AS Equipment_Booked,
    COUNT(DISTINCT col.Partner_Club_ID) AS Partner_Clubs_Count,
    COUNT(DISTINCT vl.Student_ID) AS Volunteers_Assigned,
    GROUP_CONCAT(DISTINCT eq.Name ORDER BY eq.Name SEPARATOR ', ') AS Equipment_List
FROM Event e
JOIN Club c ON e.Primary_Club_ID = c.Club_ID
LEFT JOIN Resource_Booking rb ON e.Event_ID = rb.Event_ID AND rb.Status = 'Confirmed'
LEFT JOIN Equipment eq ON rb.Equip_ID = eq.Equip_ID
LEFT JOIN Collaboration col ON e.Event_ID = col.Event_ID
LEFT JOIN Volunteer_Log vl ON e.Event_ID = vl.Event_ID
WHERE e.Date >= CURDATE()
GROUP BY e.Event_ID, e.Title, e.Date, e.Venue, c.Name
ORDER BY e.Date;

-- View 8: Equipment Maintenance History
DROP VIEW IF EXISTS Equipment_Maintenance_History;
CREATE VIEW Equipment_Maintenance_History AS
SELECT 
    e.Equip_ID, e.Name AS Equipment_Name, e.Type,
    COUNT(ml.Log_ID) AS Maintenance_Count,
    COALESCE(SUM(ml.Cost), 0) AS Total_Cost,
    COALESCE(AVG(ml.Cost), 0) AS Average_Cost,
    MAX(ml.Date) AS Last_Maintenance_Date,
    DATEDIFF(CURDATE(), MAX(ml.Date)) AS Days_Since_Last_Maintenance
FROM Equipment e
LEFT JOIN Maintenance_Log ml ON e.Equip_ID = ml.Equip_ID
GROUP BY e.Equip_ID, e.Name, e.Type
ORDER BY Total_Cost DESC;

-- View 9: Cross-Club Volunteers
DROP VIEW IF EXISTS Cross_Club_Volunteers;
CREATE VIEW Cross_Club_Volunteers AS
SELECT 
    s.Student_ID, s.Name,
    GROUP_CONCAT(DISTINCT mc.Name ORDER BY mc.Name SEPARATOR ', ') AS Home_Clubs,
    COALESCE(SUM(CASE 
        WHEN ev.Primary_Club_ID NOT IN (SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID)
        THEN vl.Hours_Worked ELSE 0 END), 0) AS Cross_Club_Hours,
    COUNT(DISTINCT CASE 
        WHEN ev.Primary_Club_ID NOT IN (SELECT m3.Club_ID FROM Membership m3 WHERE m3.Student_ID = s.Student_ID)
        THEN vl.Event_ID END) AS Cross_Club_Events,
    GROUP_CONCAT(DISTINCT CASE 
        WHEN ev.Primary_Club_ID NOT IN (SELECT m4.Club_ID FROM Membership m4 WHERE m4.Student_ID = s.Student_ID)
        THEN hc.Name END ORDER BY hc.Name SEPARATOR ', ') AS Clubs_Helped
FROM Student s
JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
JOIN Event ev ON vl.Event_ID = ev.Event_ID
LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
LEFT JOIN Club mc ON m.Club_ID = mc.Club_ID
LEFT JOIN Club hc ON ev.Primary_Club_ID = hc.Club_ID
GROUP BY s.Student_ID, s.Name
HAVING Cross_Club_Hours > 0
ORDER BY Cross_Club_Hours DESC;

-- View 10: Booking Conflicts Report
DROP VIEW IF EXISTS Booking_Conflicts_Report;
CREATE VIEW Booking_Conflicts_Report AS
SELECT 
    rb1.Booking_ID AS Booking_1_ID, rb2.Booking_ID AS Booking_2_ID,
    e.Name AS Equipment_Name, ev1.Title AS Event_1, ev2.Title AS Event_2,
    rb1.Borrow_Time AS Booking_1_Start, rb1.Return_Time AS Booking_1_End,
    rb2.Borrow_Time AS Booking_2_Start, rb2.Return_Time AS Booking_2_End,
    'CONFLICT DETECTED' AS Status
FROM Resource_Booking rb1
JOIN Resource_Booking rb2 ON rb1.Equip_ID = rb2.Equip_ID 
    AND rb1.Booking_ID < rb2.Booking_ID
    AND rb1.Status = 'Confirmed' AND rb2.Status = 'Confirmed'
    AND (rb1.Borrow_Time < rb2.Return_Time AND rb1.Return_Time > rb2.Borrow_Time)
JOIN Equipment e ON rb1.Equip_ID = e.Equip_ID
JOIN Event ev1 ON rb1.Event_ID = ev1.Event_ID
JOIN Event ev2 ON rb2.Event_ID = ev2.Event_ID
ORDER BY e.Name, rb1.Borrow_Time;

-- ============================================
-- PART 4: STORED PROCEDURES (6 Analytics Queries)
-- ============================================

-- Procedure 1: Top Cross-Club Volunteer
DROP PROCEDURE IF EXISTS Get_Top_Cross_Club_Volunteer;
DELIMITER //
CREATE PROCEDURE Get_Top_Cross_Club_Volunteer()
BEGIN
    SELECT s.Student_ID, s.Name, s.Email,
        GROUP_CONCAT(DISTINCT mc.Name ORDER BY mc.Name SEPARATOR ', ') AS Home_Clubs,
        COALESCE(SUM(CASE WHEN ev.Primary_Club_ID NOT IN (SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID)
            THEN vl.Hours_Worked ELSE 0 END), 0) AS Cross_Club_Hours,
        COUNT(DISTINCT CASE WHEN ev.Primary_Club_ID NOT IN (SELECT m3.Club_ID FROM Membership m3 WHERE m3.Student_ID = s.Student_ID)
            THEN vl.Event_ID END) AS Cross_Club_Events,
        GROUP_CONCAT(DISTINCT CASE WHEN ev.Primary_Club_ID NOT IN (SELECT m4.Club_ID FROM Membership m4 WHERE m4.Student_ID = s.Student_ID)
            THEN hc.Name END ORDER BY hc.Name SEPARATOR ', ') AS Clubs_Helped
    FROM Student s
    JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
    JOIN Event ev ON vl.Event_ID = ev.Event_ID
    LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
    LEFT JOIN Club mc ON m.Club_ID = mc.Club_ID
    LEFT JOIN Club hc ON ev.Primary_Club_ID = hc.Club_ID
    GROUP BY s.Student_ID, s.Name, s.Email
    HAVING Cross_Club_Hours > 0
    ORDER BY Cross_Club_Hours DESC LIMIT 1;
END//
DELIMITER ;

-- Procedure 2: Equipment Utilization
DROP PROCEDURE IF EXISTS Get_Equipment_Utilization;
DELIMITER //
CREATE PROCEDURE Get_Equipment_Utilization()
BEGIN
    SELECT e.Equip_ID, e.Name, e.Type, e.Status, c.Name AS Owner_Club,
        COUNT(rb.Booking_ID) AS Total_Bookings,
        COALESCE(SUM(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 0) AS Total_Hours_Booked,
        COALESCE(SUM(ml.Cost), 0) AS Total_Maintenance_Cost,
        CASE 
            WHEN COALESCE(SUM(ml.Cost), 0) = 0 THEN 'N/A'
            WHEN COALESCE(SUM(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 0) / COALESCE(SUM(ml.Cost), 1) > 10 THEN 'Excellent'
            WHEN COALESCE(SUM(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 0) / COALESCE(SUM(ml.Cost), 1) > 5 THEN 'Good'
            WHEN COALESCE(SUM(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 0) / COALESCE(SUM(ml.Cost), 1) > 2 THEN 'Fair'
            ELSE 'Poor'
        END AS ROI_Rating,
        ROUND(COUNT(rb.Booking_ID) / GREATEST(TIMESTAMPDIFF(MONTH, e.Purchase_Date, CURDATE()), 1), 2) AS Bookings_Per_Month,
        DATEDIFF(CURDATE(), e.Purchase_Date) AS Days_Since_Purchase,
        CASE 
            WHEN COUNT(rb.Booking_ID) = 0 THEN 'Consider Retiring'
            WHEN COALESCE(SUM(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 0) < 10 THEN 'Low Usage'
            WHEN COALESCE(SUM(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 0) < 50 THEN 'Moderate Usage'
            ELSE 'High Usage - Consider Purchasing More'
        END AS Recommendation
    FROM Equipment e
    JOIN Club c ON e.Owner_Club_ID = c.Club_ID
    LEFT JOIN Resource_Booking rb ON e.Equip_ID = rb.Equip_ID
    LEFT JOIN Maintenance_Log ml ON e.Equip_ID = ml.Equip_ID
    GROUP BY e.Equip_ID, e.Name, e.Type, e.Status, c.Name, e.Purchase_Date
    ORDER BY Total_Hours_Booked DESC;
END//
DELIMITER ;

-- Procedure 3: Club Collaboration Network
DROP PROCEDURE IF EXISTS Get_Club_Collaboration_Network;
DELIMITER //
CREATE PROCEDURE Get_Club_Collaboration_Network()
BEGIN
    SELECT c1.Name AS Club_1, c2.Name AS Club_2,
        COUNT(DISTINCT col.Event_ID) AS Collaborations_Count,
        COUNT(DISTINCT rb1.Equip_ID) AS Shared_Equipment_Usage,
        GROUP_CONCAT(DISTINCT e.Title ORDER BY e.Date DESC SEPARATOR ' | ') AS Recent_Events,
        CASE 
            WHEN COUNT(DISTINCT col.Event_ID) >= 5 THEN 'Strong Partnership'
            WHEN COUNT(DISTINCT col.Event_ID) >= 3 THEN 'Moderate Partnership'
            WHEN COUNT(DISTINCT col.Event_ID) >= 1 THEN 'Emerging Partnership'
            ELSE 'No Partnership'
        END AS Partnership_Strength,
        ROUND((COUNT(DISTINCT col.Event_ID) * 10 + COUNT(DISTINCT rb1.Equip_ID) * 5) / 15.0, 2) AS Collaboration_Score
    FROM Club c1
    CROSS JOIN Club c2 ON c1.Club_ID < c2.Club_ID
    LEFT JOIN Event e ON (e.Primary_Club_ID = c1.Club_ID OR e.Primary_Club_ID = c2.Club_ID)
    LEFT JOIN Collaboration col ON e.Event_ID = col.Event_ID 
        AND (col.Partner_Club_ID = c1.Club_ID OR col.Partner_Club_ID = c2.Club_ID)
        AND col.Partner_Club_ID != e.Primary_Club_ID
    LEFT JOIN Resource_Booking rb1 ON e.Event_ID = rb1.Event_ID
    LEFT JOIN Equipment eq1 ON rb1.Equip_ID = eq1.Equip_ID 
        AND (eq1.Owner_Club_ID = c1.Club_ID OR eq1.Owner_Club_ID = c2.Club_ID)
    GROUP BY c1.Club_ID, c1.Name, c2.Club_ID, c2.Name
    HAVING Collaborations_Count > 0
    ORDER BY Collaboration_Score DESC, Collaborations_Count DESC;
END//
DELIMITER ;

-- Procedure 4: Event Success Metrics
DROP PROCEDURE IF EXISTS Get_Event_Success_Metrics;
DELIMITER //
CREATE PROCEDURE Get_Event_Success_Metrics()
BEGIN
    SELECT e.Event_ID, e.Title, e.Date, e.Venue, c.Name AS Primary_Club,
        COUNT(DISTINCT vl.Student_ID) AS Volunteers_Count,
        COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Volunteer_Hours,
        COUNT(DISTINCT col.Partner_Club_ID) AS Partner_Clubs_Count,
        COUNT(DISTINCT rb.Equip_ID) AS Equipment_Used,
        CASE 
            WHEN COUNT(DISTINCT vl.Student_ID) >= 10 AND COUNT(DISTINCT col.Partner_Club_ID) >= 3 THEN 'Large'
            WHEN COUNT(DISTINCT vl.Student_ID) >= 5 AND COUNT(DISTINCT col.Partner_Club_ID) >= 2 THEN 'Medium'
            ELSE 'Small'
        END AS Event_Scale,
        ROUND((COUNT(DISTINCT vl.Student_ID) * 5 + COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
               COUNT(DISTINCT col.Partner_Club_ID) * 10 + COUNT(DISTINCT rb.Equip_ID) * 3) / 20.0, 2) AS Success_Score
    FROM Event e
    JOIN Club c ON e.Primary_Club_ID = c.Club_ID
    LEFT JOIN Volunteer_Log vl ON e.Event_ID = vl.Event_ID
    LEFT JOIN Collaboration col ON e.Event_ID = col.Event_ID
    LEFT JOIN Resource_Booking rb ON e.Event_ID = rb.Event_ID
    GROUP BY e.Event_ID, e.Title, e.Date, e.Venue, c.Name
    ORDER BY Success_Score DESC;
END//
DELIMITER ;

-- Procedure 5: Student Engagement Ranking
DROP PROCEDURE IF EXISTS Get_Student_Engagement_Ranking;
DELIMITER //
CREATE PROCEDURE Get_Student_Engagement_Ranking()
BEGIN
    SELECT s.Student_ID, s.Name, s.Email,
        COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
        COUNT(DISTINCT vl.Event_ID) AS Events_Volunteered,
        COUNT(DISTINCT m.Club_ID) AS Clubs_Joined,
        CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) THEN 1 ELSE 0 END AS Is_Executive,
        COUNT(DISTINCT vl.Role) AS Different_Roles,
        ROUND((COALESCE(SUM(vl.Hours_Worked), 0) * 2 + COUNT(DISTINCT vl.Event_ID) * 5 + 
               COUNT(DISTINCT m.Club_ID) * 3 + 
               CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) THEN 20 ELSE 0 END + 
               COUNT(DISTINCT vl.Role) * 5) / 35.0, 2) AS Engagement_Score,
        CASE 
            WHEN ROUND((COALESCE(SUM(vl.Hours_Worked), 0) * 2 + COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 35.0, 2) >= 80 THEN 'Champion'
            WHEN ROUND((COALESCE(SUM(vl.Hours_Worked), 0) * 2 + COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 35.0, 2) >= 60 THEN 'Active'
            WHEN ROUND((COALESCE(SUM(vl.Hours_Worked), 0) * 2 + COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 35.0, 2) >= 40 THEN 'Engaged'
            WHEN ROUND((COALESCE(SUM(vl.Hours_Worked), 0) * 2 + COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 35.0, 2) >= 20 THEN 'Participant'
            ELSE 'Inactive'
        END AS Engagement_Category
    FROM Student s
    LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
    LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
    GROUP BY s.Student_ID, s.Name, s.Email
    ORDER BY Engagement_Score DESC;
END//
DELIMITER ;

-- Procedure 6: Booking Pattern Analysis
DROP PROCEDURE IF EXISTS Get_Booking_Pattern_Analysis;
DELIMITER //
CREATE PROCEDURE Get_Booking_Pattern_Analysis()
BEGIN
    SELECT DAYNAME(rb.Borrow_Time) AS Day_Of_Week,
        HOUR(rb.Borrow_Time) AS Hour_Of_Day,
        COUNT(*) AS Booking_Count,
        e.Type AS Equipment_Type,
        ROUND(AVG(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 2) AS Avg_Duration_Hours,
        CASE 
            WHEN COUNT(*) >= 10 THEN 'High Demand'
            WHEN COUNT(*) >= 5 THEN 'Moderate Demand'
            ELSE 'Low Demand'
        END AS Demand_Level
    FROM Resource_Booking rb
    JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
    WHERE rb.Status IN ('Confirmed', 'Completed')
    GROUP BY DAYNAME(rb.Borrow_Time), HOUR(rb.Borrow_Time), e.Type
    ORDER BY Booking_Count DESC, Day_Of_Week, Hour_Of_Day;
END//
DELIMITER ;

-- ============================================
-- PART 5: SAMPLE DATA
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Volunteer_Badge;
TRUNCATE TABLE Badge;
TRUNCATE TABLE Phone_Numbers;
TRUNCATE TABLE Contact_Emails;
TRUNCATE TABLE Volunteer_Log;
TRUNCATE TABLE Collaboration;
TRUNCATE TABLE Resource_Booking;
TRUNCATE TABLE Maintenance_Log;
TRUNCATE TABLE Equipment;
TRUNCATE TABLE Event;
TRUNCATE TABLE Membership;
TRUNCATE TABLE Club_Executive;
TRUNCATE TABLE General_Student;
TRUNCATE TABLE Student;
TRUNCATE TABLE Club;
SET FOREIGN_KEY_CHECKS = 1;

-- Insert Clubs
INSERT INTO Club (Name, Department, Office_Room, Founded_Date) VALUES
('Media Society', 'Arts & Media', 'A201', '2018-09-01');
SET @club1 = LAST_INSERT_ID();

INSERT INTO Club (Name, Department, Office_Room, Founded_Date) VALUES
('Tech Innovators', 'Computer Science', 'C305', '2017-05-15');
SET @club2 = LAST_INSERT_ID();

INSERT INTO Club (Name, Department, Office_Room, Founded_Date) VALUES
('Sports Alliance', 'Physical Education', 'B108', '2016-02-10');
SET @club3 = LAST_INSERT_ID();

-- Insert Students
INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES
('Maya Patel', 'maya.patel@example.edu', 'password123', '12 Elm St', 'Springfield', '12345', '555-0101');
SET @student1 = LAST_INSERT_ID();

INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES
('Noah Kim', 'noah.kim@example.edu', 'securePass!', '89 Pine St', 'Springfield', '12345', '555-0102');
SET @student2 = LAST_INSERT_ID();

INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES
('Aisha Ahmed', 'aisha.ahmed@example.edu', 'helloWorld', '47 Oak Ave', 'Springfield', '12345', '555-0103');
SET @student3 = LAST_INSERT_ID();

INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES
('Liam Torres', 'liam.torres@example.edu', 'pass2026', '73 Maple Rd', 'Springfield', '12345', '555-0104');
SET @student4 = LAST_INSERT_ID();

INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES
('Zoe Carter', 'zoe.carter@example.edu', 'clubLeader!', '28 Birch Blvd', 'Springfield', '12345', '555-0105');
SET @student5 = LAST_INSERT_ID();

INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES
('Demo Student', 'student@example.edu', 'student123', '123 Demo St', 'Springfield', '12345', '555-0199');
SET @student6 = LAST_INSERT_ID();

INSERT INTO Student (Name, Email, Password, Street, City, Zip, Contact_No) VALUES
('Demo Admin', 'admin@example.edu', 'admin123', '456 Admin Ave', 'Springfield', '12345', '555-0198');
SET @student7 = LAST_INSERT_ID();

-- Insert General Students
INSERT INTO General_Student (Student_ID, Year_of_Study, Major) VALUES
(@student1, 2, 'Media Studies'),
(@student2, 3, 'Computer Science'),
(@student3, 1, 'Journalism'),
(@student4, 4, 'Sports Management'),
(@student5, 2, 'Information Systems'),
(@student6, 2, 'Computer Science');

-- Insert Contact Emails
INSERT INTO Contact_Emails (Club_ID, Email) VALUES
(@club1, 'media@college.edu'),
(@club2, 'tech@college.edu'),
(@club3, 'sports@college.edu');

-- Insert Phone Numbers
INSERT INTO Phone_Numbers (Student_ID, Phone_Number) VALUES
(@student1, '555-010-1001'),
(@student2, '555-010-1002'),
(@student3, '555-010-1003'),
(@student6, '555-019-9001'),
(@student7, '555-019-9002');

-- Insert Memberships (must come before Club_Executive due to trigger validation)
INSERT INTO Membership (Student_ID, Club_ID, Role, Join_Date) VALUES
(@student1, @club1, 'Executive', '2023-09-05'),
(@student2, @club2, 'Executive', '2023-09-05'),
(@student3, @club1, 'Member', '2024-01-20'),
(@student4, @club3, 'Volunteer', '2024-02-15'),
(@student5, @club2, 'Member', '2024-03-10'),
(@student6, @club2, 'Member', '2024-09-01'),
(@student7, @club1, 'Executive', '2024-01-01');

-- Insert Club Executives (after memberships)
INSERT INTO Club_Executive (Student_ID, Position, Term_Start, Term_End) VALUES
(@student1, 'President', '2024-08-01', '2025-05-31'),
(@student2, 'Vice President', '2024-08-01', '2025-05-31'),
(@student7, 'System Administrator', '2024-01-01', '2025-12-31');

-- Insert Equipment
INSERT INTO Equipment (Name, Type, Status, Owner_Club_ID, Purchase_Date) VALUES
('Sony Camera ZX10', 'Camera', 'Available', @club1, '2023-03-22');
SET @equip1 = LAST_INSERT_ID();

INSERT INTO Equipment (Name, Type, Status, Owner_Club_ID, Purchase_Date) VALUES
('Epson Projector P90', 'Projector', 'In-Use', @club2, '2022-10-12');
SET @equip2 = LAST_INSERT_ID();

INSERT INTO Equipment (Name, Type, Status, Owner_Club_ID, Purchase_Date) VALUES
('Rode Microphone XLR', 'Microphone', 'Damaged', @club1, '2023-07-05');
SET @equip3 = LAST_INSERT_ID();

INSERT INTO Equipment (Name, Type, Status, Owner_Club_ID, Purchase_Date) VALUES
('Dell Laptop Latitude', 'Laptop', 'Available', @club2, '2023-11-02');
SET @equip4 = LAST_INSERT_ID();

INSERT INTO Equipment (Name, Type, Status, Owner_Club_ID, Purchase_Date) VALUES
('Bose Wireless Speaker', 'Speaker', 'Maintenance', @club3, '2024-01-18');
SET @equip5 = LAST_INSERT_ID();

-- Insert Maintenance Logs
INSERT INTO Maintenance_Log (Equip_ID, Log_ID, Date, Description, Cost) VALUES
(@equip3, 1, '2024-03-10', 'Replacement of XLR cable and audio test', 45.00),
(@equip5, 1, '2024-04-05', 'Speaker calibration and firmware update', 60.00);

-- Insert Events
INSERT INTO Event (Title, Date, Venue, Primary_Club_ID, Description) VALUES
('Spring Media Expo', '2025-05-10', 'Auditorium A', @club1, 'A showcase of media projects and club collaboration.');
SET @event1 = LAST_INSERT_ID();

INSERT INTO Event (Title, Date, Venue, Primary_Club_ID, Description) VALUES
('Hackathon Weekend', '2025-06-08', 'Lab C', @club2, '24-hour innovation and prototyping competition.');
SET @event2 = LAST_INSERT_ID();

INSERT INTO Event (Title, Date, Venue, Primary_Club_ID, Description) VALUES
('Championship Match', '2025-05-22', 'Gymnasium', @club3, 'Inter-college sports final with guest volunteers.');
SET @event3 = LAST_INSERT_ID();

-- Insert Collaborations
INSERT INTO Collaboration (Event_ID, Partner_Club_ID, Contribution_Type) VALUES
(@event1, @club2, 'Tech support'),
(@event2, @club1, 'Media coverage'),
(@event3, @club2, 'Audio/visual equipment');

-- Insert Resource Bookings
INSERT INTO Resource_Booking (Equip_ID, Event_ID, Borrow_Time, Return_Time, Status) VALUES
(@equip1, @event1, '2025-05-09 08:00:00', '2025-05-10 20:00:00', 'Confirmed'),
(@equip2, @event2, '2025-06-07 09:00:00', '2025-06-08 21:00:00', 'Confirmed');

-- Insert Volunteer Logs
INSERT INTO Volunteer_Log (Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date) VALUES
(@student4, @event3, 'Event Coordinator', 6.50, @student2, '2025-05-23'),
(@student3, @event1, 'Media Assistant', 4.00, @student1, '2025-05-11');

-- Insert Badges (20 badges across 5 tiers)
INSERT INTO Badge (Name, Description, Icon, Color, Hours_Required, Tier) VALUES
-- Bronze Tier (1-10 hours)
('Newcomer', 'Welcome to volunteering! First steps into community service.', 'star', '#CD7F32', 1.00, 'Bronze'),
('Helper', 'Lending a hand and making a difference.', 'hands-helping', '#CD7F32', 5.00, 'Bronze'),
('Contributor', 'Consistent support for club events.', 'user-check', '#CD7F32', 10.00, 'Bronze'),
-- Silver Tier (10-50 hours)
('Dedicated', 'Showing true commitment to the community.', 'award', '#C0C0C0', 15.00, 'Silver'),
('Committed', 'Going above and beyond for club success.', 'medal', '#C0C0C0', 25.00, 'Silver'),
('Reliable', 'A trusted volunteer for any event.', 'shield-check', '#C0C0C0', 40.00, 'Silver'),
-- Gold Tier (50-100 hours)
('Champion', 'Leading by example with exceptional service.', 'trophy', '#FFD700', 50.00, 'Gold'),
('Legend', 'Inspiring others through dedication and impact.', 'crown', '#FFD700', 75.00, 'Gold'),
('All-Star', 'Outstanding contributions across multiple events.', 'star-half-alt', '#FFD700', 90.00, 'Gold'),
-- Platinum Tier (100-200 hours)
('Hero', 'Extraordinary commitment to community excellence.', 'user-shield', '#E5E4E2', 100.00, 'Platinum'),
('Elite', 'Among the top volunteers in the community.', 'gem', '#E5E4E2', 150.00, 'Platinum'),
('Visionary', 'Shaping the future of club collaboration.', 'lightbulb', '#E5E4E2', 180.00, 'Platinum'),
-- Diamond Tier (200+ hours)
('Master', 'The pinnacle of volunteer achievement.', 'diamond', '#B9F2FF', 200.00, 'Diamond'),
('Icon', 'A legendary figure in club history.', 'fire', '#B9F2FF', 300.00, 'Diamond'),
('Immortal', 'Unmatched dedication and lifetime impact.', 'infinity', '#B9F2FF', 500.00, 'Diamond'),
-- Special Badges
('Cross-Club Volunteer', 'Helped 3 or more different clubs.', 'handshake', '#9370DB', 10.00, 'Silver'),
('Event Organizer', 'Led event coordination and logistics.', 'calendar-check', '#FF6347', 20.00, 'Gold'),
('Tech Support Pro', 'Expert in technical assistance roles.', 'laptop-code', '#4169E1', 15.00, 'Silver'),
('Media Maven', 'Excellence in media and documentation.', 'camera', '#FF1493', 15.00, 'Silver'),
('Setup Specialist', 'Master of event setup and preparation.', 'tools', '#32CD32', 15.00, 'Silver');

-- Note: Badge awards will be automatically generated by triggers when volunteer logs are inserted

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Database: club_collab
-- Tables: 15
-- Triggers: 8
-- Views: 11 (actually 10 in this file)
-- Stored Procedures: 6
-- Badges: 20
-- Sample Students: 7
-- Sample Events: 3
-- ============================================
-- Next Steps:
-- 1. Verify: SELECT COUNT(*) FROM Badge; (should be 20)
-- 2. Test triggers by logging volunteer hours
-- 3. Check views: SELECT * FROM Volunteer_Leaderboard;
-- 4. Run analytics: CALL Get_Equipment_Utilization();
-- ============================================
