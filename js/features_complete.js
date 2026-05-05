// ===== PAGINATION =====
const ITEMS_PER_PAGE = 10;
let currentPages = {
    equipment: 1,
    bookings: 1,
    volunteers: 1,
    badges: 1
};

function paginateData(data, page, itemsPerPage = ITEMS_PER_PAGE) {
    const start = (page - 1) * itemsPerPage;
    const end = start + itemsPerPage;
    return data.slice(start, end);
}

function createPagination(totalItems, currentPage, containerId, onPageChange) {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    const totalPages = Math.ceil(totalItems / ITEMS_PER_PAGE);
    if (totalPages <= 1) {
        container.innerHTML = '';
        return;
    }
    
    let html = '<div class="pagination-controls">';
    
    // Previous button
    html += `<button class="pagination-btn" ${currentPage === 1 ? 'disabled' : ''} onclick="${onPageChange}(${currentPage - 1})">
        <i class="fa-solid fa-chevron-left"></i>
    </button>`;
    
    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || (i >= currentPage - 1 && i <= currentPage + 1)) {
            html += `<button class="pagination-btn ${i === currentPage ? 'active' : ''}" onclick="${onPageChange}(${i})">${i}</button>`;
        } else if (i === currentPage - 2 || i === currentPage + 2) {
            html += '<span class="pagination-dots">...</span>';
        }
    }
    
    // Next button
    html += `<button class="pagination-btn" ${currentPage === totalPages ? 'disabled' : ''} onclick="${onPageChange}(${currentPage + 1})">
        <i class="fa-solid fa-chevron-right"></i>
    </button>`;
    
    html += '</div>';
    container.innerHTML = html;
}

// ===== SORTING =====
let sortDirections = {};

function sortTable(tableId, columnIndex) {
    const table = document.getElementById(tableId);
    const tbody = table.querySelector('tbody');
    const rows = Array.from(tbody.querySelectorAll('tr'));
    
    const direction = sortDirections[`${tableId}-${columnIndex}`] || 'asc';
    const newDirection = direction === 'asc' ? 'desc' : 'asc';
    sortDirections[`${tableId}-${columnIndex}`] = newDirection;
    
    rows.sort((a, b) => {
        const aValue = a.cells[columnIndex].textContent.trim();
        const bValue = b.cells[columnIndex].textContent.trim();
        
        // Try to parse as number
        const aNum = parseFloat(aValue.replace(/[^0-9.-]/g, ''));
        const bNum = parseFloat(bValue.replace(/[^0-9.-]/g, ''));
        
        if (!isNaN(aNum) && !isNaN(bNum)) {
            return newDirection === 'asc' ? aNum - bNum : bNum - aNum;
        }
        
        // String comparison
        return newDirection === 'asc' 
            ? aValue.localeCompare(bValue)
            : bValue.localeCompare(aValue);
    });
    
    rows.forEach(row => tbody.appendChild(row));
}

// Make sortTable globally available
window.sortTable = sortTable;

// ===== NEXT AVAILABLE TIME FOR EQUIPMENT =====
async function getNextAvailableTime(equipId) {
    try {
        const response = await fetch(`backend/bookings_api.php?action=get_next_available&equip_id=${equipId}`);
        const data = await response.json();
        if (data.success && data.data && data.data.Next_Available) {
            return data.data.Next_Available;
        }
        return 'Available Now';
    } catch (error) {
        return 'Unknown';
    }
}

// ===== BOOKING CONFLICT DETECTION =====
async function checkBookingConflict(equipId, borrowTime, returnTime, excludeBookingId = null) {
    try {
        let url = `backend/bookings_api.php?action=check_availability&equip_id=${equipId}&borrow_time=${encodeURIComponent(borrowTime)}&return_time=${encodeURIComponent(returnTime)}`;
        const response = await fetch(url);
        const data = await response.json();
        return data;
    } catch (error) {
        return { available: true };
    }
}

// ===== BADGE PROGRESS TRACKER =====
async function getStudentBadgeProgress(studentId) {
    try {
        const response = await fetch(`backend/badges_api.php?action=get_badge_progress&student_id=${studentId}`);
        const data = await response.json();
        if (data.success && data.data) {
            return data.data;
        }
        return null;
    } catch (error) {
        return null;
    }
}

function showBadgeProgressModal(studentId, studentName) {
    getStudentBadgeProgress(studentId).then(progress => {
        if (!progress) {
            alert('No progress data available');
            return;
        }
        
        const modal = document.getElementById('crudModal');
        const modalTitle = document.getElementById('modalTitle');
        const modalBody = document.querySelector('.modal-body');
        
        modalTitle.textContent = `Badge Progress - ${studentName}`;
        
        let html = `
            <div class="badge-progress-container">
                <div class="progress-stats">
                    <div class="stat-card">
                        <h3>${progress.Total_Hours || 0}</h3>
                        <p>Total Hours</p>
                    </div>
                    <div class="stat-card">
                        <h3>${progress.Events_Participated || 0}</h3>
                        <p>Events</p>
                    </div>
                    <div class="stat-card">
                        <h3>${progress.Badges_Earned_Count || 0}</h3>
                        <p>Badges Earned</p>
                    </div>
                    <div class="stat-card">
                        <h3>${progress.Highest_Tier_Achieved || 'None'}</h3>
                        <p>Highest Tier</p>
                    </div>
                </div>
                
                ${progress.Next_Badge_Name ? `
                <div class="next-badge">
                    <h3>Next Badge: ${progress.Next_Badge_Name}</h3>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${progress.Progress_To_Next_Badge || 0}%"></div>
                    </div>
                    <p>${progress.Hours_To_Next_Badge || 0} hours remaining (${progress.Progress_To_Next_Badge || 0}% complete)</p>
                </div>
                ` : '<p>All badges earned!</p>'}
            </div>
        `;
        
        modalBody.innerHTML = html;
        modal.style.display = 'flex';
    });
}

