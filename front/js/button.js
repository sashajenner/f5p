// Define default values for buttons and form options
var default_format = "--zebra";
var default_monitor_dir = "/mnt/simulator_out";
var default_script = "fast5_pipeline.sh";
var default_upload_script = "-- not selected --";
var default_keep_new_script = "no";
var default_timeout_time_format = "Hours";
var default_timeout_time_value = "";
var default_sim = "off";
var default_real_sim = "off";
var default_sim_dir = "/mnt/zebrafish/zebrafish_test";
var default_time_between_reads = "";
var default_no_reads = "";
var default_non_realtime = "off";
var default_resuming = "off";

// Function that resets elements to their default
reset_default = function() {

    const select_format = document.getElementById("format");
    for (var i = 0; i < select_format.options.length; i ++) { // Iterate through format options
        if (select_format.options[i].text == default_format) {
            select_format.selectedIndex = i; // Select the default format
        }
    }

    const select_dir = document.getElementById("dir");
    for (var i = 0; i < select_dir.options.length; i ++) {
        if (select_dir.options[i].text == default_monitor_dir) {
            select_dir.selectedIndex = i;
        }
    }

    const select_script_exist = document.getElementById("script-exist");
    for (var i = 0; i < select_script_exist.options.length; i ++) {
        if (select_script_exist.options[i].text == default_script) {
            select_script_exist.selectedIndex = i;
        }
    }

    const select_script_upload = document.getElementById("script-upload");
    for (var i = 0; i < select_script_upload.options.length; i ++) {
        if (select_script_upload.options[i].text == default_upload_script) {
            select_script_upload.selectedIndex = i;
        }
    }

    if (default_upload_script == "-- not selected --") {
        document.getElementById("script-new_label").classList.add("grey"); // Visual effects
        document.getElementById("script-exist_label").classList.remove("grey");
    } else {
        document.getElementById("script-new_label").classList.remove("grey");
        document.getElementById("script-exist_label").classList.add("grey");
    }

    if (default_keep_new_script == "no") {
        const upload_new_script = document.getElementById("script-new");
        upload_new_script.value = upload_new_script.defaultValue;
    }

    const select_timeout_format = document.getElementById("timeout-format");
    for (var i = 0; i < select_timeout_format.options.length; i ++) {
        if (select_timeout_format.options[i].text == default_timeout_time_format) {
            select_timeout_format.selectedIndex = i;
        }
    }

    const value_timeout_time = document.getElementById("timeout-time");
    if (default_timeout_time_format == "Hours") {
        value_timeout_time.disabled = false;
    }
    value_timeout_time.value = default_timeout_time_value;

    const real_sim_checkbox = document.getElementById("sim-real");
    const real_sim_checkbox_label = document.getElementById("sim-real_label");
    if (default_real_sim == "on") {
        real_sim_checkbox.checked = "checked";
    } else if (default_real_sim == "off") {
        real_sim_checkbox.checked = false;
    }

    const select_sim_dir = document.getElementById("sim-dir");
    const select_sim_dir_label = document.getElementById("sim-dir_label");
    for (var i = 0; i < select_sim_dir.options.length; i ++) {
        if (select_sim_dir.options[i].text == default_sim_dir) {
            select_sim_dir.selectedIndex = i;
        }
    }

    const value_time_between_reads = document.getElementById("sim-time");
    value_time_between_reads.value = default_time_between_reads;
    const value_time_between_reads_label = document.getElementById("sim-time_label");

    const value_no_reads = document.getElementById("sim-read_num");
    value_no_reads.value = default_no_reads;
    const value_no_reads_label = document.getElementById("sim-read_num_label");

    const sim_checkbox = document.getElementById("sim");
    if (default_sim == "on") {
        sim_checkbox.checked = "checked";
        
        if (real_sim_checkbox.checked) {
            value_time_between_reads.disabled = "disabled";
            value_time_between_reads_label.classList.add("grey");
        } else {
            value_time_between_reads.disabled = false;
            value_time_between_reads_label.classList.remove("grey");
        }

        if (value_time_between_reads.value != "") {
            real_sim_checkbox.disabled = "disabled";
            real_sim_checkbox_label.classList.add("grey");
        } else {
            real_sim_checkbox.disabled = false;
            real_sim_checkbox_label.classList.remove("grey");
        }

        value_no_reads.disabled = false;
        value_no_reads_label.classList.remove("grey");
        select_sim_dir.disabled = false;
        select_sim_dir_label.classList.remove("grey");

    } else if (default_sim == "off") {
        sim_checkbox.checked = false;

        real_sim_checkbox.disabled = "disabled";
        real_sim_checkbox_label.classList.add("grey");
        value_time_between_reads.disabled = "disabled";
        value_time_between_reads_label.classList.add("grey");
        value_no_reads.disabled = "disabled";
        value_no_reads_label.classList.add("grey");
        select_sim_dir.disabled = "disabled";
        select_sim_dir_label.classList.add("grey");
    }

    resuming_checkbox = document.getElementById("resume");
    resuming_checkbox_label = document.getElementById("resume_label");

    non_realtime_checkbox = document.getElementById("non-real-time");
    non_realtime_checkbox_label = document.getElementById("non-real-time_label");

    if (default_non_realtime == "on") {
        non_realtime_checkbox.checked = "checked";
        non_realtime_checkbox.disabled = false;
        non_realtime_checkbox_label.classList.remove("grey");

        resuming_checkbox.disabled = true;
        resuming_checkbox_label.classList.add("grey");
    } else {
        non_realtime_checkbox.checked = false;
        non_realtime_checkbox.disabled = false;
        non_realtime_checkbox_label.classList.remove("grey");
    }

    if (default_non_realtime == "on") {
        resuming_checkbox.checked = "checked";
        resuming_checkbox.disabled = false;
        resuming_checkbox_label.classList.remove("grey");

        non_realtime_checkbox.disabled = true;
        non_realtime_checkbox_label.classList.add("grey");
    } else {
        resuming_checkbox.checked = false;
        resuming_checkbox.disabled = false;
        resuming_checkbox_label.classList.remove("grey");
    }
}


$(document).ready(function() {
    $('.button').click(function() { // On click of an element with 'button' class

        if ($(this).val() == "reset to default options") { // Reset defaults
            reset_default();

        } else if ($(this).html() == "i"|| $(this).html() == "?") { // For info buttons
            var id = $(this).attr("id");

            // Get the modal
            var modal = document.getElementById("modal-" + id);

            // Get the button that opens the modal
            var btn = this;

            // Get the <span> element that closes the modal
            var span = document.getElementsByClassName("modal-close-" + id)[0];

            modal.style.display = "block";

            // When the user clicks on <span> (x), close the modal
            span.onclick = function() {
                modal.style.display = "none";
            }

            // When the user clicks anywhere outside of the modal, close it
            window.onclick = function(event) {
                if (event.target == modal) {
                    modal.style.display = "none";
                }
            }

        } else if ($(this).attr("id") == "toggle-refresh") { // For toggle refresh button

            var js_refresh = document.getElementById("js-refresh");

            // Change appearance and class on click
            if (!$(this).hasClass("toggle-green")) {
                this.classList.add("toggle-green");
                this.innerHTML = "Auto Refresh: ON";
                
            } else {
                this.classList.remove("toggle-green");
                this.innerHTML = "Auto Refresh: OFF";
            }
        }
    });
});