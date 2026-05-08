document.getElementById('signupForm').addEventListener('submit', async (e) => {
    e.preventDefault(); // Stop the page from reloading

    // Get the current date to set default terms for executives
    const today = new Date().toISOString().split('T')[0];
    const nextYear = new Date(new Date().setFullYear(new Date().getFullYear() + 1)).toISOString().split('T')[0];

    // Grab all the values using their IDs
    const newStudentData = {
        name: document.getElementById('signupName').value,
        email: document.getElementById('signupEmail').value,
        password: document.getElementById('signupPassword').value,
        street: document.getElementById('signupStreet').value,
        city: document.getElementById('signupCity').value,
        zip: document.getElementById('signupZip').value,
        contact_no: document.getElementById('signupContact').value,
        student_type: document.getElementById('signupType').value,
        // Default values for general student
        year_of_study: 1, 
        major: 'Undeclared',
        // Default values for club executive
        position: 'Member',
        term_start: today,
        term_end: nextYear
    };

    try {
        // Send the data to your backend
        const response = await fetch('backend/students.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newStudentData)
        });

        const data = await response.json();

        if (data.success) {
            alert('Sign up successful! Please log in.');
            window.location.href = 'login.html'; // Redirect to login page
        } else {
            alert('Sign up failed: ' + data.error);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('An error occurred during sign up.');
    }
});