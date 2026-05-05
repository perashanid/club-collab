// Global variables
let currentClubId = null;
let clubs = [];
let equipment = [];

// Initialize page
document.addEventListener('DOMContentLoaded', function() {
    console.log('Bidding page loaded');
    loadClubs();
    loadEquipment();
    loadClubBalance();
    loadActiveAuctions();
    loadLeaderboard();
    
    // Auto-refresh every 30 seconds
    setInterval(() => {
        loadActiveAuctions();
        loadClubBalance();
    }, 30000);
    
    // Setup create auction form
    const form = document.getElementById('createAuctionForm');
    if (form) {
        form.addEventListener('submit', handleCreateAuction);
    }
});

async function loadClubs() {
    console.log('Loading clubs...');
    try {
        const response = await fetch('backend/get_clubs.php');
        const data = await response.json();
        console.log('Clubs loaded:', data);
        if (data.success) {
            clubs = data.clubs;
            // Set first club as current (in real app, this would be from session)
            if (clubs.length > 0) {
                currentClubId = clubs[0].Club_ID;
            }
        }
    } catch (error) {
        console.error('Error loading clubs:', error);
    }
}

async function loadEquipment() {
    try {
        const response = await fetch('backend/get_equip.php');
        const data = await response.json();
        if (data.success) {
            equipment = data.equipment;
            populateEquipmentSelect();
        }
    } catch (error) {
        console.error('Error loading equipment:', error);
    }
}

function populateEquipmentSelect() {
    const select = document.getElementById('auctionEquipment');
    select.innerHTML = '<option value="">Select equipment...</option>';
    
    // Filter equipment owned by current club
    const myEquipment = equipment.filter(e => e.Owner_Club_ID == currentClubId);
    
    myEquipment.forEach(equip => {
        const option = document.createElement('option');
        option.value = equip.Equip_ID;
        option.textContent = `${equip.Name} (${equip.Type})`;
        select.appendChild(option);
    });
}

async function loadClubBalance() {
    if (!currentClubId) return;
    
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_club_currency&club_id=${currentClubId}`);
        const data = await response.json();
        if (data.success) {
            document.getElementById('clubBalance').textContent = Math.floor(data.balance) + ' Coins';
        }
    } catch (error) {
        console.error('Error loading balance:', error);
    }
}

async function loadActiveAuctions() {
    console.log('Loading active auctions...');
    try {
        // First complete any expired auctions
        await fetch('backend/bidding_api.php?action=complete_expired_auctions');
        
        const response = await fetch('backend/bidding_api.php?action=get_active_auctions');
        const data = await response.json();
        console.log('Active auctions:', data);
        
        if (data.success) {
            displayActiveAuctions(data.auctions);
        }
    } catch (error) {
        console.error('Error loading auctions:', error);
    }
}

function displayActiveAuctions(auctions) {
    const grid = document.getElementById('activeAuctionsGrid');
    
    if (auctions.length === 0) {
        grid.innerHTML = '<p style="text-align: center; color: var(--gray-600); padding: 2rem;">No active auctions at the moment.</p>';
        return;
    }
    
    grid.innerHTML = auctions.map(auction => {
        const hoursRemaining = parseInt(auction.Hours_Remaining);
        const isUrgent = hoursRemaining < 2;
        const minBid = auction.Current_Highest_Bid ? parseFloat(auction.Current_Highest_Bid) + 10 : parseFloat(auction.Starting_Price);
        const isMyAuction = auction.Owner_Club == getClubName(currentClubId);
        
        return `
            <div class="auction-card">
                <div class="auction-header">
                    <div>
                        <div class="equipment-name">${auction.Equipment_Name}</div>
                        <span class="equipment-type">${auction.Equipment_Type}</span>
                    </div>
                </div>
                
                <div class="auction-info">
                    <div class="info-row">
                        <span class="info-label">Owner Club</span>
                        <span class="info-value">${auction.Owner_Club}</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Starting Price</span>
                        <span class="info-value">${Math.floor(auction.Starting_Price)} Coins</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Current Bid</span>
                        <span class="info-value current-bid">
                            ${auction.Current_Highest_Bid ? Math.floor(auction.Current_Highest_Bid) + ' Coins' : 'No bids yet'}
                        </span>
                    </div>
                    ${auction.Highest_Bidder_Club ? `
                    <div class="info-row">
                        <span class="info-label">Leading Bidder</span>
                        <span class="info-value">${auction.Highest_Bidder_Club}</span>
                    </div>
                    ` : ''}
                    <div class="info-row">
                        <span class="info-label">Total Bids</span>
                        <span class="info-value">${auction.Total_Bids}</span>
                    </div>
                </div>
                
                <div class="time-remaining ${isUrgent ? 'urgent' : ''}">
                    <i class="fas fa-clock"></i>
                    <span>${hoursRemaining > 0 ? hoursRemaining + ' hours' : 'Less than 1 hour'} remaining</span>
                </div>
                
                ${!isMyAuction ? `
                <div class="bid-input-group">
                    <input type="number" 
                           class="bid-input" 
                           id="bid-${auction.Auction_ID}" 
                           placeholder="Min: ${Math.floor(minBid)} coins"
                           min="${Math.floor(minBid)}"
                           step="10">
                    <button class="bid-btn" onclick="placeBid(${auction.Auction_ID})">
                        <i class="fas fa-gavel"></i> Bid
                    </button>
                </div>
                ` : '<p style="text-align: center; color: var(--gray-600); margin-top: 1rem;">Your auction</p>'}
                
                <button onclick="viewBidHistory(${auction.Auction_ID})" 
                        style="width: 100%; margin-top: 0.5rem; padding: 0.5rem; background: var(--gray-100); border: none; border-radius: 8px; cursor: pointer;">
                    View Bid History
                </button>
            </div>
        `;
    }).join('');
}

async function placeBid(auctionId) {
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
        formData.append('club_id', currentClubId);
        formData.append('bid_amount', bidAmount);
        
        const response = await fetch('backend/bidding_api.php', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('Bid placed successfully!');
            bidInput.value = '';
            loadActiveAuctions();
            loadClubBalance();
        } else {
            alert(data.message || 'Failed to place bid');
        }
    } catch (error) {
        console.error('Error placing bid:', error);
        alert('An error occurred while placing bid');
    }
}

async function viewBidHistory(auctionId) {
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_bid_history&auction_id=${auctionId}`);
        const data = await response.json();
        
        if (data.success) {
            displayBidHistory(data.bids);
            document.getElementById('bidDetailsModal').classList.add('active');
        }
    } catch (error) {
        console.error('Error loading bid history:', error);
    }
}

