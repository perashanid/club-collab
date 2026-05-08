﻿let equipmentData = [];
let clubsData = [];
let studentsData = [];
let eventsData = [];
let volunteersData = [];
let bookingsData = [];
let badgesData = [];
let leaderboardData = [];
let maintenanceData = [];
let membershipsData = [];
let currentUser = null;

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    bindNavLinks();
    bindHeaderButtons();
    bindSearch();
    bindTableActions();
    bindCRUDButtons();
    bindAnalyticsTabs();
    fetchAllData();
});

function checkAuth() {
    const user = localStorage.getItem('user');
    if (!user) {
        window.location.href = 'login.html';
        return;
    }

    currentUser = JSON.parse(user);
    document.getElementById('userName').textContent = currentUser.Name;

    // Setup logout
    document.getElementById('logoutBtn').addEventListener('click', () => {
        localStorage.removeItem('user');
        window.location.href = 'login.html';
    });
}

function bindAnalyticsTabs() {
    const tabBtns = document.querySelectorAll('.tab-btn');
    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            // Remove active from all
            tabBtns.forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.analytics-tab-content').forEach(c => c.classList.remove('active'));
            
            // Add active to clicked
            btn.classList.add('active');
            const tabId = 'tab-' + btn.dataset.tab;
            document.getElementById(tabId).classList.add('active');
        });
    });
}

function bindNavLinks() {
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', event => {
            event.preventDefault();
            const target = link.dataset.target;
            switchSection(target);
            setActiveLink(link);
            closeSidebarOnMobile();
        });
    });

    const placeholderButtons = document.querySelectorAll('.placeholder-card .btn-primary');
    placeholderButtons.forEach(button => {
        button.addEventListener('click', () => {
            const target = button.id.replace('Placeholder', '').toLowerCase();
            switchSection(target);
            const matchingLink = document.querySelector(`.nav-link[data-target="${target}"]`);
            if (matchingLink) setActiveLink(matchingLink);
            closeSidebarOnMobile();
        });
    });
}

function bindHeaderButtons() {
    const navToggle = document.getElementById('navToggle');
    const sidebar = document.getElementById('sidebar');

    navToggle?.addEventListener('click', () => {
        sidebar?.classList.toggle('show');
    });

    // Add Equipment button (multiple instances)
    document.querySelectorAll('#addEquipmentBtn').forEach(btn => {
        btn.addEventListener('click', addEquipment);
    });
    
    // Add Booking button
    document.getElementById('addBookingBtn')?.addEventListener('click', addBooking);
    
    // Add Club button
    document.getElementById('addClubBtn')?.addEventListener('click', addClub);
    
    // Add Student button
    document.getElementById('addStudentBtn')?.addEventListener('click', addStudent);
    
    // Add Event button
    document.getElementById('addEventBtn')?.addEventListener('click', addEvent);
    
    // Add Maintenance button
    document.getElementById('addMaintenanceBtn')?.addEventListener('click', addMaintenance);
    
    // Add Membership button
    document.getElementById('addMembershipBtn')?.addEventListener('click', addMembership);
    
    // Add Volunteer Log button
    document.getElementById('addVolunteerLogBtn')?.addEventListener('click', addVolunteerLog);
    
    // Add Volunteer button
    document.getElementById('addVolunteerBtn')?.addEventListener('click', addVolunteer);
}

function bindSearch() {
    const searchInput = document.getElementById('searchInput');
    searchInput?.addEventListener('keyup', function(e) {
        const term = e.target.value.toLowerCase();
        const rows = document.querySelectorAll('#tableBody tr');
        rows.forEach(row => {
            const text = row.innerText.toLowerCase();
            row.style.display = text.includes(term) ? '' : 'none';
        });
    });
}

function bindTableActions() {
    // Bind to both dashboard and equipment section tables
    document.getElementById('tableBody')?.addEventListener('click', handleEquipmentTableClick);
    document.getElementById('equipmentBody')?.addEventListener('click', handleEquipmentTableClick);
}

function handleEquipmentTableClick(event) {
    const button = event.target.closest('button');
    if (!button) return;
    const row = button.closest('tr');
    const id = row?.querySelector('td')?.innerText || '#0';

    if (button.title === 'Edit') {
        alert(`Edit mode not available yet for ${id}.`);
    }
    if (button.title === 'Delete') {
        if (confirm(`Delete ${id}? This will only remove the row from the screen.`)) {
            row.remove();
            equipmentData = equipmentData.filter(item => `#${item.Equip_ID}` !== id);
            updateKPIs(equipmentData);
        }
    }
}

function switchSection(target) {
    const sections = document.querySelectorAll('.section');
    sections.forEach(section => {
        section.classList.toggle('active', section.id === `section-${target}`);
    });

    const titles = {
        dashboard: 'Equipment Dashboard',
        clubs: 'Clubs Overview',
        students: 'Students Overview',
        equipment: 'Equipment Manager',
        maintenance: 'Maintenance Logs',
        events: 'Events Overview',
        bookings: 'Resource Bookings',
        volunteers: 'Volunteers Overview',
        memberships: 'Club Memberships',
        leaderboard: 'Volunteer Leaderboard',
        badges: 'Volunteer Badges & Leaderboard',
        bidding: 'Equipment Bidding',
        analytics: 'Analytics & Reports'
    };

    document.getElementById('pageTitle').innerText = titles[target] || 'Club-Collab';
    
    // Auto-load analytics data when analytics section is opened
    if (target === 'analytics') {
        setTimeout(() => {
            loadEquipmentUtilization();
            loadClubCollaboration();
            loadEventSuccess();
            loadStudentEngagement();
            loadBookingPatterns();
        }, 100);
    }
    
    // Auto-load leaderboard data when leaderboard section is opened
    if (target === 'leaderboard') {
        setTimeout(() => {
            fetchLeaderboard();
            fetchClubLeaderboard();
        }, 100);
    }
    
    // Auto-load bidding data when bidding section is opened
    if (target === 'bidding') {
        setTimeout(() => {
            loadBiddingData();
        }, 100);
    }
}

function setActiveLink(link) {
    document.querySelectorAll('.nav-link').forEach(item => item.classList.remove('active'));
    link.classList.add('active');
}

function closeSidebarOnMobile() {
    const sidebar = document.getElementById('sidebar');
    if (window.innerWidth <= 1100) {
        sidebar?.classList.remove('show');
    }
}

async function fetchAllData() {
    await Promise.all([
        fetchEquipment(),
        fetchClubs(),
        fetchStudents(),
        fetchEvents(),
        fetchVolunteers(),
        fetchBookings(),
        fetchBadges(),
        fetchLeaderboard(),
        fetchMaintenance(),
        fetchMemberships()
    ]);
}

async function fetchEquipment() {
    const tableBody = document.getElementById('tableBody');
    try {
        const response = await fetch('backend/get_equip.php');
        const data = await response.json();
        if (data.error) {
            tableBody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:red;">Error loading data: ${data.error}</td></tr>`;
            equipmentData = [];
            updateKPIs(equipmentData);
            return;
        }
        equipmentData = Array.isArray(data) ? data : [];
        updateKPIs(equipmentData);
        renderEquipmentRows(equipmentData);
    } catch (error) {
        console.error('Error fetching equipment:', error);
        tableBody.innerHTML = `<tr><td colspan="6" style="text-align:center;">Failed to connect to the backend.</td></tr>`;
    }
}

async function fetchClubs() {
    const clubsBody = document.getElementById('clubsBody');
    try {
        const response = await fetch('backend/get_clubs.php');
        const data = await response.json();
        if (data.error) {
            clubsBody.innerHTML = `<tr><td colspan="7" style="text-align:center; color:red;">Error loading clubs: ${data.error}</td></tr>`;
            clubsData = [];
            updateClubSummary();
            return;
        }
        clubsData = Array.isArray(data) ? data : [];
        updateClubSummary();
        renderClubRows(clubsData);
    } catch (error) {
        console.error('Error fetching clubs:', error);
        clubsBody.innerHTML = `<tr><td colspan="7" style="text-align:center;">Failed to connect to the backend.</td></tr>`;
    }
}

async function fetchStudents() {
    const studentsBody = document.getElementById('studentsBody');
    try {
        const response = await fetch('backend/get_students.php');
        const data = await response.json();
        if (data.error) {
            studentsBody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:red;">Error loading students: ${data.error}</td></tr>`;
            studentsData = [];
            updateStudentSummary();
            return;
        }
        studentsData = Array.isArray(data) ? data : [];
        updateStudentSummary();
        renderStudentRows(studentsData);
    } catch (error) {
        console.error('Error fetching students:', error);
        studentsBody.innerHTML = `<tr><td colspan="6" style="text-align:center;">Failed to connect to the backend.</td></tr>`;
    }
}

async function fetchEvents() {
    const eventsBody = document.getElementById('eventsBody');
    try {
        const response = await fetch('backend/get_events.php');
        const data = await response.json();
        if (data.error) {
            eventsBody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:red;">Error loading events: ${data.error}</td></tr>`;
            eventsData = [];
            updateEventSummary();
            return;
        }
        eventsData = Array.isArray(data) ? data : [];
        updateEventSummary();
        renderEventRows(eventsData);
    } catch (error) {
        console.error('Error fetching events:', error);
        eventsBody.innerHTML = `<tr><td colspan="6" style="text-align:center;">Failed to connect to the backend.</td></tr>`;
    }
}

async function fetchVolunteers() {
    const volunteersBody = document.getElementById('volunteersBody');
    try {
        const response = await fetch('backend/get_volunteers.php');
        const data = await response.json();
        if (data.error) {
            volunteersBody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:red;">Error loading volunteers: ${data.error}</td></tr>`;
            volunteersData = [];
            updateVolunteerSummary();
            return;
        }
        volunteersData = Array.isArray(data) ? data : [];
        updateVolunteerSummary();
        renderVolunteerRows(volunteersData);
    } catch (error) {
        console.error('Error fetching volunteers:', error);
        volunteersBody.innerHTML = `<tr><td colspan="6" style="text-align:center;">Failed to connect to the backend.</td></tr>`;
    }
}

async function fetchBookings() {
    const bookingsBody = document.getElementById('bookingsBody');
    try {
        const response = await fetch('backend/get_bookings.php');
        const data = await response.json();
        if (data.error) {
            if(bookingsBody) bookingsBody.innerHTML = `<tr><td colspan="7" style="text-align:center; color:red;">Error loading bookings: ${data.error}</td></tr>`;
            bookingsData = [];
            return;
        }
        bookingsData = Array.isArray(data) ? data : [];
        if(bookingsBody) renderBookingRows(bookingsData);
    } catch (error) {
        console.error('Error fetching bookings:', error);
        if(bookingsBody) bookingsBody.innerHTML = `<tr><td colspan="7" style="text-align:center;">Failed to connect to the backend.</td></tr>`;
    }
}

function renderEquipmentRows(data) {
    const tableBody = document.getElementById('tableBody');
    const equipmentBody = document.getElementById('equipmentBody');
    
    const html = generateEquipmentHTML(data);
    
    if (tableBody) tableBody.innerHTML = html;
    if (equipmentBody) equipmentBody.innerHTML = html;
}