// ===== VOLUNTEER PORTFOLIO VIEW =====
async function showVolunteerPortfolio(studentId, studentName) {
    try {
        const response = await fetch(`backend/analytics.php?action=volunteer_profile&student_id=${studentId}`);
        const data = await response.json();
        
        if (!data.success || !data.data || data.data.length === 0) {
            alert('No portfolio data available');
            return;
        }
        
        const profile = data.data[0];
        const modal = document.getElementById('crudModal');
        const modalTitle = document.getElementById('modalTitle');
        const modalBody = document.querySelector('.modal-body');
        
        modalTitle.textContent = `Volunteer Portfolio - ${studentName}`;
        
        let html = `
            <div class="portfolio-container">
                <div class="portfolio-header">
                    <h2>${profile.Name}</h2>
                    <p>${profile.Email}</p>
                    <span class="engagement-badge">${profile.Engagement_Level || 'Inactive'}</span>
                </div>
                
                <div class="portfolio-stats">
                    <div class="stat-item">
                        <strong>Clubs Joined:</strong> ${profile.Clubs_Joined || 'None'}
                    </div>
                    <div class="stat-item">
                        <strong>Events Volunteered:</strong> ${profile.Events_Volunteered || 0}
                    </div>
                    <div class="stat-item">
                        <strong>Total Hours:</strong> ${profile.Total_Hours || 0}
                    </div>
                    <div class="stat-item">
                        <strong>Average Hours/Event:</strong> ${profile.Average_Hours_Per_Event || 0}
                    </div>
                    <div class="stat-item">
                        <strong>Last Volunteer Date:</strong> ${profile.Last_Volunteer_Date || 'N/A'}
                    </div>
                    <div class="stat-item">
                        <strong>Executive Status:</strong> ${profile.Is_Executive || 'No'}
                    </div>
                </div>
                
                <button class="btn-primary" onclick="showBadgeProgressModal(${studentId}, '${studentName}')">
                    View Badge Progress
                </button>
            </div>
        `;
        
        modalBody.innerHTML = html;
        modal.style.display = 'flex';
    } catch (error) {
        alert('Error loading portfolio');
    }
}

// Make functions globally available
window.showBadgeProgressModal = showBadgeProgressModal;
window.showVolunteerPortfolio = showVolunteerPortfolio;

// ===== ADVANCED SEARCH =====
function setupAdvancedSearch() {
    const searchInput = document.getElementById('searchInput');
    if (!searchInput) return;
    
    let searchTimeout;
    searchInput.addEventListener('input', (e) => {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            const term = e.target.value.toLowerCase();
            performGlobalSearch(term);
        }, 300);
    });
}

function performGlobalSearch(term) {
    // Search across all visible tables
    const tables = document.querySelectorAll('.section.active table tbody');
    tables.forEach(tbody => {
        const rows = tbody.querySelectorAll('tr');
        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = text.includes(term) ? '' : 'none';
        });
    });
}

// ===== EVENT FILTERS =====
function setupEventFilters() {
    // Add event date filter
    const eventsSection = document.getElementById('section-events');
    if (!eventsSection) return;
    
    const filterContainer = eventsSection.querySelector('.filters');
    if (!filterContainer) {
        // Create filter container
        const tableContainer = eventsSection.querySelector('.table-container');
        const filterDiv = document.createElement('div');
        filterDiv.className = 'filters';
        filterDiv.innerHTML = `
            <div class="filter-group">
                <label>Date</label>
                <select id="filterEventDate">
                    <option value="">All Dates</option>
                    <option value="past">Past Events</option>
                    <option value="upcoming">Upcoming Events</option>
                    <option value="today">Today</option>
                </select>
            </div>
            <div class="filter-group">
                <label>Organizing Club</label>
                <select id="filterEventClub">
                    <option value="">All Clubs</option>
                </select>
            </div>
        `;
        tableContainer.insertBefore(filterDiv, tableContainer.querySelector('.table-responsive'));
        
        // Populate club filter
        if (clubsData && clubsData.length > 0) {
            const clubFilter = document.getElementById('filterEventClub');
            clubsData.forEach(club => {
                const option = document.createElement('option');
                option.value = club.Club_ID;
                option.textContent = club.ClubName;
                clubFilter.appendChild(option);
            });
        }
        
        // Bind events
        document.getElementById('filterEventDate')?.addEventListener('change', filterEvents);
        document.getElementById('filterEventClub')?.addEventListener('change', filterEvents);
    }
}

function filterEvents() {
    const dateFilter = document.getElementById('filterEventDate')?.value || '';
    const clubFilter = document.getElementById('filterEventClub')?.value || '';
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const filtered = eventsData.filter(item => {
        const eventDate = new Date(item.Date);
        eventDate.setHours(0, 0, 0, 0);
        
        let matchDate = true;
        if (dateFilter === 'past') matchDate = eventDate < today;
        else if (dateFilter === 'upcoming') matchDate = eventDate > today;
        else if (dateFilter === 'today') matchDate = eventDate.getTime() === today.getTime();
        
        const matchClub = !clubFilter || item.Club_ID == clubFilter;
        
        return matchDate && matchClub;
    });
    
    renderEventRows(filtered);
}

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    setupAdvancedSearch();
    setTimeout(() => {
        setupEventFilters();
    }, 1000);
});