function displayBidHistory(bids) {
    const list = document.getElementById('bidHistoryList');
    
    if (bids.length === 0) {
        list.innerHTML = '<p style="text-align: center; padding: 2rem; color: var(--gray-600);">No bids yet</p>';
        return;
    }
    
    list.innerHTML = bids.map((bid, index) => `
        <div class="bid-item">
            <div>
                <div style="font-weight: 600;">${bid.Club_Name}</div>
                <div style="font-size: 0.875rem; color: var(--gray-600);">
                    ${new Date(bid.Bid_Time).toLocaleString()}
                </div>
            </div>
            <div style="text-align: right;">
                <div style="font-size: 1.25rem; font-weight: bold;">${Math.floor(bid.Bid_Amount)} Coins</div>
                <span class="status-badge status-${bid.Status.toLowerCase()}">${bid.Status}</span>
            </div>
        </div>
    `).join('');
}

async function loadLeaderboard() {
    try {
        const response = await fetch('backend/bidding_api.php?action=get_currency_leaderboard');
        const data = await response.json();
        
        if (data.success) {
            displayLeaderboard(data.leaderboard);
        }
    } catch (error) {
        console.error('Error loading leaderboard:', error);
    }
}

function displayLeaderboard(leaderboard) {
    const tbody = document.getElementById('leaderboardBody');
    
    tbody.innerHTML = leaderboard.map((club, index) => {
        const rank = index + 1;
        const rankClass = rank <= 3 ? `rank-${rank}` : 'rank-other';
        
        return `
            <tr>
                <td><span class="rank-badge ${rankClass}">${rank}</span></td>
                <td style="font-weight: 600;">${club.Club_Name}</td>
                <td style="font-weight: bold; color: #FFD700;">${Math.floor(club.Currency_Balance)} Coins</td>
                <td>${club.Total_Members}</td>
                <td>${parseFloat(club.Total_Volunteer_Hours).toFixed(1)} hrs</td>
                <td>${club.Total_Badges_Earned}</td>
                <td>${club.Equipment_Owned}</td>
            </tr>
        `;
    }).join('');
}