function generateEquipmentHTML(data) {
    if (!Array.isArray(data) || data.length === 0) {
        return `<tr><td colspan="6" style="text-align:center;">No equipment found. Add some in phpMyAdmin!</td></tr>`;
    }

    let html = '';
    data.forEach(item => {
        const statusClass = (item.Status || '').toLowerCase().replace(/\s+/g, '-');
        html += `
            <tr>
                <td>#${item.Equip_ID}</td>
                <td><strong>${item.EquipName}</strong></td>
                <td>${item.Type}</td>
                <td>${item.ClubName || 'Unassigned'}</td>
                <td><span class="status ${statusClass}">${item.Status}</span></td>
                <td>
                    <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                    <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
                </td>
            </tr>
        `;
    });
    return html;
}

function renderClubRows(data) {
    const clubsBody = document.getElementById('clubsBody');
    clubsBody.innerHTML = '';

    if (!Array.isArray(data) || data.length === 0) {
        clubsBody.innerHTML = `<tr><td colspan="8" style="text-align:center;">No clubs found.</td></tr>`;
        return;
    }

    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>#${item.Club_ID}</td>
            <td>${item.ClubName}</td>
            <td>${item.Department}</td>
            <td>${item.Office}</td>
            <td>${item.Founded}</td>
            <td>${item.MemberCount}</td>
            <td>${item.ContactEmails || 'N/A'}</td>
            <td>
                <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
            </td>
        `;
        clubsBody.appendChild(row);
    });
}

function renderStudentRows(data) {
    const studentsBody = document.getElementById('studentsBody');
    studentsBody.innerHTML = '';

    if (!Array.isArray(data) || data.length === 0) {
        studentsBody.innerHTML = `<tr><td colspan="7" style="text-align:center;">No student records found.</td></tr>`;
        return;
    }

    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>#${item.Student_ID}</td>
            <td>${item.StudentName}</td>
            <td>${item.Email}</td>
            <td>${item.Major || 'N/A'}</td>
            <td>${item.YearOfStudy || 'N/A'}</td>
            <td>${item.ClubsAndRoles || 'No club assignment'}</td>
            <td>
                <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
            </td>
        `;
        studentsBody.appendChild(row);
    });
}

function renderEventRows(data) {
    const eventsBody = document.getElementById('eventsBody');
    eventsBody.innerHTML = '';

    if (!Array.isArray(data) || data.length === 0) {
        eventsBody.innerHTML = `<tr><td colspan="8" style="text-align:center;">No events found.</td></tr>`;
        return;
    }

    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>#${item.Event_ID}</td>
            <td>${item.Title}</td>
            <td>${item.Date}</td>
            <td>${item.Venue}</td>
            <td>${item.HostClub || 'Unknown'}</td>
            <td>${item.PartnerCount}</td>
            <td>${item.BookingCount}</td>
            <td>
                <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
            </td>
        `;
        eventsBody.appendChild(row);
    });
}

function renderVolunteerRows(data) {
    const volunteersBody = document.getElementById('volunteersBody');
    volunteersBody.innerHTML = '';

    if (!Array.isArray(data) || data.length === 0) {
        volunteersBody.innerHTML = `<tr><td colspan="7" style="text-align:center;">No volunteer activity found.</td></tr>`;
        return;
    }

    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>#${item.Log_ID}</td>
            <td>${item.StudentName || 'Unknown'}</td>
            <td>${item.EventTitle || 'Unknown'}</td>
            <td>${item.Role}</td>
            <td>${item.HoursWorked}</td>
            <td>${item.VerifiedBy || 'N/A'}</td>
            <td>
                <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
            </td>
        `;
        volunteersBody.appendChild(row);
    });
}

function renderBookingRows(data) {
    const bookingsBody = document.getElementById('bookingsBody');
    if(!bookingsBody) return;
    
    bookingsBody.innerHTML = '';

    if (!Array.isArray(data) || data.length === 0) {
        bookingsBody.innerHTML = `<tr><td colspan="7" style="text-align:center;">No resource bookings found.</td></tr>`;
        return;
    }

    data.forEach(item => {
        const statusClass = (item.Status || '').toLowerCase();
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>#${item.Booking_ID}</td>
            <td>${item.EquipName || item.Equip_ID}</td>
            <td>${item.EventTitle || item.Event_ID}</td>
            <td>${item.Borrow_Time}</td>
            <td>${item.Return_Time}</td>
            <td><span class="status ${statusClass}">${item.Status}</span></td>
            <td>
                <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
            </td>
        `;
        bookingsBody.appendChild(row);
    });
    
    updateBookingSummary();
}

async function fetchMaintenance() {
    try {
        const response = await fetch('backend/maintenance.php');
        const data = await response.json();
        if (data.error) {
            console.error('Error loading maintenance:', data.error);
            maintenanceData = [];
            return;
        }
        maintenanceData = Array.isArray(data) ? data : [];
        renderMaintenanceRows(maintenanceData);
        updateMaintenanceSummary();
    } catch (error) {
        console.error('Error fetching maintenance:', error);
        maintenanceData = [];
    }
}

async function fetchMemberships() {
    try {
        const response = await fetch('backend/memberships.php');
        const data = await response.json();
        if (data.error) {
            console.error('Error loading memberships:', data.error);
            membershipsData = [];
            return;
        }
        membershipsData = Array.isArray(data) ? data : [];
        renderMembershipRows(membershipsData);
        updateMembershipSummary();
    } catch (error) {
        console.error('Error fetching memberships:', error);
        membershipsData = [];
    }
}

function renderMaintenanceRows(data) {
    const maintenanceBody = document.getElementById('maintenanceBody');
    if (!maintenanceBody) return;
    
    maintenanceBody.innerHTML = '';

    if (!Array.isArray(data) || data.length === 0) {
        maintenanceBody.innerHTML = `<tr><td colspan="5" style="text-align:center;">No maintenance logs found.</td></tr>`;
        return;
    }

    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.EquipName || item.Equip_ID}</td>
            <td>${item.Maintenance_Date}</td>
            <td>${item.Description}</td>
            <td>$${parseFloat(item.Cost || 0).toFixed(2)}</td>
            <td>
                <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
            </td>
        `;
        maintenanceBody.appendChild(row);
    });
}

