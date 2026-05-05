USE club_collab;

-- ============================================
-- DATABASE VIEWS FOR ANALYTICS & REPORTS
-- ============================================

-- ============================================
-- A. AVAILABLE VOLUNTEERS VIEW
-- ============================================
DROP VIEW IF EXISTS Available_Volunteers;
CREATE VIEW Available_Volunteers AS
SELECT 
    s.Student_ID,
    s.Name,
    s.Email,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
    GROUP_CONCAT(DISTINCT c.Name ORDER BY c.Name SEPARATOR ', ') AS Club_Memberships,
    COUNT(DISTINCT m.Club_ID) AS Clubs_Count
FROM Student s
LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
WHERE s.Student_ID NOT IN (
    SELECT DISTINCT vl2.Student_ID
    FROM Volunteer_Log vl2
    JOIN Event e ON vl2.Event_ID = e.Event_ID
    WHERE e.Date = CURDATE()
)
LEFT JOIN Club c ON m.Club_ID = c.Club_ID
GROUP BY s.Student_ID, s.Name, s.Email
ORDER BY Total_Hours DESC;

-- ============================================
-- B. EQUIPMENT DASHBOARD VIEW
-- ============================================
DROP VIEW IF EXISTS Equipment_Dashboard;
CREATE VIEW Equipment_Dashboard AS
SELECT 
    e.Equip_ID,
    e.Name,
    e.Type,
    e.Status,
    e.Purchase_Date,
    c.Name AS Owner_Club,
    COUNT(DISTINCT rb.Booking_ID) AS Upcoming_Bookings_Count,
    COALESCE(SUM(ml.Cost), 0) AS Total_Maintenance_Cost,
    (SELECT MIN(rb2.Borrow_Time)
     FROM Resource_Booking rb2
     WHERE rb2.Equip_ID = e.Equip_ID
       AND rb2.Status = 'Confirmed'
       AND rb2.Borrow_Time > NOW()
    ) AS Next_Available_Time,
    DATEDIFF(CURDATE(), e.Purchase_Date) AS Days_Since_Purchase
FROM Equipment e
JOIN Club c ON e.Owner_Club_ID = c.Club_ID
LEFT JOIN Resource_Booking rb ON e.Equip_ID = rb.Equip_ID 
    AND rb.Status = 'Confirmed' 
    AND rb.Borrow_Time > NOW()
LEFT JOIN Maintenance_Log ml ON e.Equip_ID = ml.Equip_ID
GROUP BY e.Equip_ID, e.Name, e.Type, e.Status, e.Purchase_Date, c.Name
ORDER BY e.Status, e.Name;

-- ============================================
-- C. CLUB ACTIVITY SUMMARY VIEW
-- ============================================
DROP VIEW IF EXISTS Club_Activity_Summary;
CREATE VIEW Club_Activity_Summary AS
SELECT 
    c.Club_ID,
    c.Name AS Club_Name,
    c.Department,
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

-- ============================================
-- D. STUDENT VOLUNTEER PROFILE VIEW
-- ============================================
DROP VIEW IF EXISTS Student_Volunteer_Profile;
CREATE VIEW Student_Volunteer_Profile AS
SELECT 
    s.Student_ID,
    s.Name,
    s.Email,
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

