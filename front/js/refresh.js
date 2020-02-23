/* Refresh page ever 5 seconds */

var timeout = setInterval(function() {
    // If there is the button with id 'toggle-refresh' and auto refresh is on reload the page
    if (document.getElementById("toggle-refresh") != undefined && 
        document.getElementById("toggle-refresh").innerHTML == "Auto Refresh: ON") {

        location.reload();
    }
    
    return false;
}, 5000);