function renderMembershipRows(data) {
    const membershipsBody = document.getElementById('membershipsBody');
    if (!membershipsBody) return;
    
    membershipsBody.innerHTML = '';

    if (!Array.isArray(data) || data.length === 0) {
        membershipsBody.innerHTML = `<tr><td colspan="5" style="text-align:center;">No memberships found.</td></tr>`;
        return;
    }

    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.StudentName || item.Student_ID}</td>
            <td>${item.ClubName || item.Club_ID}</td>
            <td><span class="status">${item.Role}</span></td>
            <td>${item.Join_Date}</td>
            <td>
                <button class="action-btn" title="Edit"><i class="fa-solid fa-pen"></i></button>
                <button class="action-btn" title="Delete"><i class="fa-solid fa-trash"></i></button>
            </td>
        `;
        membershipsBody.appendChild(row);
    });
}

function updateMaintenanceSummary() {
    const totalEl = document.getElementById('totalMaintenance');
    const costEl = document.getElementById('totalMaintenanceCost');
    const monthEl = document.getElementById('maintenanceThisMonth');
    
    if (totalEl) totalEl.textContent = maintenanceData.length;
    
    const totalCost = maintenanceData.reduce((sum, item) => sum + parseFloat(item.Cost || 0), 0);
    if (costEl) costEl.textContent = `$${totalCost.toFixed(2)}`;
    
    const thisMonth = new Date().getMonth();
    const thisYear = new Date().getFullYear();
    const monthCount = maintenanceData.filter(item => {
        const date = new Date(item.Maintenance_Date);
        return date.getMonth() === thisMonth && date.getFullYear() === thisYear;
    }).length;
    if (monthEl) monthEl.textContent = monthCount;
}

function updateMembershipSummary() {
    const totalEl = document.getElementById('totalMemberships');
    const execEl = document.getElementById('executiveMemberships');
    const activeEl = document.getElementById('activeMemberships');
    
    if (totalEl) totalEl.textContent = membershipsData.length;
    
    const executives = membershipsData.filter(m => m.Role === 'Executive').length;
    if (execEl) execEl.textContent = executives;
    
    const active = membershipsData.filter(m => m.Role === 'Member' || m.Role === 'Volunteer').length;
    if (activeEl) activeEl.textContent = active;
}

function updateKPIs(data) {
    if (!Array.isArray(data)) return;
    document.getElementById('totalEquip').innerText = data.length;
    const available = data.filter(item => item.Status === 'Available').length;
    document.getElementById('availEquip').innerText = available;
    const damaged = data.filter(item => item.Status === 'Damaged' || item.Status === 'Maintenance').length;
    document.getElementById('damagedEquip').innerText = damaged;
}

function updateClubSummary() {
    document.getElementById('totalClubs').innerText = clubsData.length;
    const members = clubsData.reduce((sum, item) => sum + Number(item.MemberCount || 0), 0);
    document.getElementById('totalMembers').innerText = members;
    document.getElementById('clubContacts').innerText = clubsData.filter(item => item.ContactEmails).length;
}

function updateStudentSummary() {
    document.getElementById('totalStudents').innerText = studentsData.length;
    const execCount = studentsData.filter(item => item.ClubsAndRoles && item.ClubsAndRoles.toLowerCase().includes('executive')).length;
    document.getElementById('executiveCount').innerText = execCount;
    const majorCount = new Set(studentsData.map(item => item.Major).filter(Boolean)).size;
    document.getElementById('majorCount').innerText = majorCount;
}

function updateEventSummary() {
    document.getElementById('totalEvents').innerText = eventsData.length;
    const partnerCount = eventsData.reduce((sum, item) => sum + Number(item.PartnerCount || 0), 0);
    document.getElementById('partnerClubs').innerText = partnerCount;
    const bookingCount = eventsData.reduce((sum, item) => sum + Number(item.BookingCount || 0), 0);
    document.getElementById('bookedEquipment').innerText = bookingCount;
}

function updateVolunteerSummary() {
    const hours = volunteersData.reduce((sum, item) => sum + Number(item.HoursWorked || 0), 0);
    document.getElementById('totalVolunteerHours').innerText = hours.toFixed(2);
    document.getElementById('totalVolunteerLogs').innerText = volunteersData.length;
    const verifiedCount = new Set(volunteersData.map(item => item.VerifiedBy).filter(Boolean)).size;
    document.getElementById('verifiedCount').innerText = verifiedCount;
}

function bindCRUDButtons() {
    // Bind edit/delete buttons in tables
    document.addEventListener('click', handleTableButtonClick);

    // Modal controls
    document.getElementById('modalClose').addEventListener('click', closeModal);
    document.getElementById('modalCancel').addEventListener('click', closeModal);

    // Form submission
    document.getElementById('crudForm').addEventListener('submit', handleFormSubmit);
}

function handleTableButtonClick(e) {
    const button = e.target.closest('.action-btn');
    if (!button) return;

    const row = button.closest('tr');
    const table = button.closest('table');
    const action = button.title.toLowerCase();
    const id = row.querySelector('td')?.textContent.replace('#', '');

    if (!id) return;

    // Determine which section/table we're in
    let section = '';
    if (table.id === 'equipmentTable') section = 'equipment';
    else if (table.id === 'clubsTable') section = 'clubs';
    else if (table.id === 'studentsTable') section = 'students';
    else if (table.id === 'eventsTable') section = 'events';
    else if (table.id === 'volunteersTable') section = 'volunteers';
    else if (table.id === 'bookingsTable') section = 'bookings';

    if (action === 'edit') {
        openEditModal(section, id);
    } else if (action === 'delete') {
        handleDelete(section, id, row);
    }
}

function openEditModal(section, id) {
    // Check permissions
    if (currentUser.role !== 'admin' && section !== 'volunteers') {
        alert('You do not have permission to edit this item.');
        return;
    }

    let data = null;
    let endpoint = '';

    // Find the data for this ID
    switch (section) {
        case 'equipment':
            data = equipmentData.find(item => item.Equip_ID == id);
            endpoint = 'equipment.php';
            break;
        case 'clubs':
            data = clubsData.find(item => item.Club_ID == id);
            endpoint = 'clubs_api.php';
            break;
        case 'students':
            data = studentsData.find(item => item.Student_ID == id);
            endpoint = 'students_api.php';
            break;
        case 'events':
            data = eventsData.find(item => item.Event_ID == id);
            endpoint = 'events.php';
            break;
        case 'volunteers':
            data = volunteersData.find(item => item.Log_ID == id);
            endpoint = 'crud_volunteers.php';
            break;
        case 'bookings':
            data = bookingsData.find(item => item.Booking_ID == id);
            endpoint = 'crud_bookings.php';
            break;
        case 'maintenance':
            data = maintenanceData.find(item => item.Equip_ID == id && item.Maintenance_Date == data.Maintenance_Date);
            endpoint = 'maintenance.php';
            break;
        case 'memberships':
            data = membershipsData.find(item => item.Student_ID == id);
            endpoint = 'memberships.php';
            break;
    }

    if (!data) {
        alert('Item not found.');
        return;
    }

    // Generate form based on section
    const formHtml = generateFormHtml(section, data);
    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = section;
    document.getElementById('crudForm').dataset.id = id;
    document.getElementById('crudForm').dataset.endpoint = endpoint;
    document.getElementById('crudForm').dataset.method = 'PUT';

    document.getElementById('modalTitle').textContent = `Edit ${section.charAt(0).toUpperCase() + section.slice(1)}`;
    document.getElementById('crudModal').style.display = 'flex';
}

function generateFormHtml(section, data) {
    switch (section) {
        case 'equipment':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Name</label>
                        <input type="text" name="name" value="${data.EquipName || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Type</label>
                        <select name="type" required>
                            <option value="Camera" ${data.Type === 'Camera' ? 'selected' : ''}>Camera</option>
                            <option value="Projector" ${data.Type === 'Projector' ? 'selected' : ''}>Projector</option>
                            <option value="Microphone" ${data.Type === 'Microphone' ? 'selected' : ''}>Microphone</option>
                            <option value="Laptop" ${data.Type === 'Laptop' ? 'selected' : ''}>Laptop</option>
                            <option value="Speaker" ${data.Type === 'Speaker' ? 'selected' : ''}>Speaker</option>
                            <option value="Other" ${data.Type === 'Other' ? 'selected' : ''}>Other</option>
                        </select>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Status</label>
                        <select name="status" required>
                            <option value="Available" ${data.Status === 'Available' ? 'selected' : ''}>Available</option>
                            <option value="In-Use" ${data.Status === 'In-Use' ? 'selected' : ''}>In-Use</option>
                            <option value="Damaged" ${data.Status === 'Damaged' ? 'selected' : ''}>Damaged</option>
                            <option value="Maintenance" ${data.Status === 'Maintenance' ? 'selected' : ''}>Maintenance</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Owner Club ID</label>
                        <input type="number" name="owner_club_id" value="${data.Owner_Club_ID || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Purchase Date</label>
                        <input type="date" name="purchase_date" value="${data.Purchase_Date ? data.Purchase_Date.split(' ')[0] : ''}" required>
                    </div>
                </div>
            `;

        case 'bookings':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Equipment ID</label>
                        <input type="number" name="equip_id" value="${data.Equip_ID || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Event ID</label>
                        <input type="number" name="event_id" value="${data.Event_ID || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Borrow Time</label>
                        <input type="datetime-local" name="borrow_time" value="${data.Borrow_Time ? data.Borrow_Time.slice(0, 16) : ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Return Time</label>
                        <input type="datetime-local" name="return_time" value="${data.Return_Time ? data.Return_Time.slice(0, 16) : ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Status</label>
                        <select name="status" required>
                            <option value="Confirmed" ${data.Status === 'Confirmed' ? 'selected' : ''}>Confirmed</option>
                            <option value="Completed" ${data.Status === 'Completed' ? 'selected' : ''}>Completed</option>
                            <option value="Cancelled" ${data.Status === 'Cancelled' ? 'selected' : ''}>Cancelled</option>
                        </select>
                    </div>
                </div>
            `;

        case 'clubs':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Club Name</label>
                        <input type="text" name="name" value="${data.ClubName || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Department</label>
                        <input type="text" name="department" value="${data.Department || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Office Room</label>
                        <input type="text" name="office" value="${data.Office || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Founded Date</label>
                        <input type="date" name="founded" value="${data.Founded ? data.Founded.split(' ')[0] : ''}" required>
                    </div>
                </div>
            `;

        case 'clubs':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Name</label>
                        <input type="text" name="name" value="${data.ClubName || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Department</label>
                        <input type="text" name="department" value="${data.Department || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Office Room</label>
                        <input type="text" name="office" value="${data.Office || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Founded Date</label>
                        <input type="date" name="founded" value="${data.Founded ? data.Founded.split(' ')[0] : ''}" required>
                    </div>
                </div>
            `;

        case 'students':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Name</label>
                        <input type="text" name="name" value="${data.StudentName || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" name="email" value="${data.Email || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Street</label>
                        <input type="text" name="street" value="${data.Street || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>City</label>
                        <input type="text" name="city" value="${data.City || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Zip</label>
                        <input type="text" name="zip" value="${data.Zip || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Contact No</label>
                        <input type="text" name="contact_no" value="${data.Contact_No || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Student Type</label>
                        <select name="student_type" required onchange="toggleStudentFields(this.value)">
                            <option value="general" ${!data.Position ? 'selected' : ''}>General Student</option>
                            <option value="executive" ${data.Position ? 'selected' : ''}>Club Executive</option>
                        </select>
                    </div>
                </div>
                <div id="generalFields" style="display: ${!data.Position ? 'block' : 'none'}">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Year of Study</label>
                            <input type="number" name="year_of_study" min="1" max="4" value="${data.YearOfStudy || ''}">
                        </div>
                        <div class="form-group">
                            <label>Major</label>
                            <input type="text" name="major" value="${data.Major || ''}">
                        </div>
                    </div>
                </div>
                <div id="executiveFields" style="display: ${data.Position ? 'block' : 'none'}">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Position</label>
                            <input type="text" name="position" value="${data.Position || ''}">
                        </div>
                        <div class="form-group">
                            <label>Term Start</label>
                            <input type="date" name="term_start" value="${data.Term_Start ? data.Term_Start.split(' ')[0] : ''}">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Term End</label>
                            <input type="date" name="term_end" value="${data.Term_End ? data.Term_End.split(' ')[0] : ''}">
                        </div>
                    </div>
                </div>
            `;

        case 'events':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Title</label>
                        <input type="text" name="title" value="${data.Title || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Venue</label>
                        <input type="text" name="venue" value="${data.Venue || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Date</label>
                        <input type="date" name="date" value="${data.Date ? data.Date.split(' ')[0] : ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Primary Club ID</label>
                        <input type="number" name="primary_club_id" value="${data.Club_ID || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description">${data.Description || ''}</textarea>
                    </div>
                </div>
            `;

        case 'maintenance':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Equipment</label>
                        <select name="equip_id" required>
                            <option value="">Select Equipment</option>
                            ${equipmentData.map(e => `<option value="${e.Equip_ID}" ${data.Equip_ID == e.Equip_ID ? 'selected' : ''}>${e.EquipName}</option>`).join('')}
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Maintenance Date</label>
                        <input type="date" name="maintenance_date" value="${data.Maintenance_Date ? data.Maintenance_Date.split(' ')[0] : ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description" rows="3" required>${data.Description || ''}</textarea>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Cost ($)</label>
                        <input type="number" name="cost" step="0.01" min="0" value="${data.Cost || ''}" required>
                    </div>
                </div>
            `;

        case 'memberships':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Student</label>
                        <select name="student_id" required>
                            <option value="">Select Student</option>
                            ${studentsData.map(s => `<option value="${s.Student_ID}" ${data.Student_ID == s.Student_ID ? 'selected' : ''}>${s.StudentName}</option>`).join('')}
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Club</label>
                        <select name="club_id" required>
                            <option value="">Select Club</option>
                            ${clubsData.map(c => `<option value="${c.Club_ID}" ${data.Club_ID == c.Club_ID ? 'selected' : ''}>${c.ClubName}</option>`).join('')}
                        </select>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Role</label>
                        <select name="role" required>
                            <option value="Member" ${data.Role === 'Member' ? 'selected' : ''}>Member</option>
                            <option value="Volunteer" ${data.Role === 'Volunteer' ? 'selected' : ''}>Volunteer</option>
                            <option value="Executive" ${data.Role === 'Executive' ? 'selected' : ''}>Executive</option>
                            <option value="Advisor" ${data.Role === 'Advisor' ? 'selected' : ''}>Advisor</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Join Date</label>
                        <input type="date" name="join_date" value="${data.Join_Date ? data.Join_Date.split(' ')[0] : ''}" required>
                    </div>
                </div>
            `;

        case 'volunteers':
            return `
                <div class="form-row">
                    <div class="form-group">
                        <label>Student ID</label>
                        <input type="number" name="student_id" value="${data.Student_ID || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Event ID</label>
                        <input type="number" name="event_id" value="${data.Event_ID || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Role</label>
                        <input type="text" name="role" value="${data.Role || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Hours Worked</label>
                        <input type="number" name="hours_worked" step="0.5" min="0" max="24" value="${data.HoursWorked || ''}" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Verified By (Student ID)</label>
                        <input type="number" name="verified_by" value="${data.Verified_By || ''}" required>
                    </div>
                    <div class="form-group">
                        <label>Verification Date</label>
                        <input type="date" name="verification_date" value="${data.Verification_Date ? data.Verification_Date.split(' ')[0] : ''}" required>
                    </div>
                </div>
            `;

        default:
            return '<p>Form not available for this section.</p>';
    }
}

function toggleStudentFields(type) {
    document.getElementById('generalFields').style.display = type === 'general' ? 'block' : 'none';
    document.getElementById('executiveFields').style.display = type === 'executive' ? 'block' : 'none';
}

function handleFormSubmit(e) {
    e.preventDefault();

    const form = e.target;
    const formData = new FormData(form);
    const data = Object.fromEntries(formData);
    const section = form.dataset.section;
    const id = form.dataset.id;
    const endpoint = form.dataset.endpoint;
    const method = form.dataset.method;
    const action = form.dataset.action;

    // Build URL with id or action
    let url = `backend/${endpoint}`;
    if (id) {
        url += `?id=${id}`;
    } else if (action) {
        url += `?action=${action}`;
    }

    // Submit to backend
    fetch(url, {
        method: method,
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            closeModal();
            // Refresh data
            fetchAllData();
            alert(result.message || 'Item updated successfully!');
        } else {
            alert('Error: ' + (result.message || result.error || 'Unknown error'));
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Network error occurred.');
    });
}

function handleDelete(section, id, row) {
    // Check permissions
    if (currentUser.role !== 'admin' && section !== 'volunteers') {
        alert('You do not have permission to delete this item.');
        return;
    }

    if (!confirm('Are you sure you want to delete this item? This action cannot be undone.')) {
        return;
    }

    let endpoint = '';
    switch (section) {
        case 'equipment': endpoint = 'equipment.php'; break;
        case 'clubs': endpoint = 'clubs_api.php'; break;
        case 'students': endpoint = 'students_api.php'; break;
        case 'events': endpoint = 'events.php'; break;
        case 'volunteers': endpoint = 'crud_volunteers.php'; break;
        case 'bookings': endpoint = 'crud_bookings.php'; break;
        case 'maintenance': endpoint = 'maintenance.php'; break;
        case 'memberships': endpoint = 'memberships.php'; break;
    }

    fetch(`backend/${endpoint}?id=${id}`, {
        method: 'DELETE'
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            row.remove();
            // Refresh data and KPIs
            fetchAllData();
            alert('Item deleted successfully!');
        } else {
            alert('Error: ' + (result.error || 'Unknown error'));
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Network error occurred.');
    });
}

function closeModal() {
    document.getElementById('crudModal').style.display = 'none';
    document.getElementById('crudForm').reset();
}

function addEquipment() {
    // Check permissions
    if (currentUser.role !== 'admin') {
        alert('You do not have permission to add equipment.');
        return;
    }

    // Get user's club name for display
    const userClub = clubsData.find(c => c.Club_ID == currentUser.Club_ID);
    const clubName = userClub ? userClub.Name : 'Your Club';

    // Open modal for adding new equipment
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Name</label>
                <input type="text" name="name" required>
            </div>
            <div class="form-group">
                <label>Type</label>
                <select name="type" required>
                    <option value="Camera">Camera</option>
                    <option value="Projector">Projector</option>
                    <option value="Microphone">Microphone</option>
                    <option value="Laptop">Laptop</option>
                    <option value="Speaker">Speaker</option>
                    <option value="Other">Other</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Status</label>
                <select name="status" required>
                    <option value="Available">Available</option>
                    <option value="In-Use">In-Use</option>
                    <option value="Damaged">Damaged</option>
                    <option value="Maintenance">Maintenance</option>
                </select>
            </div>
            <div class="form-group">
                <label>Owner Club</label>
                <input type="text" value="${clubName}" disabled style="background: var(--gray-100); color: var(--gray-600);">
                <input type="hidden" name="owner_club_id" value="${currentUser.Club_ID || 1}">
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Purchase Date</label>
                <input type="date" name="purchase_date" required>
            </div>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'equipment';
    document.getElementById('crudForm').dataset.endpoint = 'equipment.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Add New Equipment';
    document.getElementById('crudModal').style.display = 'flex';
}

function addBooking() {
    // Open modal for adding new booking with conflict detection
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Equipment</label>
                <select name="equip_id" id="bookingEquipSelect" required onchange="checkEquipmentAvailability()">
                    <option value="">Select Equipment</option>
                    ${equipmentData.filter(e => e.Status === 'Available').map(e => `<option value="${e.Equip_ID}">${e.EquipName} (${e.Type})</option>`).join('')}
                </select>
            </div>
            <div class="form-group">
                <label>Event</label>
                <select name="event_id" required>
                    <option value="">Select Event</option>
                    ${eventsData.map(ev => `<option value="${ev.Event_ID}">${ev.Title} - ${ev.Date}</option>`).join('')}
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Borrow Time</label>
                <input type="datetime-local" name="borrow_time" id="borrowTime" required onchange="checkBookingConflictUI()">
            </div>
            <div class="form-group">
                <label>Return Time</label>
                <input type="datetime-local" name="return_time" id="returnTime" required onchange="checkBookingConflictUI()">
            </div>
        </div>
        <div id="availabilityMessage" style="padding: 1rem; margin-top: 1rem; border-radius: 6px; display: none;"></div>
        <div class="form-row">
            <div class="form-group">
                <label>Status</label>
                <select name="status" required>
                    <option value="Confirmed">Confirmed</option>
                    <option value="Completed">Completed</option>
                    <option value="Cancelled">Cancelled</option>
                </select>
            </div>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'bookings';
    document.getElementById('crudForm').dataset.endpoint = 'crud_bookings.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Add New Booking';
    document.getElementById('crudModal').style.display = 'flex';
}

// Check equipment availability and show next available time
async function checkEquipmentAvailability() {
    const equipSelect = document.getElementById('bookingEquipSelect');
    const equipId = equipSelect?.value;
    
    if (!equipId) return;
    
    try {
        const response = await fetch(`backend/bookings_api.php?action=get_next_available&equip_id=${equipId}`);
        const data = await response.json();
        
        const msgDiv = document.getElementById('availabilityMessage');
        if (data.success && data.data && data.data.Next_Available) {
            msgDiv.style.display = 'block';
            msgDiv.style.background = 'var(--gray-100)';
            msgDiv.style.border = '1px solid var(--gray-300)';
            msgDiv.innerHTML = `<i class="fa-solid fa-info-circle"></i> <strong>Next Available:</strong> ${data.data.Next_Available}`;
        } else {
            msgDiv.style.display = 'block';
            msgDiv.style.background = '#e8f5e9';
            msgDiv.style.border = '1px solid #4caf50';
            msgDiv.innerHTML = `<i class="fa-solid fa-check-circle"></i> <strong>Equipment is currently available</strong>`;
        }
    } catch (error) {
        console.error('Error checking availability:', error);
    }
}

// Check for booking conflicts in real-time
async function checkBookingConflictUI() {
    const equipId = document.getElementById('bookingEquipSelect')?.value;
    const borrowTime = document.getElementById('borrowTime')?.value;
    const returnTime = document.getElementById('returnTime')?.value;
    
    if (!equipId || !borrowTime || !returnTime) return;
    
    try {
        const response = await fetch(`backend/bookings_api.php?action=check_availability&equip_id=${equipId}&borrow_time=${encodeURIComponent(borrowTime)}&return_time=${encodeURIComponent(returnTime)}`);
        const data = await response.json();
        
        const msgDiv = document.getElementById('availabilityMessage');
        msgDiv.style.display = 'block';
        
        if (data.success && data.available) {
            msgDiv.style.background = '#e8f5e9';
            msgDiv.style.border = '1px solid #4caf50';
            msgDiv.style.color = '#2e7d32';
            msgDiv.innerHTML = `<i class="fa-solid fa-check-circle"></i> <strong>Available!</strong> No conflicts detected for this time slot.`;
        } else {
            msgDiv.style.background = '#ffebee';
            msgDiv.style.border = '1px solid #f44336';
            msgDiv.style.color = '#c62828';
            msgDiv.innerHTML = `<i class="fa-solid fa-exclamation-triangle"></i> <strong>Conflict!</strong> ${data.reason || 'Equipment is already booked for this time slot.'}`;
        }
    } catch (error) {
        console.error('Error checking conflict:', error);
    }
}

// Make functions globally available
window.checkEquipmentAvailability = checkEquipmentAvailability;
window.checkBookingConflictUI = checkBookingConflictUI;

// ===== BADGES & LEADERBOARD FUNCTIONS =====
async function fetchBadges() {
    try {
        const response = await fetch('backend/badges_api.php?action=get_badge_statistics');
        const data = await response.json();
        if (data.success && data.data) {
            badgesData = Array.isArray(data.data) ? data.data : [];
            renderBadges(badgesData);
            updateBadgeSummary();
        }
    } catch (error) {
        console.error('Error fetching badges:', error);
    }
}

async function fetchLeaderboard() {
    try {
        const response = await fetch('backend/badges_api.php?action=get_leaderboard&limit=50');
        const data = await response.json();
        if (data.success && data.data) {
            leaderboardData = Array.isArray(data.data) ? data.data : [];
            renderLeaderboard(leaderboardData);
        }
    } catch (error) {
        console.error('Error fetching leaderboard:', error);
    }
}

function renderBadges(data) {
    const badgesGrid = document.getElementById('badgesGrid');
    if (!badgesGrid) return;
    
    badgesGrid.innerHTML = '';
    
    if (!Array.isArray(data) || data.length === 0) {
        badgesGrid.innerHTML = '<p style="text-align:center; padding:2rem;">No badges found.</p>';
        return;
    }
    
    data.forEach(badge => {
        const tierClass = badge.Tier.toLowerCase();
        const card = document.createElement('div');
        card.className = `badge-card ${tierClass}`;
        card.innerHTML = `
            <div class="badge-header">
                <div class="badge-icon" style="color: ${badge.Color}">
                    <i class="fa-solid fa-${badge.Icon}"></i>
                </div>
                <div class="badge-info">
                    <h3>${badge.Badge_Name}</h3>
                    <span class="badge-tier ${tierClass}">${badge.Tier}</span>
                </div>
            </div>
            <p class="badge-description">${badge.Description}</p>
            <div class="badge-requirements">
                <span class="badge-hours">
                    <i class="fa-solid fa-clock"></i> ${badge.Hours_Required} hours
                </span>
                <span class="badge-earned-count">
                    ${badge.Students_Earned || 0} earned (${badge.Percentage_Of_Volunteers || 0}%)
                </span>
            </div>
        `;
        badgesGrid.appendChild(card);
    });
}

function renderLeaderboard(data) {
    const leaderboardBody = document.getElementById('leaderboardBody');
    const leaderboardBodyMain = document.getElementById('leaderboardBodyMain');
    
    if (!Array.isArray(data) || data.length === 0) {
        const emptyHTML = '<tr><td colspan="6" style="text-align:center;">No leaderboard data available.</td></tr>';
        if (leaderboardBody) leaderboardBody.innerHTML = emptyHTML;
        if (leaderboardBodyMain) leaderboardBodyMain.innerHTML = '<tr><td colspan="7" style="text-align:center;">No leaderboard data available.</td></tr>';
        return;
    }
    
    // Render to badges section leaderboard
    if (leaderboardBody) {
        leaderboardBody.innerHTML = '';
        data.forEach((item, index) => {
            const medal = index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : '';
            const row = document.createElement('tr');
            row.innerHTML = `
                <td><span class="rank-medal">${medal}</span> ${item.Rank_Position || index + 1}</td>
                <td>
                    <a href="#" onclick="showVolunteerPortfolio(${item.Student_ID}, '${item.Name}'); return false;" style="color: var(--black); text-decoration: underline; cursor: pointer;">
                        ${item.Name}
                    </a>
                </td>
                <td>${item.Total_Hours || 0}</td>
                <td>${item.Events_Count || 0}</td>
                <td>
                    <a href="#" onclick="showBadgeProgressModal(${item.Student_ID}, '${item.Name}'); return false;" style="color: var(--black); text-decoration: underline; cursor: pointer;">
                        ${item.Badges_Earned || 0}
                    </a>
                </td>
                <td>${item.Highest_Tier || 'None'}</td>
            `;
            leaderboardBody.appendChild(row);
        });
    }
    
    // Render to main leaderboard section
    if (leaderboardBodyMain) {
        leaderboardBodyMain.innerHTML = '';
        data.forEach((item, index) => {
            const medal = index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : '';
            const row = document.createElement('tr');
            row.innerHTML = `
                <td><span class="rank-medal">${medal}</span> ${item.Rank_Position || index + 1}</td>
                <td>
                    <a href="#" onclick="showVolunteerPortfolio(${item.Student_ID}, '${item.Name}'); return false;" style="color: var(--black); text-decoration: underline; cursor: pointer;">
                        ${item.Name}
                    </a>
                </td>
                <td>${item.Club_Name || 'No Club'}</td>
                <td>${item.Total_Hours || 0}</td>
                <td>${item.Events_Count || 0}</td>
                <td>
                    <a href="#" onclick="showBadgeProgressModal(${item.Student_ID}, '${item.Name}'); return false;" style="color: var(--black); text-decoration: underline; cursor: pointer;">
                        ${item.Badges_Earned || 0}
                    </a>
                </td>
                <td>${item.Highest_Tier || 'None'}</td>
                <td>
                    <button class="action-btn" onclick="showVolunteerPortfolio(${item.Student_ID}, '${item.Name}')" title="View Portfolio">
                        <i class="fa-solid fa-user"></i>
                    </button>
                    <button class="action-btn" onclick="showBadgeProgressModal(${item.Student_ID}, '${item.Name}')" title="View Badges">
                        <i class="fa-solid fa-medal"></i>
                    </button>
                </td>
            `;
            leaderboardBodyMain.appendChild(row);
        });
    }
    
    // Update leaderboard KPIs
    updateLeaderboardKPIs(data);
}

function updateLeaderboardKPIs(data) {
    if (!Array.isArray(data) || data.length === 0) return;
    
    const totalVolunteers = data.length;
    const totalHours = data.reduce((sum, item) => sum + (parseFloat(item.Total_Hours) || 0), 0);
    const topVolunteer = data[0]?.Name || '-';
    
    const totalVolEl = document.getElementById('leaderboardTotalVolunteers');
    const totalHoursEl = document.getElementById('leaderboardTotalHours');
    const topVolEl = document.getElementById('leaderboardTopVolunteer');
    
    if (totalVolEl) totalVolEl.textContent = totalVolunteers;
    if (totalHoursEl) totalHoursEl.textContent = totalHours.toFixed(1);
    if (topVolEl) topVolEl.textContent = topVolunteer;
}

// Switch between volunteer and club leaderboard tabs
function switchLeaderboardTab(tab) {
    // Update tab buttons
    document.querySelectorAll('.leaderboard-tab').forEach(btn => {
        btn.classList.remove('active');
        btn.style.color = 'var(--gray-600)';
        btn.style.borderBottomColor = 'transparent';
    });
    
    const activeTab = document.querySelector(`.leaderboard-tab[data-tab="${tab}"]`);
    if (activeTab) {
        activeTab.classList.add('active');
        activeTab.style.color = 'var(--gray-900)';
        activeTab.style.borderBottomColor = 'var(--gray-900)';
    }
    
    // Update content visibility
    document.querySelectorAll('.leaderboard-content').forEach(content => {
        content.style.display = 'none';
    });
    
    const activeContent = document.getElementById(`leaderboard-${tab}`);
    if (activeContent) {
        activeContent.style.display = 'block';
    }
    
    // Load data for the tab
    if (tab === 'clubs') {
        fetchClubLeaderboard();
    } else {
        fetchLeaderboard();
    }
}

// Fetch club leaderboard
async function fetchClubLeaderboard() {
    try {
        const response = await fetch('backend/bidding_api.php?action=get_currency_leaderboard');
        const data = await response.json();
        if (data.success && data.leaderboard) {
            renderClubLeaderboard(data.leaderboard);
        }
    } catch (error) {
        console.error('Error fetching club leaderboard:', error);
    }
}

// Render club leaderboard
function renderClubLeaderboard(data) {
    const tbody = document.getElementById('clubLeaderboardBody');
    
    if (!tbody) return;
    
    if (!Array.isArray(data) || data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;">No club data available.</td></tr>';
        return;
    }
    
    tbody.innerHTML = '';
    data.forEach((club, index) => {
        const rank = index + 1;
        const medal = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : '';
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td><span class="rank-medal">${medal}</span> ${rank}</td>
            <td style="font-weight: 600;">${club.Club_Name}</td>
            <td style="font-weight: bold; color: #FFD700;">${Math.floor(club.Currency_Balance)} Coins</td>
            <td>${club.Total_Members}</td>
            <td>${parseFloat(club.Total_Volunteer_Hours).toFixed(1)} hrs</td>
            <td>${club.Total_Badges_Earned}</td>
            <td>${club.Equipment_Owned}</td>
        `;
        tbody.appendChild(row);
    });
}

