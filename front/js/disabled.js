const sim_checkbox = document.getElementById("sim");
const pipeline_script_upload = document.getElementById("script-new");
var real_checkbox = document.getElementById("sim-real");
var sim_dir = document.getElementById("sim-dir");
var time_between_reads = document.getElementById("sim-time");
var num_reads = document.getElementById("sim-read_num");
const timeout_format = document.getElementById("timeout-format");
var timeout_time = document.getElementById("timeout-time");
var prev_script_upload = document.getElementById("script-upload");
var pipeline_script_existing = document.getElementById("script-exist");
var non_realtime_checkbox = document.getElementById("non-real-time");
var monior_dir = document.getElementById("dir");
var resuming_checkbox = document.getElementById("resume");

var real_checkbox_label = document.getElementById("sim-real_label");
var sim_dir_label = document.getElementById("sim-dir_label");
var time_between_reads_label = document.getElementById("sim-time_label");
var sim_checkbox_label = document.getElementById("sim_label");
var num_reads_label = document.getElementById("sim-read_num_label");
var timeout_label = document.getElementById("timeout_label");
var monior_dir_label = document.getElementById("dir_label");
var non_realtime_checkbox_label = document.getElementById("non-real-time_label")
var resuming_checkbox_label = document.getElementById("resume_label");

function react_checkbox_change(event) {

    var real_checkbox = document.getElementById("sim-real");
    var time_input = document.getElementById("sim-time");
    var read_input = document.getElementById("sim-read_num");
    var sim_dir = document.getElementById("sim-dir");

    var real_checkbox_label = document.getElementById("sim-real_label");
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

    var real_checkbox_label = document.getElementById("sim-real_label");
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
        read_input_label.classList.remove("grey");
        sim_dir.disabled = false;
        sim_dir_label.classList.remove("grey");
    }
}

function react_script(event) {

    var pipeline_script_existing = document.getElementById("script-exist");
    var pipeline_script_existing_label = document.getElementById("script-exist_label");

    if (pipeline_script_upload.value.length != "") {

        for (var i = 0; i < pipeline_script_existing.options.length; i ++) {
            if (pipeline_script_existing.options[i].value == "unselected") {
                pipeline_script_existing.selectedIndex = i;
            }
        }

        for (var j = 0; j < prev_script_upload.options.length; j ++) {
            if (prev_script_upload.options[j].value == "unselected") {
                prev_script_upload.selectedIndex = j;
            }
        }

        pipeline_script_existing_label.classList.add("grey");
        document.getElementById("script-new_label").classList.remove("grey");
    } else {
        pipeline_script_existing.disabled = false;
        pipeline_script_existing_label.classList.remove("grey");
    }
}

function react_realistic_change(event) {
    if (event.target.checked) {
        time_between_reads.value = "";
        time_between_reads.disabled = "disabled";
        time_between_reads_label.classList.add("grey");
    } else {
        time_between_reads.disabled = false;
        time_between_reads_label.classList.remove("grey");
    }
}

function react_realistic_load(event) {
    if (real_checkbox.checked) {
        time_between_reads.value = "";
        time_between_reads.disabled = "disabled";
        time_between_reads_label.classList.add("grey");
    } else {
        time_between_reads.disabled = false;
        time_between_reads_label.classList.remove("grey");
    }
}

