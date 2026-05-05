USE club_collab;

-- ============================================
-- COMPLEX ANALYTICS QUERIES
-- ============================================

-- ============================================
-- A. TOP CROSS-CLUB VOLUNTEER
-- ============================================
-- Find student with most volunteer hours in clubs they're NOT a member of
DROP PROCEDURE IF EXISTS Get_Top_Cross_Club_Volunteer;
DELIMITER //
CREATE PROCEDURE Get_Top_Cross_Club_Volunteer()
BEGIN
    SELECT 
        s.Student_ID,
        s.Name,
        s.Email,
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
    GROUP BY s.Student_ID, s.Name, s.Email
    HAVING Cross_Club_Hours > 0
    ORDER BY Cross_Club_Hours DESC
    LIMIT 1;
END//
DELIMITER ;

-- ============================================
-- B. EQUIPMENT UTILIZATION ANALYSIS
-- ============================================
DROP PROCEDURE IF EXISTS Get_Equipment_Utilization;
DELIMITER //
CREATE PROCEDURE Get_Equipment_Utilization()
BEGIN
    SELECT 
        e.Equip_ID,
        e.Name,
        e.Type,
        e.Status,
        c.Name AS Owner_Club,
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
        ROUND(COUNT(rb.Booking_ID) / 
            GREATEST(TIMESTAMPDIFF(MONTH, e.Purchase_Date, CURDATE()), 1), 2) AS Bookings_Per_Month,
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

-- ============================================
-- C. CLUB COLLABORATION NETWORK
-- ============================================
DROP PROCEDURE IF EXISTS Get_Club_Collaboration_Network;
DELIMITER //
CREATE PROCEDURE Get_Club_Collaboration_Network()
BEGIN
    SELECT 
        c1.Name AS Club_1,
        c2.Name AS Club_2,
        COUNT(DISTINCT col.Event_ID) AS Collaborations_Count,
        COUNT(DISTINCT rb1.Equip_ID) AS Shared_Equipment_Usage,
        GROUP_CONCAT(DISTINCT e.Title ORDER BY e.Date DESC SEPARATOR ' | ') AS Recent_Events,
        CASE 
            WHEN COUNT(DISTINCT col.Event_ID) >= 5 THEN 'Strong Partnership'
            WHEN COUNT(DISTINCT col.Event_ID) >= 3 THEN 'Moderate Partnership'
            WHEN COUNT(DISTINCT col.Event_ID) >= 1 THEN 'Emerging Partnership'
            ELSE 'No Partnership'
        END AS Partnership_Strength,
        ROUND((COUNT(DISTINCT col.Event_ID) * 10 + 
               COUNT(DISTINCT rb1.Equip_ID) * 5) / 15.0, 2) AS Collaboration_Score
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