function updateBadgeSummary() {
    document.getElementById('totalBadges').textContent = badgesData.length;
    const activeVols = new Set(leaderboardData.map(v => v.Student_ID)).size;
    document.getElementById('activeVolunteers').textContent = activeVols;
    const topTier = leaderboardData.filter(v => v.Highest_Tier === 'Diamond' || v.Highest_Tier === 'Platinum').length;
    document.getElementById('topTierCount').textContent = topTier;
}

function updateBookingSummary() {
    document.getElementById('totalBookings').textContent = bookingsData.length;
    const confirmed = bookingsData.filter(b => b.Status === 'Confirmed').length;
    document.getElementById('confirmedBookings').textContent = confirmed;
    // Conflicts would need a separate API call to the Booking_Conflicts_Report view
    document.getElementById('conflictBookings').textContent = 0;
}

// ===== ANALYTICS FUNCTIONS =====
async function loadEquipmentUtilization() {
    try {
        const response = await fetch('backend/analytics.php?action=equipment_utilization');
        const data = await response.json();
        if (data.success && data.data) {
            renderEquipmentUtilization(Array.isArray(data.data) ? data.data : []);
        }
    } catch (error) {
        console.error('Error loading equipment utilization:', error);
    }
}

function renderEquipmentUtilization(data) {
    const tbody = document.getElementById('equipUtilBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;">No data available. Click Refresh to load.</td></tr>';
        return;
    }
    
    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.Name}</td>
            <td>${item.Type}</td>
            <td>${item.Owner_Club}</td>
            <td>${item.Total_Bookings || 0}</td>
            <td>${item.Total_Hours_Booked || 0}</td>
            <td>$${item.Total_Maintenance_Cost || 0}</td>
            <td><span class="status ${(item.ROI_Rating || '').toLowerCase()}">${item.ROI_Rating || 'N/A'}</span></td>
            <td>${item.Recommendation || 'N/A'}</td>
        `;
        tbody.appendChild(row);
    });
}

async function loadClubCollaboration() {
    try {
        const response = await fetch('backend/analytics.php?action=club_collaboration');
        const data = await response.json();
        if (data.success && data.data) {
            renderClubCollaboration(Array.isArray(data.data) ? data.data : []);
        }
    } catch (error) {
        console.error('Error loading club collaboration:', error);
    }
}

function renderClubCollaboration(data) {
    const tbody = document.getElementById('clubCollabBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;">No data available. Click Refresh to load.</td></tr>';
        return;
    }
    
    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.Club_1}</td>
            <td>${item.Club_2}</td>
            <td>${item.Collaborations_Count || 0}</td>
            <td>${item.Shared_Equipment_Usage || 0}</td>
            <td><span class="status">${item.Partnership_Strength || 'N/A'}</span></td>
            <td>${item.Collaboration_Score || 0}</td>
        `;
        tbody.appendChild(row);
    });
}

