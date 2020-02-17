var timeout = setInterval(function() {
    if (document.getElementById("toggle-refresh") != undefined && 
        document.getElementById("toggle-refresh").innerHTML == "Auto Refresh: ON") {

        location.reload();
    }

    return false;
}, 5000);