function react_time_reads(event) {
    if (time_between_reads.value != "") {
        real_checkbox.checked = false;
        real_checkbox.disabled = "disabled";
        real_checkbox_label.classList.add("grey");
    } else {
        real_checkbox.disabled = false;
        real_checkbox_label.classList.remove("grey");
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

function react_upload_script(event) {

    if (prev_script_upload[prev_script_upload.selectedIndex].value != "unselected") {
        
        document.getElementById("script-exist_label").classList.add("grey");
        document.getElementById("script-new_label").classList.remove("grey");
        
        var upload_new_script = document.getElementById("script-new");
        
        upload_new_script.disabled = false;
        upload_new_script.value = upload_new_script.defaultValue;

        for (var i = 0; i < pipeline_script_existing.options.length; i ++) {
            if (pipeline_script_existing.options[i].text == "-- not selected --") {
                pipeline_script_existing.selectedIndex = i;
            }
        }

    }
}

function react_existing_script(event) {

    if (pipeline_script_existing[pipeline_script_existing.selectedIndex].value != "unselected") {

        var pipeline_script_upload = document.getElementById("script-new");
        var pipeline_script_upload_label = document.getElementById("script-new_label");

        pipeline_script_upload.value = pipeline_script_upload.defaultValue;
        pipeline_script_upload_label.classList.add("grey");

        document.getElementById("script-exist_label").classList.remove("grey");

        for (var i = 0; i < prev_script_upload.options.length; i ++) {
            if (prev_script_upload.options[i].text == "-- not selected --") {
                prev_script_upload.selectedIndex = i;
            }
        }
    }
}

function react_non_realtime_checkbox(event) {
    if (non_realtime_checkbox.checked) {
        sim_checkbox.disabled = "disabled";
        sim_checkbox_label.classList.add("grey");

        real_checkbox.disabled = "disabled";
        real_checkbox_label.classList.add("grey");

        sim_dir.disabled = "disabled";
        sim_dir_label.classList.add("grey");

        time_between_reads.disabled = "disabled";
        time_between_reads_label.classList.add("grey");

        num_reads.disabled = "disabled";
        num_reads_label.classList.add("grey");


        timeout_format.disabled = "disabled";
        timeout_time.disabled = "disabled";
        timeout_label.classList.add("grey");

        monior_dir.disabled = "disabled";
        monior_dir_label.classList.add("grey");

        resuming_checkbox.disabled = "disabled";
        resuming_checkbox_label.classList.add("grey");
        
    } else {
        sim_checkbox.disabled = false;
        sim_checkbox_label.classList.remove("grey");

        if (sim_checkbox.checked) {
            real_checkbox.disabled = false;
            real_checkbox_label.classList.remove("grey");

            if (real_checkbox.checked) {
                time_between_reads.disabled = "disabled";
                time_between_reads_label.classList.add("grey");
            } else {
                time_between_reads.disabled = false;
                time_between_reads_label.classList.remove("grey");
            }

            if (time_between_reads.value != "") {
                real_checkbox.disabled = "disabled";
                real_checkbox_label.classList.add("grey");
            }

            sim_dir.disabled = false;
            sim_dir_label.classList.remove("grey");

            num_reads.disabled = false;
            num_reads_label.classList.remove("grey");
        }


        timeout_format.disabled = false;

        if (timeout_format[timeout_format.selectedIndex].value != "Automatic") {
            timeout_time.disabled = false;
        }

        timeout_label.classList.remove("grey");

        monior_dir.disabled = false;
        monior_dir_label.classList.remove("grey");

        resuming_checkbox.disabled = false;
        resuming_checkbox_label.classList.remove("grey");      
    }
}

function react_resuming_checkbox(event) {
    if (resuming_checkbox.checked) {
        sim_checkbox.disabled = "disabled";
        sim_checkbox_label.classList.add("grey");

        real_checkbox.disabled = "disabled";
        real_checkbox_label.classList.add("grey");

        sim_dir.disabled = "disabled";
        sim_dir_label.classList.add("grey");

        time_between_reads.disabled = "disabled";
        time_between_reads_label.classList.add("grey");

        num_reads.disabled = "disabled";
        num_reads_label.classList.add("grey");

        non_realtime_checkbox.disabled = "disabled";
        non_realtime_checkbox_label.classList.add("grey");
    } else {
        sim_checkbox.disabled = false;
        sim_checkbox_label.classList.remove("grey");

        if (sim_checkbox.checked) {
            real_checkbox.disabled = false;
            real_checkbox_label.classList.remove("grey");

            if (real_checkbox.checked) {
                time_between_reads.disabled = "disabled";
                time_between_reads_label.classList.add("grey");
            } else {
                time_between_reads.disabled = false;
                time_between_reads_label.classList.remove("grey");
            }

            if (time_between_reads.value != "") {
                real_checkbox.disabled = "disabled";
                real_checkbox_label.classList.add("grey");
            }

            sim_dir.disabled = false;
            sim_dir_label.classList.remove("grey");

            num_reads.disabled = false;
            num_reads_label.classList.remove("grey");
        }

        non_realtime_checkbox.disabled = false
        non_realtime_checkbox_label.classList.remove("grey");
    }
}


window.addEventListener("load", react_script);
window.addEventListener("load", react_timeout_format);
window.addEventListener("load", react_realistic_load);
window.addEventListener("load", react_checkbox_load);
window.addEventListener("load", react_upload_script);
window.addEventListener("load", react_existing_script);
window.addEventListener("load", react_non_realtime_checkbox);
window.addEventListener("load", react_resuming_checkbox);

sim_checkbox.addEventListener("change", react_checkbox_change);
pipeline_script_upload.addEventListener("change", react_script);
time_between_reads.addEventListener("change", react_time_reads);
real_checkbox.addEventListener("change", react_realistic_change);
timeout_format.addEventListener("change", react_timeout_format);
prev_script_upload.addEventListener("change", react_upload_script);
pipeline_script_existing.addEventListener("change", react_existing_script);
non_realtime_checkbox.addEventListener("change", react_non_realtime_checkbox);
resuming_checkbox.addEventListener("change", react_resuming_checkbox);