async function loadEventSuccess() {
    try {
        const response = await fetch('backend/analytics.php?action=event_success');
        const data = await response.json();
        if (data.success && data.data) {
            renderEventSuccess(Array.isArray(data.data) ? data.data : []);
        }
    } catch (error) {
        console.error('Error loading event success:', error);
    }
}

function renderEventSuccess(data) {
    const tbody = document.getElementById('eventSuccessBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;">No data available. Click Refresh to load.</td></tr>';
        return;
    }
    
    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.Title}</td>
            <td>${item.Date}</td>
            <td>${item.Primary_Club}</td>
            <td>${item.Volunteers_Count || 0}</td>
            <td>${item.Partner_Clubs_Count || 0}</td>
            <td>${item.Equipment_Used || 0}</td>
            <td><span class="status">${item.Event_Scale || 'N/A'}</span></td>
            <td>${item.Success_Score || 0}</td>
        `;
        tbody.appendChild(row);
    });
}

async function loadStudentEngagement() {
    try {
        const response = await fetch('backend/analytics.php?action=student_engagement');
        const data = await response.json();
        if (data.success && data.data) {
            renderStudentEngagement(Array.isArray(data.data) ? data.data : []);
        }
    } catch (error) {
        console.error('Error loading student engagement:', error);
    }
}

function renderStudentEngagement(data) {
    const tbody = document.getElementById('engagementBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;">No data available. Click Refresh to load.</td></tr>';
        return;
    }
    
    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.Name}</td>
            <td>${item.Total_Hours || 0}</td>
            <td>${item.Events_Volunteered || 0}</td>
            <td>${item.Clubs_Joined || 0}</td>
            <td>${item.Is_Executive === 1 ? 'Yes' : 'No'}</td>
            <td>${item.Different_Roles || 0}</td>
            <td>${item.Engagement_Score || 0}</td>
            <td><span class="status">${item.Engagement_Category || 'N/A'}</span></td>
        `;
        tbody.appendChild(row);
    });
}

async function loadBookingPatterns() {
    try {
        const response = await fetch('backend/analytics.php?action=booking_patterns');
        const data = await response.json();
        if (data.success && data.data) {
            renderBookingPatterns(Array.isArray(data.data) ? data.data : []);
        }
    } catch (error) {
        console.error('Error loading booking patterns:', error);
    }
}

