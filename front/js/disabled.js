const sim_checkbox = document.getElementById("sim");
const pipeline_script_upload = document.getElementById("script-new");
var real_checkbox = document.getElementById("sim-real");
var time_between_batches = document.getElementById("sim-time");
const timeout_format = document.getElementById("timeout-format");

function react_checkbox(event) {

    var real_checkbox = document.getElementById("sim-real");
    var time_input = document.getElementById("sim-time");
    var batch_input = document.getElementById("sim-batch_num");
    var sim_dir = document.getElementById("sim-dir");

    if (!event.target.checked) {
        real_checkbox.disabled = "disabled";
        time_input.disabled = "disabled";
        batch_input.disabled = "disabled";
        sim_dir.disabled = "disabled";
    } else {
        real_checkbox.disabled = false;
        time_input.disabled = false;
        batch_input.disabled = false;
        sim_dir.disabled = false;
    }
}

function react_script(event) {

    var pipeline_script_existing = document.getElementById("script-exist");

    if (pipeline_script_upload.value.length != "") {
        pipeline_script_existing.disabled = "disabled";
    } else {
        pipeline_script_existing.disabled = false;
    }
}

function react_realistic(event) {
    if (event.target.checked) {
        time_between_batches.value = "";
        time_between_batches.disabled = "disabled";
    } else {
        time_between_batches.disabled = false;
    }
}

function react_time_batches(event) {
    if (time_between_batches.value != "") {
        real_checkbox.checked = false;
        real_checkbox.disabled = "disabled";
    } else {
        real_checkbox.disabled = false;
    }
}

function react_timeout_format(event) {

    var timeout_time = document.getElementById("timeout-time");

    if (timeout_format.options[timeout_format.selectedIndex].text == "Automatic") {
        timeout_time.value = "";
        timeout_time.disabled = "disabled";
    } else {
        timeout_time.disabled = false;
    }
}

window.addEventListener("load", react_checkbox);
window.addEventListener("load", react_script);
window.addEventListener("load", react_timeout_format);

sim_checkbox.addEventListener("change", react_checkbox);
pipeline_script_upload.addEventListener("change", react_script);
time_between_batches.addEventListener("change", react_time_batches);
real_checkbox.addEventListener("change", react_realistic);
timeout_format.addEventListener("change", react_timeout_format);