-- ============================================
-- D. EVENT SUCCESS METRICS
-- ============================================
DROP PROCEDURE IF EXISTS Get_Event_Success_Metrics;
DELIMITER //
CREATE PROCEDURE Get_Event_Success_Metrics()
BEGIN
    SELECT 
        e.Event_ID,
        e.Title,
        e.Date,
        e.Venue,
        c.Name AS Primary_Club,
        COUNT(DISTINCT vl.Student_ID) AS Volunteers_Count,
        COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Volunteer_Hours,
        COUNT(DISTINCT col.Partner_Club_ID) AS Partner_Clubs_Count,
        COUNT(DISTINCT rb.Equip_ID) AS Equipment_Used,
        COUNT(DISTINCT CASE 
            WHEN ev2.Primary_Club_ID NOT IN (
                SELECT m.Club_ID FROM Membership m WHERE m.Student_ID = vl.Student_ID
            ) THEN vl.Student_ID 
        END) AS Cross_Club_Volunteers,
        CASE 
            WHEN COUNT(DISTINCT vl.Student_ID) >= 10 AND COUNT(DISTINCT col.Partner_Club_ID) >= 3 THEN 'Large'
            WHEN COUNT(DISTINCT vl.Student_ID) >= 5 AND COUNT(DISTINCT col.Partner_Club_ID) >= 2 THEN 'Medium'
            ELSE 'Small'
        END AS Event_Scale,
        ROUND(
            (COUNT(DISTINCT vl.Student_ID) * 5 + 
             COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
             COUNT(DISTINCT col.Partner_Club_ID) * 10 + 
             COUNT(DISTINCT rb.Equip_ID) * 3 +
             COUNT(DISTINCT CASE 
                WHEN ev2.Primary_Club_ID NOT IN (
                    SELECT m.Club_ID FROM Membership m WHERE m.Student_ID = vl.Student_ID
                ) THEN vl.Student_ID 
             END) * 8) / 28.0, 2
        ) AS Success_Score,
        RANK() OVER (ORDER BY 
            (COUNT(DISTINCT vl.Student_ID) * 5 + 
             COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
             COUNT(DISTINCT col.Partner_Club_ID) * 10 + 
             COUNT(DISTINCT rb.Equip_ID) * 3 +
             COUNT(DISTINCT CASE 
                WHEN ev2.Primary_Club_ID NOT IN (
                    SELECT m.Club_ID FROM Membership m WHERE m.Student_ID = vl.Student_ID
                ) THEN vl.Student_ID 
             END) * 8) DESC
        ) AS Success_Rank
    FROM Event e
    JOIN Club c ON e.Primary_Club_ID = c.Club_ID
    LEFT JOIN Volunteer_Log vl ON e.Event_ID = vl.Event_ID
    LEFT JOIN Collaboration col ON e.Event_ID = col.Event_ID
    LEFT JOIN Resource_Booking rb ON e.Event_ID = rb.Event_ID
    LEFT JOIN Event ev2 ON vl.Event_ID = ev2.Event_ID
    GROUP BY e.Event_ID, e.Title, e.Date, e.Venue, c.Name
    ORDER BY Success_Score DESC;
END//
DELIMITER ;