-- ============================================
-- E. VOLUNTEER STATS WITH BADGE PROGRESS VIEW
-- ============================================
DROP VIEW IF EXISTS Volunteer_Stats;
CREATE VIEW Volunteer_Stats AS
SELECT 
    s.Student_ID,
    s.Name,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
    COUNT(DISTINCT vl.Event_ID) AS Events_Participated,
    COUNT(DISTINCT m.Club_ID) AS Clubs_Joined,
    COUNT(DISTINCT CASE 
        WHEN m.Club_ID NOT IN (
            SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
        ) THEN vl.Event_ID 
    END) AS Cross_Club_Events,
    COALESCE(SUM(CASE 
        WHEN ev.Primary_Club_ID NOT IN (
            SELECT m3.Club_ID FROM Membership m3 WHERE m3.Student_ID = s.Student_ID
        ) THEN vl.Hours_Worked 
        ELSE 0 
    END), 0) AS Cross_Club_Hours,
    COUNT(DISTINCT vb.Badge_ID) AS Badges_Earned,
    (SELECT MAX(b.Tier) 
     FROM Volunteer_Badge vb2 
     JOIN Badge b ON vb2.Badge_ID = b.Badge_ID 
     WHERE vb2.Student_ID = s.Student_ID
     ORDER BY FIELD(b.Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond') DESC
     LIMIT 1
    ) AS Highest_Tier,
    (SELECT b2.Name
     FROM Badge b2
     WHERE b2.Hours_Required > COALESCE(SUM(vl.Hours_Worked), 0)
       AND b2.Badge_ID NOT IN (SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = s.Student_ID)
     ORDER BY b2.Hours_Required ASC
     LIMIT 1
    ) AS Next_Badge_Name,
    (SELECT b3.Hours_Required - COALESCE(SUM(vl.Hours_Worked), 0)
     FROM Badge b3
     WHERE b3.Hours_Required > COALESCE(SUM(vl.Hours_Worked), 0)
       AND b3.Badge_ID NOT IN (SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = s.Student_ID)
     ORDER BY b3.Hours_Required ASC
     LIMIT 1
    ) AS Hours_To_Next_Badge,
    (SELECT ROUND((COALESCE(SUM(vl.Hours_Worked), 0) / b4.Hours_Required) * 100, 2)
     FROM Badge b4
     WHERE b4.Hours_Required > COALESCE(SUM(vl.Hours_Worked), 0)
       AND b4.Badge_ID NOT IN (SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = s.Student_ID)
     ORDER BY b4.Hours_Required ASC
     LIMIT 1
    ) AS Progress_Percentage
FROM Student s
LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
LEFT JOIN Volunteer_Badge vb ON s.Student_ID = vb.Student_ID
LEFT JOIN Event ev ON vl.Event_ID = ev.Event_ID
GROUP BY s.Student_ID, s.Name
ORDER BY Total_Hours DESC;

-- ============================================
-- F. VOLUNTEER LEADERBOARD VIEW
-- ============================================
DROP VIEW IF EXISTS Volunteer_Leaderboard;
CREATE VIEW Volunteer_Leaderboard AS
SELECT 
    RANK() OVER (ORDER BY COALESCE(SUM(vl.Hours_Worked), 0) DESC) AS Rank_Position,
    s.Student_ID,
    s.Name,
    COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
    COUNT(DISTINCT vl.Event_ID) AS Events_Count,
    COUNT(DISTINCT vb.Badge_ID) AS Badges_Earned,
    (SELECT MAX(b.Tier) 
     FROM Volunteer_Badge vb2 
     JOIN Badge b ON vb2.Badge_ID = b.Badge_ID 
     WHERE vb2.Student_ID = s.Student_ID
     ORDER BY FIELD(b.Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond') DESC
     LIMIT 1
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

-- ============================================
-- G. BADGE STATISTICS VIEW
-- ============================================
DROP VIEW IF EXISTS Badge_Statistics;
CREATE VIEW Badge_Statistics AS
SELECT 
    b.Badge_ID,
    b.Name AS Badge_Name,
    b.Tier,
    b.Hours_Required,
    b.Description,
    b.Icon,
    b.Color,
    COUNT(DISTINCT vb.Student_ID) AS Students_Earned,
    ROUND((COUNT(DISTINCT vb.Student_ID) * 100.0 / 
        (SELECT COUNT(DISTINCT Student_ID) FROM Volunteer_Log)), 2) AS Percentage_Of_Volunteers
FROM Badge b
LEFT JOIN Volunteer_Badge vb ON b.Badge_ID = vb.Badge_ID
GROUP BY b.Badge_ID, b.Name, b.Tier, b.Hours_Required, b.Description, b.Icon, b.Color
ORDER BY FIELD(b.Tier, 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'), b.Hours_Required;

-- ============================================
-- H. UPCOMING EVENTS RESOURCES VIEW
-- ============================================
DROP VIEW IF EXISTS Upcoming_Events_Resources;
CREATE VIEW Upcoming_Events_Resources AS
SELECT 
    e.Event_ID,
    e.Title,
    e.Date,
    e.Venue,
    c.Name AS Primary_Club,
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

-- ============================================
-- I. EQUIPMENT MAINTENANCE HISTORY VIEW
-- ============================================
DROP VIEW IF EXISTS Equipment_Maintenance_History;
CREATE VIEW Equipment_Maintenance_History AS
SELECT 
    e.Equip_ID,
    e.Name AS Equipment_Name,
    e.Type,
    COUNT(ml.Log_ID) AS Maintenance_Count,
    COALESCE(SUM(ml.Cost), 0) AS Total_Cost,
    COALESCE(AVG(ml.Cost), 0) AS Average_Cost,
    MAX(ml.Date) AS Last_Maintenance_Date,
    DATEDIFF(CURDATE(), MAX(ml.Date)) AS Days_Since_Last_Maintenance
FROM Equipment e
LEFT JOIN Maintenance_Log ml ON e.Equip_ID = ml.Equip_ID
GROUP BY e.Equip_ID, e.Name, e.Type
ORDER BY Total_Cost DESC;

-- ============================================
-- J. CROSS-CLUB VOLUNTEERS VIEW
-- ============================================
DROP VIEW IF EXISTS Cross_Club_Volunteers;
CREATE VIEW Cross_Club_Volunteers AS
SELECT 
    s.Student_ID,
    s.Name,
    GROUP_CONCAT(DISTINCT mc.Name ORDER BY mc.Name SEPARATOR ', ') AS Home_Clubs,
    COALESCE(SUM(CASE 
        WHEN ev.Primary_Club_ID NOT IN (
            SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
        ) THEN vl.Hours_Worked 
        ELSE 0 
    END), 0) AS Cross_Club_Hours,
    COUNT(DISTINCT CASE 
        WHEN ev.Primary_Club_ID NOT IN (
            SELECT m3.Club_ID FROM Membership m3 WHERE m3.Student_ID = s.Student_ID
        ) THEN vl.Event_ID 
    END) AS Cross_Club_Events,
    GROUP_CONCAT(DISTINCT CASE 
        WHEN ev.Primary_Club_ID NOT IN (
            SELECT m4.Club_ID FROM Membership m4 WHERE m4.Student_ID = s.Student_ID
        ) THEN hc.Name 
    END ORDER BY hc.Name SEPARATOR ', ') AS Clubs_Helped
FROM Student s
JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
JOIN Event ev ON vl.Event_ID = ev.Event_ID
LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
LEFT JOIN Club mc ON m.Club_ID = mc.Club_ID
LEFT JOIN Club hc ON ev.Primary_Club_ID = hc.Club_ID
GROUP BY s.Student_ID, s.Name
HAVING Cross_Club_Hours > 0
ORDER BY Cross_Club_Hours DESC;

-- ============================================
-- K. BOOKING CONFLICTS REPORT VIEW
-- ============================================
DROP VIEW IF EXISTS Booking_Conflicts_Report;
CREATE VIEW Booking_Conflicts_Report AS
SELECT 
    rb1.Booking_ID AS Booking_1_ID,
    rb2.Booking_ID AS Booking_2_ID,
    e.Name AS Equipment_Name,
    ev1.Title AS Event_1,
    ev2.Title AS Event_2,
    rb1.Borrow_Time AS Booking_1_Start,
    rb1.Return_Time AS Booking_1_End,
    rb2.Borrow_Time AS Booking_2_Start,
    rb2.Return_Time AS Booking_2_End,
    'CONFLICT DETECTED' AS Status
FROM Resource_Booking rb1
JOIN Resource_Booking rb2 ON rb1.Equip_ID = rb2.Equip_ID 
    AND rb1.Booking_ID < rb2.Booking_ID
    AND rb1.Status = 'Confirmed' 
    AND rb2.Status = 'Confirmed'
    AND (rb1.Borrow_Time < rb2.Return_Time AND rb1.Return_Time > rb2.Borrow_Time)
JOIN Equipment e ON rb1.Equip_ID = e.Equip_ID
JOIN Event ev1 ON rb1.Event_ID = ev1.Event_ID
JOIN Event ev2 ON rb2.Event_ID = ev2.Event_ID
ORDER BY e.Name, rb1.Borrow_Time;