async function loadMyAuctions() {
    if (!currentClubId) return;
    
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_my_auctions&club_id=${currentClubId}`);
        const data = await response.json();
        
        if (data.success) {
            displayMyAuctions(data.auctions);
        }
    } catch (error) {
        console.error('Error loading my auctions:', error);
    }
}

function displayMyAuctions(auctions) {
    const grid = document.getElementById('myAuctionsGrid');
    
    if (auctions.length === 0) {
        grid.innerHTML = '<p style="text-align: center; color: var(--gray-600); padding: 2rem;">You haven\'t created any auctions yet.</p>';
        return;
    }
    
    grid.innerHTML = auctions.map(auction => `
        <div class="auction-card">
            <div class="auction-header">
                <div>
                    <div class="equipment-name">${auction.Equipment_Name}</div>
                    <span class="equipment-type">${auction.Type}</span>
                </div>
                <span class="status-badge status-${auction.Status.toLowerCase()}">${auction.Status}</span>
            </div>
            
            <div class="auction-info">
                <div class="info-row">
                    <span class="info-label">Current Bid</span>
                    <span class="info-value current-bid">
                        ${auction.Current_Highest_Bid ? Math.floor(auction.Current_Highest_Bid) + ' Coins' : 'No bids'}
                    </span>
                </div>
                ${auction.Highest_Bidder_Club ? `
                <div class="info-row">
                    <span class="info-label">Leading Bidder</span>
                    <span class="info-value">${auction.Highest_Bidder_Club}</span>
                </div>
                ` : ''}
                <div class="info-row">
                    <span class="info-label">Ends</span>
                    <span class="info-value">${new Date(auction.Auction_End).toLocaleString()}</span>
                </div>
            </div>
            
            ${auction.Status === 'Active' ? `
            <button onclick="cancelAuction(${auction.Auction_ID})" class="bid-btn" style="width: 100%; margin-top: 1rem; background: #CC0000;">
                Cancel Auction
            </button>
            ` : ''}
        </div>
    `).join('');
}

async function loadMyBids() {
    if (!currentClubId) return;
    
    try {
        const response = await fetch(`backend/bidding_api.php?action=get_my_bids&club_id=${currentClubId}`);
        const data = await response.json();
        
        if (data.success) {
            displayMyBids(data.bids);
        }
    } catch (error) {
        console.error('Error loading my bids:', error);
    }
}

function displayMyBids(bids) {
    const list = document.getElementById('myBidsList');
    
    if (bids.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: var(--gray-600); padding: 2rem;">You haven\'t placed any bids yet.</p>';
        return;
    }
    
    list.innerHTML = bids.map(bid => `
        <div class="auction-card">
            <div class="auction-header">
                <div>
                    <div class="equipment-name">${bid.Equipment_Name}</div>
                    <span class="equipment-type">Auction by ${bid.Owner_Club}</span>
                </div>
                <span class="status-badge status-${bid.Status.toLowerCase()}">${bid.Status}</span>
            </div>
            
            <div class="auction-info">
                <div class="info-row">
                    <span class="info-label">Your Bid</span>
                    <span class="info-value current-bid">${Math.floor(bid.Bid_Amount)} Coins</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Bid Time</span>
                    <span class="info-value">${new Date(bid.Bid_Time).toLocaleString()}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Auction Status</span>
                    <span class="info-value">${bid.Auction_Status}</span>
                </div>
            </div>
        </div>
    `).join('');
}

function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
    event.target.closest('.tab').classList.add('active');
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    document.getElementById(tabName).classList.add('active');
    
    // Load data for the tab
    if (tabName === 'my-auctions') {
        loadMyAuctions();
    } else if (tabName === 'my-bids') {
        loadMyBids();
    } else if (tabName === 'leaderboard') {
        loadLeaderboard();
    }
}

function openCreateAuctionModal() {
    document.getElementById('createAuctionModal').classList.add('active');
}

function closeCreateAuctionModal() {
    document.getElementById('createAuctionModal').classList.remove('active');
}

function closeBidDetailsModal() {
    document.getElementById('bidDetailsModal').classList.remove('active');
}

async function handleCreateAuction(e) {
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
            loadActiveAuctions();
        } else {
            alert(data.message || 'Failed to create auction');
        }
    } catch (error) {
        console.error('Error creating auction:', error);
        alert('An error occurred while creating auction');
    }
}

async function cancelAuction(auctionId) {
    if (!confirm('Are you sure you want to cancel this auction?')) return;
    
    try {
        const formData = new FormData();
        formData.append('action', 'cancel_auction');
        formData.append('auction_id', auctionId);
        formData.append('club_id', currentClubId);
        
        const response = await fetch('backend/bidding_api.php', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('Auction cancelled');
            loadMyAuctions();
            loadActiveAuctions();
        } else {
            alert(data.message || 'Failed to cancel auction');
        }
    } catch (error) {
        console.error('Error cancelling auction:', error);
    }
}

function getClubName(clubId) {
    const club = clubs.find(c => c.Club_ID == clubId);
    return club ? club.Name : 'Unknown';
}

// Close modals when clicking outside
window.onclick = function(event) {
    if (event.target.classList.contains('modal')) {
        event.target.classList.remove('active');
    }
}