function renderBookingPatterns(data) {
    const tbody = document.getElementById('bookingPatternsBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    if (data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;">No data available. Click Refresh to load.</td></tr>';
        return;
    }
    
    data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${item.Day_Of_Week}</td>
            <td>${item.Hour_Of_Day}:00</td>
            <td>${item.Equipment_Type}</td>
            <td>${item.Booking_Count || 0}</td>
            <td>${item.Avg_Duration_Hours || 0}</td>
            <td><span class="status ${(item.Demand_Level || '').toLowerCase().replace(' ', '-')}">${item.Demand_Level || 'N/A'}</span></td>
        `;
        tbody.appendChild(row);
    });
}

// Make analytics functions globally available
window.loadEquipmentUtilization = loadEquipmentUtilization;
window.loadClubCollaboration = loadClubCollaboration;
window.loadEventSuccess = loadEventSuccess;
window.loadStudentEngagement = loadStudentEngagement;
window.loadBookingPatterns = loadBookingPatterns;

// ===== ADD CLUB FUNCTION =====
function addClub() {
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Club Name</label>
                <input type="text" name="name" required>
            </div>
            <div class="form-group">
                <label>Department</label>
                <input type="text" name="department" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Office Room</label>
                <input type="text" name="office" required>
            </div>
            <div class="form-group">
                <label>Founded Date</label>
                <input type="date" name="founded" required>
            </div>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'clubs';
    document.getElementById('crudForm').dataset.endpoint = 'clubs_api.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Add New Club';
    document.getElementById('crudModal').style.display = 'flex';
}

// ===== ADD STUDENT FUNCTION =====
function addStudent() {
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Name</label>
                <input type="text" name="name" required>
            </div>
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Street</label>
                <input type="text" name="street" required>
            </div>
            <div class="form-group">
                <label>City</label>
                <input type="text" name="city" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Zip</label>
                <input type="text" name="zip" required>
            </div>
            <div class="form-group">
                <label>Contact No</label>
                <input type="text" name="contact_no" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Student Type</label>
                <select name="student_type" required onchange="toggleStudentFields(this.value)">
                    <option value="general">General Student</option>
                    <option value="executive">Club Executive</option>
                </select>
            </div>
        </div>
        <div id="generalFields">
            <div class="form-row">
                <div class="form-group">
                    <label>Year of Study</label>
                    <input type="number" name="year_of_study" min="1" max="4">
                </div>
                <div class="form-group">
                    <label>Major</label>
                    <input type="text" name="major">
                </div>
            </div>
        </div>
        <div id="executiveFields" style="display: none;">
            <div class="form-row">
                <div class="form-group">
                    <label>Position</label>
                    <input type="text" name="position">
                </div>
                <div class="form-group">
                    <label>Term Start</label>
                    <input type="date" name="term_start">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label>Term End</label>
                    <input type="date" name="term_end">
                </div>
            </div>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'students';
    document.getElementById('crudForm').dataset.endpoint = 'students_api.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Add New Student';
    document.getElementById('crudModal').style.display = 'flex';
}

// ===== ADD EVENT FUNCTION =====
function addEvent() {
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Event Title</label>
                <input type="text" name="title" required>
            </div>
            <div class="form-group">
                <label>Venue</label>
                <input type="text" name="venue" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Date</label>
                <input type="date" name="date" required>
            </div>
            <div class="form-group">
                <label>Primary Club</label>
                <select name="primary_club_id" required>
                    <option value="">Select Club</option>
                    ${clubsData.map(club => `<option value="${club.Club_ID}">${club.ClubName}</option>`).join('')}
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Description</label>
                <textarea name="description" rows="3"></textarea>
            </div>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'events';
    document.getElementById('crudForm').dataset.endpoint = 'events.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Add New Event';
    document.getElementById('crudModal').style.display = 'flex';
}

// Make toggle function globally available
window.toggleStudentFields = toggleStudentFields;

// ===== ADD MAINTENANCE FUNCTION =====
function addMaintenance() {
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Equipment</label>
                <select name="equip_id" required>
                    <option value="">Select Equipment</option>
                    ${equipmentData.map(e => `<option value="${e.Equip_ID}">${e.EquipName}</option>`).join('')}
                </select>
            </div>
            <div class="form-group">
                <label>Maintenance Date</label>
                <input type="date" name="maintenance_date" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Description</label>
                <textarea name="description" rows="3" required></textarea>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Cost ($)</label>
                <input type="number" name="cost" step="0.01" min="0" required>
            </div>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'maintenance';
    document.getElementById('crudForm').dataset.endpoint = 'maintenance.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Log Maintenance';
    document.getElementById('crudModal').style.display = 'flex';
}

// ===== ADD MEMBERSHIP FUNCTION =====
function addMembership() {
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Student</label>
                <select name="student_id" required>
                    <option value="">Select Student</option>
                    ${studentsData.map(s => `<option value="${s.Student_ID}">${s.StudentName}</option>`).join('')}
                </select>
            </div>
            <div class="form-group">
                <label>Club</label>
                <select name="club_id" required>
                    <option value="">Select Club</option>
                    ${clubsData.map(c => `<option value="${c.Club_ID}">${c.ClubName}</option>`).join('')}
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Role</label>
                <select name="role" required>
                    <option value="Member">Member</option>
                    <option value="Volunteer">Volunteer</option>
                    <option value="Executive">Executive</option>
                    <option value="Advisor">Advisor</option>
                </select>
            </div>
            <div class="form-group">
                <label>Join Date</label>
                <input type="date" name="join_date" required>
            </div>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'memberships';
    document.getElementById('crudForm').dataset.endpoint = 'memberships.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Add Membership';
    document.getElementById('crudModal').style.display = 'flex';
}

// ===== ADD VOLUNTEER LOG FUNCTION =====
function addVolunteerLog() {
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Student</label>
                <select name="student_id" required>
                    <option value="">Select Student</option>
                    ${studentsData.map(s => `<option value="${s.Student_ID}">${s.StudentName}</option>`).join('')}
                </select>
            </div>
            <div class="form-group">
                <label>Event</label>
                <select name="event_id" required>
                    <option value="">Select Event</option>
                    ${eventsData.map(e => `<option value="${e.Event_ID}">${e.Title} - ${e.Date}</option>`).join('')}
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Role</label>
                <input type="text" name="role" placeholder="e.g., Setup Crew, Registration, MC" required>
            </div>
            <div class="form-group">
                <label>Hours Worked</label>
                <input type="number" name="hours_worked" step="0.5" min="0.5" max="24" placeholder="e.g., 3.5" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Verified By (Executive)</label>
                <select name="verified_by">
                    <option value="">Not Verified Yet</option>
                    ${studentsData.filter(s => s.Position).map(s => `<option value="${s.Student_ID}">${s.StudentName} (${s.Position})</option>`).join('')}
                </select>
            </div>
            <div class="form-group">
                <label>Verification Date</label>
                <input type="date" name="verification_date">
            </div>
        </div>
        <div style="padding: 1rem; background: var(--gray-50); border-radius: 8px; margin-top: 1rem;">
            <p style="margin: 0; color: var(--gray-600); font-size: 0.875rem;">
                <i class="fa-solid fa-info-circle"></i> 
                Logging volunteer hours will automatically:
            </p>
            <ul style="margin: 0.5rem 0 0 1.5rem; color: var(--gray-600); font-size: 0.875rem;">
                <li>Update the volunteer leaderboard</li>
                <li>Award 10 coins per hour to the student's club</li>
                <li>Check for badge eligibility and auto-award badges</li>
            </ul>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'volunteers';
    document.getElementById('crudForm').dataset.endpoint = 'volunteers_api.php';
    document.getElementById('crudForm').dataset.method = 'POST';
    document.getElementById('crudForm').dataset.action = 'create_volunteer_log';

    document.getElementById('modalTitle').textContent = 'Log Volunteer Hours';
    document.getElementById('crudModal').style.display = 'flex';
}

// ===== ADD VOLUNTEER (STUDENT) FUNCTION =====
function addVolunteer() {
    const formHtml = `
        <div class="form-row">
            <div class="form-group">
                <label>Name</label>
                <input type="text" name="name" placeholder="Full Name" required>
            </div>
            <div class="form-group">
                <label>Email</label>
                <input type="email" name="email" placeholder="student@example.edu" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" placeholder="Default: volunteer123" value="volunteer123" required>
            </div>
            <div class="form-group">
                <label>Contact No</label>
                <input type="text" name="contact_no" placeholder="+1234567890" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Street</label>
                <input type="text" name="street" placeholder="123 Main St" required>
            </div>
            <div class="form-group">
                <label>City</label>
                <input type="text" name="city" placeholder="City Name" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Zip</label>
                <input type="text" name="zip" placeholder="12345" required>
            </div>
            <div class="form-group">
                <label>Year of Study</label>
                <select name="year_of_study" required>
                    <option value="1">Year 1</option>
                    <option value="2">Year 2</option>
                    <option value="3">Year 3</option>
                    <option value="4">Year 4</option>
                </select>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
                <label>Major</label>
                <input type="text" name="major" placeholder="e.g., Computer Science" required>
            </div>
            <div class="form-group">
                <label>Assign to Club (Optional)</label>
                <select name="club_id">
                    <option value="">No Club Assignment</option>
                    ${clubsData.map(c => `<option value="${c.Club_ID}">${c.Name}</option>`).join('')}
                </select>
            </div>
        </div>
        <input type="hidden" name="student_type" value="general">
        <div style="padding: 1rem; background: var(--gray-50); border-radius: 8px; margin-top: 1rem;">
            <p style="margin: 0; color: var(--gray-600); font-size: 0.875rem;">
                <i class="fa-solid fa-info-circle"></i> 
                This will create a new student account that can volunteer for events. If you assign them to a club, they'll automatically become a member.
            </p>
        </div>
    `;

    document.getElementById('crudForm').innerHTML = formHtml;
    document.getElementById('crudForm').dataset.section = 'students';
    document.getElementById('crudForm').dataset.endpoint = 'students_api.php';
    document.getElementById('crudForm').dataset.method = 'POST';

    document.getElementById('modalTitle').textContent = 'Add New Volunteer';
    document.getElementById('crudModal').style.display = 'flex';
}


// ===== FILTER FUNCTIONS =====
function initializeFilters() {
    // Populate club filter
    const clubFilter = document.getElementById('filterClub');
    if (clubFilter && clubsData.length > 0) {
        clubsData.forEach(club => {
            const option = document.createElement('option');
            option.value = club.Club_ID;
            option.textContent = club.ClubName;
            clubFilter.appendChild(option);
        });
    }
    
    // Populate equipment filter for bookings
    const equipFilter = document.getElementById('filterBookingEquipment');
    if (equipFilter && equipmentData.length > 0) {
        equipmentData.forEach(equip => {
            const option = document.createElement('option');
            option.value = equip.Equip_ID;
            option.textContent = equip.EquipName;
            equipFilter.appendChild(option);
        });
    }
    
    // Populate event filters
    const eventFilters = ['filterBookingEvent', 'filterVolunteerEvent'];
    eventFilters.forEach(filterId => {
        const filter = document.getElementById(filterId);
        if (filter && eventsData.length > 0) {
            eventsData.forEach(event => {
                const option = document.createElement('option');
                option.value = event.Event_ID;
                option.textContent = event.Title;
                filter.appendChild(option);
            });
        }
    });
    
    // Populate student filter for volunteers
    const studentFilter = document.getElementById('filterVolunteerStudent');
    if (studentFilter && studentsData.length > 0) {
        studentsData.forEach(student => {
            const option = document.createElement('option');
            option.value = student.Student_ID;
            option.textContent = student.StudentName;
            studentFilter.appendChild(option);
        });
    }
    
    // Populate equipment filter for maintenance
    const maintenanceEquipFilter = document.getElementById('filterMaintenanceEquipment');
    if (maintenanceEquipFilter && equipmentData.length > 0) {
        equipmentData.forEach(equip => {
            const option = document.createElement('option');
            option.value = equip.Equip_ID;
            option.textContent = equip.EquipName;
            maintenanceEquipFilter.appendChild(option);
        });
    }
    
    // Populate club filter for memberships
    const membershipClubFilter = document.getElementById('filterMembershipClub');
    if (membershipClubFilter && clubsData.length > 0) {
        clubsData.forEach(club => {
            const option = document.createElement('option');
            option.value = club.Club_ID;
            option.textContent = club.ClubName;
            membershipClubFilter.appendChild(option);
        });
    }
    
    // Populate student filter for memberships
    const membershipStudentFilter = document.getElementById('filterMembershipStudent');
    if (membershipStudentFilter && studentsData.length > 0) {
        studentsData.forEach(student => {
            const option = document.createElement('option');
            option.value = student.Student_ID;
            option.textContent = student.StudentName;
            membershipStudentFilter.appendChild(option);
        });
    }
    
    // Bind filter events
    bindFilterEvents();
}

function bindFilterEvents() {
    // Equipment filters
    document.getElementById('filterStatus')?.addEventListener('change', filterEquipment);
    document.getElementById('filterType')?.addEventListener('change', filterEquipment);
    document.getElementById('filterClub')?.addEventListener('change', filterEquipment);
    
    // Booking filters
    document.getElementById('filterBookingStatus')?.addEventListener('change', filterBookings);
    document.getElementById('filterBookingEquipment')?.addEventListener('change', filterBookings);
    document.getElementById('filterBookingEvent')?.addEventListener('change', filterBookings);
    
    // Volunteer filters
    document.getElementById('filterVolunteerStudent')?.addEventListener('change', filterVolunteers);
    document.getElementById('filterVolunteerEvent')?.addEventListener('change', filterVolunteers);
    document.getElementById('filterVolunteerDateFrom')?.addEventListener('change', filterVolunteers);
    document.getElementById('filterVolunteerDateTo')?.addEventListener('change', filterVolunteers);
    
    // Badge filter
    document.getElementById('filterBadgeTier')?.addEventListener('change', filterBadges);
}

function filterEquipment() {
    const status = document.getElementById('filterStatus')?.value || '';
    const type = document.getElementById('filterType')?.value || '';
    const club = document.getElementById('filterClub')?.value || '';
    
    const filtered = equipmentData.filter(item => {
        const matchStatus = !status || item.Status === status;
        const matchType = !type || item.Type === type;
        const matchClub = !club || item.Owner_Club_ID == club;
        return matchStatus && matchType && matchClub;
    });
    
    renderEquipmentRows(filtered);
}

function filterBookings() {
    const status = document.getElementById('filterBookingStatus')?.value || '';
    const equipment = document.getElementById('filterBookingEquipment')?.value || '';
    const event = document.getElementById('filterBookingEvent')?.value || '';
    
    const filtered = bookingsData.filter(item => {
        const matchStatus = !status || item.Status === status;
        const matchEquipment = !equipment || item.Equip_ID == equipment;
        const matchEvent = !event || item.Event_ID == event;
        return matchStatus && matchEquipment && matchEvent;
    });
    
    renderBookingRows(filtered);
}

function filterVolunteers() {
    const student = document.getElementById('filterVolunteerStudent')?.value || '';
    const event = document.getElementById('filterVolunteerEvent')?.value || '';
    const dateFrom = document.getElementById('filterVolunteerDateFrom')?.value || '';
    const dateTo = document.getElementById('filterVolunteerDateTo')?.value || '';
    
    const filtered = volunteersData.filter(item => {
        const matchStudent = !student || item.Student_ID == student;
        const matchEvent = !event || item.Event_ID == event;
        
        // Date filtering would need event date from the data
        // For now, just filter by student and event
        return matchStudent && matchEvent;
    });
    
    renderVolunteerRows(filtered);
}

function filterBadges() {
    const tier = document.getElementById('filterBadgeTier')?.value || '';
    
    const filtered = badgesData.filter(item => {
        return !tier || item.Tier === tier;
    });
    
    renderBadges(filtered);
}

// Call initializeFilters after all data is loaded
const originalFetchAllData = fetchAllData;
fetchAllData = async function() {
    await originalFetchAllData();
    setTimeout(initializeFilters, 500);
};


// ===== BIDDING FUNCTIONS =====
let currentBiddingClubId = 1; // Default to first club
let biddingEquipment = [];

async function loadBiddingData() {
    // Set club ID from current user
    if (currentUser && currentUser.Club_ID) {
        currentBiddingClubId = currentUser.Club_ID;
    } else {
        currentBiddingClubId = 1; // Fallback to first club
    }
    
    await loadBiddingClubBalance();
    await loadBiddingActiveAuctions();
    await loadBiddingClubLeaderboard();
    populateBiddingEquipmentSelect();
}

async function loadBiddingClubBalance() {
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_club_currency&club_id=${currentBiddingClubId}`);
        const data = await response.json();
        if (data.success) {
            document.getElementById('biddingClubBalance').textContent = Math.floor(data.balance) + ' Coins';
        }
    } catch (error) {
        console.error('Error loading club balance:', error);
    }
}