-- ============================================
-- E. STUDENT ENGAGEMENT RANKING
-- ============================================
DROP PROCEDURE IF EXISTS Get_Student_Engagement_Ranking;
DELIMITER //
CREATE PROCEDURE Get_Student_Engagement_Ranking()
BEGIN
    SELECT 
        s.Student_ID,
        s.Name,
        s.Email,
        COALESCE(SUM(vl.Hours_Worked), 0) AS Total_Hours,
        COUNT(DISTINCT vl.Event_ID) AS Events_Volunteered,
        COUNT(DISTINCT CASE 
            WHEN ev.Primary_Club_ID NOT IN (
                SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
            ) THEN vl.Event_ID 
        END) AS Cross_Club_Events,
        COUNT(DISTINCT m.Club_ID) AS Clubs_Joined,
        CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
             THEN 1 ELSE 0 END AS Is_Executive,
        COUNT(DISTINCT vl.Role) AS Different_Roles,
        ROUND(
            (COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
             COUNT(DISTINCT vl.Event_ID) * 5 + 
             COUNT(DISTINCT CASE 
                WHEN ev.Primary_Club_ID NOT IN (
                    SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
                ) THEN vl.Event_ID 
             END) * 10 + 
             COUNT(DISTINCT m.Club_ID) * 3 + 
             CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
                  THEN 20 ELSE 0 END + 
             COUNT(DISTINCT vl.Role) * 5) / 45.0, 2
        ) AS Engagement_Score,
        CASE 
            WHEN ROUND(
                (COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
                 COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT CASE 
                    WHEN ev.Primary_Club_ID NOT IN (
                        SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
                    ) THEN vl.Event_ID 
                 END) * 10 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
                      THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 45.0, 2
            ) >= 80 THEN 'Champion'
            WHEN ROUND(
                (COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
                 COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT CASE 
                    WHEN ev.Primary_Club_ID NOT IN (
                        SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
                    ) THEN vl.Event_ID 
                 END) * 10 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
                      THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 45.0, 2
            ) >= 60 THEN 'Active'
            WHEN ROUND(
                (COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
                 COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT CASE 
                    WHEN ev.Primary_Club_ID NOT IN (
                        SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
                    ) THEN vl.Event_ID 
                 END) * 10 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
                      THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 45.0, 2
            ) >= 40 THEN 'Engaged'
            WHEN ROUND(
                (COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
                 COUNT(DISTINCT vl.Event_ID) * 5 + 
                 COUNT(DISTINCT CASE 
                    WHEN ev.Primary_Club_ID NOT IN (
                        SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
                    ) THEN vl.Event_ID 
                 END) * 10 + 
                 COUNT(DISTINCT m.Club_ID) * 3 + 
                 CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
                      THEN 20 ELSE 0 END + 
                 COUNT(DISTINCT vl.Role) * 5) / 45.0, 2
            ) >= 20 THEN 'Participant'
            ELSE 'Inactive'
        END AS Engagement_Category,
        RANK() OVER (ORDER BY 
            (COALESCE(SUM(vl.Hours_Worked), 0) * 2 + 
             COUNT(DISTINCT vl.Event_ID) * 5 + 
             COUNT(DISTINCT CASE 
                WHEN ev.Primary_Club_ID NOT IN (
                    SELECT m2.Club_ID FROM Membership m2 WHERE m2.Student_ID = s.Student_ID
                ) THEN vl.Event_ID 
             END) * 10 + 
             COUNT(DISTINCT m.Club_ID) * 3 + 
             CASE WHEN EXISTS (SELECT 1 FROM Club_Executive ce WHERE ce.Student_ID = s.Student_ID) 
                  THEN 20 ELSE 0 END + 
             COUNT(DISTINCT vl.Role) * 5) DESC
        ) AS Overall_Rank
    FROM Student s
    LEFT JOIN Volunteer_Log vl ON s.Student_ID = vl.Student_ID
    LEFT JOIN Event ev ON vl.Event_ID = ev.Event_ID
    LEFT JOIN Membership m ON s.Student_ID = m.Student_ID
    GROUP BY s.Student_ID, s.Name, s.Email
    ORDER BY Engagement_Score DESC;
END//
DELIMITER ;

-- ============================================
-- F. BOOKING PATTERN ANALYSIS
-- ============================================
DROP PROCEDURE IF EXISTS Get_Booking_Pattern_Analysis;
DELIMITER //
CREATE PROCEDURE Get_Booking_Pattern_Analysis()
BEGIN
    SELECT 
        DAYNAME(rb.Borrow_Time) AS Day_Of_Week,
        HOUR(rb.Borrow_Time) AS Hour_Of_Day,
        COUNT(*) AS Booking_Count,
        e.Type AS Equipment_Type,
        ROUND(AVG(TIMESTAMPDIFF(HOUR, rb.Borrow_Time, rb.Return_Time)), 2) AS Avg_Duration_Hours,
        CASE 
            WHEN COUNT(*) >= 10 THEN 'High Demand'
            WHEN COUNT(*) >= 5 THEN 'Moderate Demand'
            ELSE 'Low Demand'
        END AS Demand_Level,
        GROUP_CONCAT(DISTINCT ev.Title ORDER BY rb.Borrow_Time DESC SEPARATOR ' | ') AS Recent_Events
    FROM Resource_Booking rb
    JOIN Equipment e ON rb.Equip_ID = e.Equip_ID
    JOIN Event ev ON rb.Event_ID = ev.Event_ID
    WHERE rb.Status IN ('Confirmed', 'Completed')
    GROUP BY DAYNAME(rb.Borrow_Time), HOUR(rb.Borrow_Time), e.Type
    ORDER BY Booking_Count DESC, Day_Of_Week, Hour_Of_Day;
END//
DELIMITER ;
