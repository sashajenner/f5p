const sim_checkbox = document.getElementById("sim");
const pipeline_script_upload = document.getElementById("script-new");
var real_checkbox = document.getElementById("sim-real");
var time_between_reads = document.getElementById("sim-time");
const timeout_format = document.getElementById("timeout-format");

function react_checkbox_change(event) {

    var real_checkbox = document.getElementById("sim-real");
    var time_input = document.getElementById("sim-time");
    var read_input = document.getElementById("sim-read_num");
    var sim_dir = document.getElementById("sim-dir");

    var real_checkbox_label = document.getElementById("sim-real_labell");
    var time_input_label = document.getElementById("sim-time_label");
    var read_input_label = document.getElementById("sim-read_num_label");
    var sim_dir_label = document.getElementById("sim-dir_label");

    if (!event.target.checked) {
        real_checkbox.disabled = "disabled";
        real_checkbox_label.classList.add("grey");
        time_input.disabled = "disabled";
        time_input_label.classList.add("grey");
        read_input.disabled = "disabled";
        read_input_label.classList.add("grey");
        sim_dir.disabled = "disabled";
        sim_dir_label.classList.add("grey");
        
    } else {
        if (real_checkbox.checked) {
            time_input.disabled = "disabled";
            time_input_label.classList.add("grey");
        } else {
            time_input.disabled = false;
            time_input_label.classList.remove("grey");
        }

        if (time_input.value != "") {
            real_checkbox.disabled = "disabled";
            real_checkbox_label.classList.add("grey");
        } else {
            real_checkbox.disabled = false;
            real_checkbox_label.classList.remove("grey");
        }

        read_input.disabled = false;
        read_input_label.classList.remove("grey");
        sim_dir.disabled = false;
        sim_dir_label.classList.remove("grey");
    }
}

function react_checkbox_load(event) {

    var real_checkbox = document.getElementById("sim-real");
    var time_input = document.getElementById("sim-time");
    var read_input = document.getElementById("sim-read_num");
    var sim_dir = document.getElementById("sim-dir");

    var real_checkbox_label = document.getElementById("sim-real_labell");
    var time_input_label = document.getElementById("sim-time_label");
    var read_input_label = document.getElementById("sim-read_num_label");
    var sim_dir_label = document.getElementById("sim-dir_label");

    if (!sim_checkbox.checked) {
        real_checkbox.disabled = "disabled";
        real_checkbox_label.classList.add("grey");
        time_input.disabled = "disabled";
        time_input_label.classList.add("grey");
        read_input.disabled = "disabled";
        read_input_label.classList.add("grey");
        sim_dir.disabled = "disabled";
        sim_dir_label.classList.add("grey");

    } else {

        if (real_checkbox.checked) {
            time_input.disabled = "disabled";
            time_input_label.classList.add("grey");
        } else {
            time_input.disabled = false;
            time_input_label.classList.remove("grey");
        }

        if (time_input.value != "") {
            real_checkbox.disabled = "disabled";
            real_checkbox_label.classList.add("grey");
        } else {
            real_checkbox.disabled = false;
            real_checkbox_label.classList.remove("grey");
        }

        read_input.disabled = false;
        read_input_label.classList.remve("grey");
        sim_dir.disabled = false;
        sim_dir_label.classList.remove("grey");
    }
}

function react_script(event) {

    var pipeline_script_existing = document.getElementById("script-exist");
    var pipeline_script_existing_label = document.getElementById("script-exist_label");

    if (pipeline_script_upload.value.length != "") {
        pipeline_script_existing.disabled = "disabled";
        pipeline_script_existing_label.classList
    } else {
        pipeline_script_existing.disabled = false;
    }
}

function react_realistic_change(event) {
    if (event.target.checked) {
        time_between_reads.value = "";
        time_between_reads.disabled = "disabled";
    } else {
        time_between_reads.disabled = false;
    }
}

function react_realistic_load(event) {
    if (real_checkbox.checked) {
        time_between_reads.value = "";
        time_between_reads.disabled = "disabled";
    } else {
        time_between_reads.disabled = false;
    }
}

function react_time_reads(event) {
    if (time_between_reads.value != "") {
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

window.addEventListener("load", react_checkbox_load);
window.addEventListener("load", react_script);
window.addEventListener("load", react_timeout_format);
real_checkbox.addEventListener("load", react_realistic_load);

sim_checkbox.addEventListener("change", react_checkbox_change);
pipeline_script_upload.addEventListener("change", react_script);
time_between_reads.addEventListener("change", react_time_reads);
real_checkbox.addEventListener("change", react_realistic_change);
timeout_format.addEventListener("change", react_timeout_format);