async function loadBiddingActiveAuctions() {
    try {
        await fetch('backend/bidding_api.php?action=complete_expired_auctions');
        const response = await fetch('backend/bidding_api.php?action=get_active_auctions');
        const data = await response.json();
        
        console.log('Active auctions data:', data);
        
        if (data.success) {
            document.getElementById('biddingActiveCount').textContent = data.auctions.length;
            displayBiddingActiveAuctions(data.auctions);
        } else {
            console.error('Failed to load auctions:', data);
            displayBiddingActiveAuctions([]);
        }
    } catch (error) {
        console.error('Error loading auctions:', error);
        displayBiddingActiveAuctions([]);
    }
}

function displayBiddingActiveAuctions(auctions) {
    const grid = document.getElementById('activeAuctionsGrid');
    
    console.log('displayBiddingActiveAuctions called with:', auctions);
    console.log('Grid element:', grid);
    
    if (!grid) {
        console.error('activeAuctionsGrid element not found!');
        return;
    }
    
    if (!auctions || auctions.length === 0) {
        grid.innerHTML = '<p style="text-align: center; color: var(--gray-600); padding: 2rem; grid-column: 1/-1;">No active auctions at the moment.</p>';
        return;
    }
    
    console.log('Rendering', auctions.length, 'auctions');
    
    grid.innerHTML = auctions.map(auction => {
        const hoursRemaining = parseInt(auction.Hours_Remaining);
        const isUrgent = hoursRemaining < 2;
        const minBid = auction.Current_Highest_Bid ? parseFloat(auction.Current_Highest_Bid) + 10 : parseFloat(auction.Starting_Price);
        const clubName = clubsData.find(c => c.Club_ID == currentBiddingClubId)?.Name || '';
        const isMyAuction = auction.Owner_Club === clubName;
        
        return `
            <div class="card" style="padding: 1.5rem;">
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 1rem;">
                    <div>
                        <h3 style="font-size: 1.25rem; margin-bottom: 0.5rem;">${auction.Equipment_Name}</h3>
                        <span class="badge" style="background: var(--gray-100); color: var(--gray-700); padding: 0.25rem 0.75rem; border-radius: 6px; font-size: 0.875rem;">${auction.Equipment_Type}</span>
                    </div>
                </div>
                
                <div style="margin: 1rem 0;">
                    <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100);">
                        <span style="color: var(--gray-600); font-size: 0.875rem;">Owner Club</span>
                        <span style="font-weight: 600;">${auction.Owner_Club}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100);">
                        <span style="color: var(--gray-600); font-size: 0.875rem;">Starting Price</span>
                        <span style="font-weight: 600;">${Math.floor(auction.Starting_Price)} Coins</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100);">
                        <span style="color: var(--gray-600); font-size: 0.875rem;">Current Bid</span>
                        <span style="font-weight: 600; color: #FFD700; font-size: 1.25rem;">
                            ${auction.Current_Highest_Bid ? Math.floor(auction.Current_Highest_Bid) + ' Coins' : 'No bids yet'}
                        </span>
                    </div>
                    ${auction.Highest_Bidder_Club ? `
                    <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100);">
                        <span style="color: var(--gray-600); font-size: 0.875rem;">Leading Bidder</span>
                        <span style="font-weight: 600;">${auction.Highest_Bidder_Club}</span>
                    </div>
                    ` : ''}
                    <div style="display: flex; justify-content: space-between; padding: 0.5rem 0;">
                        <span style="color: var(--gray-600); font-size: 0.875rem;">Total Bids</span>
                        <span style="font-weight: 600;">${auction.Total_Bids}</span>
                    </div>
                </div>
                
                <div style="display: flex; align-items: center; gap: 0.5rem; padding: 0.75rem; background: ${isUrgent ? '#FEE' : 'var(--gray-50)'}; border-radius: 8px; margin: 1rem 0; color: ${isUrgent ? '#C00' : 'inherit'};">
                    <i class="fas fa-clock"></i>
                    <span>${hoursRemaining > 0 ? hoursRemaining + ' hours' : 'Less than 1 hour'} remaining</span>
                </div>
                
                ${!isMyAuction ? `
                <div style="display: flex; gap: 0.5rem; margin-top: 1rem;">
                    <input type="number" 
                           class="form-control" 
                           id="bid-${auction.Auction_ID}" 
                           placeholder="Min: ${Math.floor(minBid)} coins"
                           min="${Math.floor(minBid)}"
                           step="10"
                           style="flex: 1; padding: 0.75rem; border: 1px solid var(--gray-300); border-radius: 8px;">
                    <button class="btn-primary" onclick="placeBiddingBid(${auction.Auction_ID})" style="padding: 0.75rem 1.5rem;">
                        <i class="fas fa-gavel"></i> Bid
                    </button>
                </div>
                ` : '<p style="text-align: center; color: var(--gray-600); margin-top: 1rem;">Your auction</p>'}
                
                <button onclick="viewBiddingBidHistory(${auction.Auction_ID})" class="btn-secondary" style="width: 100%; margin-top: 0.5rem; padding: 0.5rem;">
                    View Bid History
                </button>
            </div>
        `;
    }).join('');
}

async function placeBiddingBid(auctionId) {
    const bidInput = document.getElementById(`bid-${auctionId}`);
    const bidAmount = parseFloat(bidInput.value);
    
    if (!bidAmount || bidAmount <= 0) {
        alert('Please enter a valid bid amount');
        return;
    }
    
    try {
        const formData = new FormData();
        formData.append('action', 'place_bid');
        formData.append('auction_id', auctionId);
        formData.append('club_id', currentBiddingClubId);
        formData.append('bid_amount', bidAmount);
        
        const response = await fetch('backend/bidding_api.php', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('Bid placed successfully!');
            bidInput.value = '';
            loadBiddingActiveAuctions();
            loadBiddingClubBalance();
            loadMyBiddingBids(); // Update My Bids count
        } else {
            alert(data.message || 'Failed to place bid');
        }
    } catch (error) {
        console.error('Error placing bid:', error);
        alert('An error occurred while placing bid');
    }
}

