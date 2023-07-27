// Global variables
const pageSize = 10; // Number of records to load per request
let currentPage = 1; // Current page number
let isLoading = false; // Flag to prevent multiple simultaneous requests

// Function to toggle the side menu
// Function to toggle the side menu
const toggleSideMenu = () => {
  const body = document.body;
  const sideMenu = document.getElementById('sideMenu');
  const menuButton = document.querySelector('.menu-button');

  body.classList.toggle('menu-open');
  menuButton.classList.toggle('animation');

  // Reset the animation after it's completed
  menuButton.addEventListener('transitionend', () => {
    menuButton.classList.remove('animation');
  });
};

// Function to fetch sensor data from the server and update the sensorDataList
const fetchSensorData = () => {
  if (isLoading) return; // Avoid multiple simultaneous requests
  isLoading = true;

  fetch(`get_data.php?page=${currentPage}&size=${pageSize}`)
    .then(response => response.json())
    .then(data => {
      const sensorDataList = document.getElementById('sensorDataList');

      // Populate the sensorDataList with the received data
      data.forEach(record => {
        const listItem = document.createElement('div');
        listItem.classList.add('sensor-item');
        listItem.innerHTML = `
          <span>${record.timestamp}</span>
          <span>${record.temperature} °C</span>
          <span>${record.humidity} %</span>
          <span>${record.pressure} hPa</span>
        `;
        sensorDataList.appendChild(listItem);
      });

      // Increment the current page for the next request
      currentPage++;

      isLoading = false; // Allow subsequent requests
    })
    .catch(error => {
      console.error('Error fetching sensor data:', error);
      isLoading = false; // Reset the isLoading flag on error
    });
};

// Function to check if the user has scrolled to the bottom of the sensorDataList
const isScrollingToBottom = () => {
  const sensorDataList = document.getElementById('sensorDataList');
  const windowHeight = sensorDataList.clientHeight;
  const scrollTop = sensorDataList.scrollTop;
  const scrollHeight = sensorDataList.scrollHeight;

  return scrollTop + windowHeight >= scrollHeight - 100; // Load more data when within 100 pixels from the bottom
};

// Function to handle the scroll event and trigger lazy loading
const handleScroll = () => {
  if (isScrollingToBottom()) {
    fetchSensorData(); // Load more data
  }
};

// Attach the scroll event listener to the sensorDataList for lazy loading
document.getElementById('sensorDataList').addEventListener('scroll', handleScroll);

// Function to toggle light and dark modes
const toggleDarkMode = () => {
  const darkModeToggle = document.getElementById('darkModeToggle');
  const body = document.body;

  if (darkModeToggle.checked) {
    body.classList.add('dark-mode');
  } else {
    body.classList.remove('dark-mode');
  }
};

// Attach event listener to darkModeToggle
document.getElementById('darkModeToggle').addEventListener('change', toggleDarkMode);

// Fetch initial data on page load
fetchSensorData();

// Immediately apply the dark mode based on the state of the switch on page load
toggleDarkMode();