async function viewBiddingBidHistory(auctionId) {
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_bid_history&auction_id=${auctionId}`);
        const data = await response.json();
        
        if (data.success) {
            displayBiddingBidHistory(data.bids);
            document.getElementById('bidHistoryModal').style.display = 'flex';
        }
    } catch (error) {
        console.error('Error loading bid history:', error);
    }
}

function displayBiddingBidHistory(bids) {
    const list = document.getElementById('bidHistoryList');
    
    if (!bids || bids.length === 0) {
        list.innerHTML = '<p style="text-align: center; padding: 2rem; color: var(--gray-600);">No bids yet</p>';
        return;
    }
    
    list.innerHTML = bids.map((bid, index) => `
        <div style="display: flex; justify-content: space-between; padding: 0.75rem; border-bottom: 1px solid var(--gray-100); ${index === 0 ? 'background: #FFF9E6; font-weight: bold;' : ''}">
            <div>
                <div style="font-weight: 600;">${bid.Club_Name}</div>
                <div style="font-size: 0.875rem; color: var(--gray-600);">
                    ${new Date(bid.Bid_Time).toLocaleString()}
                </div>
            </div>
            <div style="text-align: right;">
                <div style="font-size: 1.25rem; font-weight: bold;">${Math.floor(bid.Bid_Amount)} Coins</div>
                <span class="badge" style="background: ${bid.Status === 'Active' ? '#E6F7FF' : bid.Status === 'Won' ? '#E6FFE6' : '#FFE6E6'}; color: ${bid.Status === 'Active' ? '#0066CC' : bid.Status === 'Won' ? '#00AA00' : '#CC0000'}; padding: 0.25rem 0.75rem; border-radius: 6px; font-size: 0.875rem;">${bid.Status}</span>
            </div>
        </div>
    `).join('');
}

function closeBidHistoryModal() {
    document.getElementById('bidHistoryModal').style.display = 'none';
}

async function loadBiddingClubLeaderboard() {
    try {
        const response = await fetch('backend/bidding_api.php?action=get_currency_leaderboard');
        const data = await response.json();
        
        if (data.success) {
            displayBiddingClubLeaderboard(data.leaderboard);
        }
    } catch (error) {
        console.error('Error loading club leaderboard:', error);
    }
}

function displayBiddingClubLeaderboard(leaderboard) {
    const tbody = document.getElementById('biddingClubLeaderboardBody');
    
    if (!tbody) return;
    
    if (!leaderboard || leaderboard.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;">No club data available.</td></tr>';
        return;
    }
    
    tbody.innerHTML = '';
    leaderboard.forEach((club, index) => {
        const rank = index + 1;
        const medal = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : '';
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td><span style="font-size: 1.25rem; margin-right: 0.5rem;">${medal}</span> ${rank}</td>
            <td style="font-weight: 600;">${club.Club_Name}</td>
            <td style="font-weight: bold; color: #FFD700;">${Math.floor(club.Currency_Balance)} Coins</td>
            <td>${club.Total_Members}</td>
            <td>${parseFloat(club.Total_Volunteer_Hours).toFixed(1)} hrs</td>
            <td>${club.Total_Badges_Earned}</td>
            <td>${club.Equipment_Owned}</td>
        `;
        tbody.appendChild(row);
    });
}

function switchBiddingTab(tab) {
    // Update tab buttons
    document.querySelectorAll('.bidding-tab').forEach(btn => {
        btn.classList.remove('active');
        btn.style.color = 'var(--gray-600)';
        btn.style.borderBottomColor = 'transparent';
    });
    
    const activeTab = document.querySelector(`.bidding-tab[data-tab="${tab}"]`);
    if (activeTab) {
        activeTab.classList.add('active');
        activeTab.style.color = 'var(--gray-900)';
        activeTab.style.borderBottomColor = 'var(--gray-900)';
    }
    
    // Update content visibility
    document.querySelectorAll('.bidding-content').forEach(content => {
        content.style.display = 'none';
    });
    
    const activeContent = document.getElementById(`bidding-${tab}`);
    if (activeContent) {
        activeContent.style.display = 'block';
    }
    
    // Load data for the tab
    if (tab === 'my-auctions') {
        loadMyBiddingAuctions();
    } else if (tab === 'my-bids') {
        loadMyBiddingBids();
    } else if (tab === 'club-leaderboard') {
        loadBiddingClubLeaderboard();
    }
}

async function loadMyBiddingAuctions() {
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_my_auctions&club_id=${currentBiddingClubId}`);
        const data = await response.json();
        
        if (data.success) {
            displayMyBiddingAuctions(data.auctions);
        }
    } catch (error) {
        console.error('Error loading my auctions:', error);
    }
}

function displayMyBiddingAuctions(auctions) {
    const grid = document.getElementById('myAuctionsGrid');
    
    if (!auctions || auctions.length === 0) {
        grid.innerHTML = '<p style="text-align: center; color: var(--gray-600); padding: 2rem; grid-column: 1/-1;">You haven\'t created any auctions yet.</p>';
        return;
    }
    
    grid.innerHTML = auctions.map(auction => `
        <div class="card" style="padding: 1.5rem; display: flex; flex-direction: column; gap: 1rem;">
            <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem;">
                <div style="flex: 1; min-width: 0;">
                    <h3 style="font-size: 1.25rem; margin-bottom: 0.5rem; word-wrap: break-word;">${auction.Equipment_Name}</h3>
                    <span class="badge" style="background: var(--gray-100); padding: 0.25rem 0.75rem; border-radius: 6px; display: inline-block;">${auction.Type}</span>
                </div>
                <span class="badge" style="background: ${auction.Status === 'Active' ? '#E6F7FF' : '#FFE6E6'}; color: ${auction.Status === 'Active' ? '#0066CC' : '#CC0000'}; padding: 0.25rem 0.75rem; border-radius: 6px; white-space: nowrap;">${auction.Status}</span>
            </div>
            
            <div style="display: flex; flex-direction: column; gap: 0.5rem;">
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100); gap: 1rem;">
                    <span style="color: var(--gray-600); white-space: nowrap;">Current Bid</span>
                    <span style="font-weight: 600; color: #FFD700; font-size: 1.25rem; text-align: right;">
                        ${auction.Current_Highest_Bid ? Math.floor(auction.Current_Highest_Bid) + ' Coins' : 'No bids'}
                    </span>
                </div>
                ${auction.Highest_Bidder_Club ? `
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100); gap: 1rem;">
                    <span style="color: var(--gray-600); white-space: nowrap;">Leading Bidder</span>
                    <span style="font-weight: 600; text-align: right; word-wrap: break-word;">${auction.Highest_Bidder_Club}</span>
                </div>
                ` : ''}
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 0; gap: 1rem;">
                    <span style="color: var(--gray-600); white-space: nowrap;">Ends</span>
                    <span style="font-weight: 600; text-align: right; font-size: 0.875rem;">${new Date(auction.Auction_End).toLocaleString()}</span>
                </div>
            </div>
            
            ${auction.Status === 'Active' ? `
            <button onclick="cancelBiddingAuction(${auction.Auction_ID})" class="btn-secondary" style="width: 100%; padding: 0.75rem; background: #CC0000; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600;">
                Cancel Auction
            </button>
            ` : ''}
        </div>
    `).join('');
}

async function loadMyBiddingBids() {
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_my_bids&club_id=${currentBiddingClubId}`);
        const data = await response.json();
        
        if (data.success) {
            document.getElementById('biddingMyBidsCount').textContent = data.bids.filter(b => b.Status === 'Active').length;
            displayMyBiddingBids(data.bids);
        }
    } catch (error) {
        console.error('Error loading my bids:', error);
    }
}

function displayMyBiddingBids(bids) {
    const list = document.getElementById('myBidsList');
    
    if (!bids || bids.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: var(--gray-600); padding: 2rem;">You haven\'t placed any bids yet.</p>';
        return;
    }
    
    list.innerHTML = '<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 1.5rem;">' + bids.map(bid => `
        <div class="card" style="padding: 1.5rem;">
            <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 1rem;">
                <div>
                    <h3 style="font-size: 1.25rem; margin-bottom: 0.5rem;">${bid.Equipment_Name}</h3>
                    <span class="badge" style="background: var(--gray-100); padding: 0.25rem 0.75rem; border-radius: 6px;">Auction by ${bid.Owner_Club}</span>
                </div>
                <span class="badge" style="background: ${bid.Status === 'Active' ? '#E6F7FF' : bid.Status === 'Won' ? '#E6FFE6' : '#FFE6E6'}; color: ${bid.Status === 'Active' ? '#0066CC' : bid.Status === 'Won' ? '#00AA00' : '#CC0000'}; padding: 0.25rem 0.75rem; border-radius: 6px;">${bid.Status}</span>
            </div>
            
            <div style="margin: 1rem 0;">
                <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100);">
                    <span style="color: var(--gray-600);">Your Bid</span>
                    <span style="font-weight: 600; color: #FFD700; font-size: 1.25rem;">${Math.floor(bid.Bid_Amount)} Coins</span>
                </div>
                <div style="display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--gray-100);">
                    <span style="color: var(--gray-600);">Bid Time</span>
                    <span style="font-weight: 600;">${new Date(bid.Bid_Time).toLocaleString()}</span>
                </div>
                <div style="display: flex; justify-content: space-between; padding: 0.5rem 0;">
                    <span style="color: var(--gray-600);">Auction Status</span>
                    <span style="font-weight: 600;">${bid.Auction_Status}</span>
                </div>
            </div>
        </div>
    `).join('') + '</div>';
}

function populateBiddingEquipmentSelect() {
    const select = document.getElementById('auctionEquipment');
    if (!select) return;
    
    select.innerHTML = '<option value="">Select equipment...</option>';
    
    // Filter equipment owned by current club
    const myEquipment = equipmentData.filter(e => e.Owner_Club_ID == currentBiddingClubId);
    
    myEquipment.forEach(equip => {
        const option = document.createElement('option');
        option.value = equip.Equip_ID;
        option.textContent = `${equip.EquipName} (${equip.Type})`;
        select.appendChild(option);
    });
}

function openCreateAuctionModal() {
    populateBiddingEquipmentSelect();
    document.getElementById('createAuctionModal').style.display = 'flex';
}

function closeCreateAuctionModal() {
    document.getElementById('createAuctionModal').style.display = 'none';
}

document.getElementById('createAuctionForm')?.addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const equipId = document.getElementById('auctionEquipment').value;
    const startingPrice = document.getElementById('startingPrice').value;
    const duration = document.getElementById('auctionDuration').value;
    
    try {
        const formData = new FormData();
        formData.append('action', 'create_auction');
        formData.append('equip_id', equipId);
        formData.append('starting_price', startingPrice);
        formData.append('duration_hours', duration);
        
        const response = await fetch('backend/bidding_api.php', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('Auction created successfully!');
            closeCreateAuctionModal();
            document.getElementById('createAuctionForm').reset();
            loadBiddingActiveAuctions();
        } else {
            alert(data.message || 'Failed to create auction');
        }
    } catch (error) {
        console.error('Error creating auction:', error);
        alert('An error occurred while creating auction');
    }
});

async function cancelBiddingAuction(auctionId) {
    if (!confirm('Are you sure you want to cancel this auction?')) return;
    
    try {
        const formData = new FormData();
        formData.append('action', 'cancel_auction');
        formData.append('auction_id', auctionId);
        formData.append('club_id', currentBiddingClubId);
        
        const response = await fetch('backend/bidding_api.php', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('Auction cancelled');
            loadMyBiddingAuctions();
            loadBiddingActiveAuctions();
        } else {
            alert(data.message || 'Failed to cancel auction');
        }
    } catch (error) {
        console.error('Error cancelling auction:', error);
    }
}
