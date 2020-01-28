var default_format = "--zebra";
var default_monitor_dir = "/mnt/NA12878_cq/";
var default_script = "fast5_pipeline.sh";
var default_timeout_time = "Hours";

$(document).ready(function() {
    $('.button').click(function() {

        if ($(this).val() == "reset to default options") {
            const select_format = document.getElementById("format");
            for (var i = 0; i < select_format.options.length; i ++) {
                if (select_format.options[i].text == default_format) {
                    select_format.selectedIndex = i;
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

            const select_timeout_format = document.getElementById("timeout-format");
            for (var i = 0; i < select_timeout_format.options.length; i ++) {
                if (select_timeout_format.options[i].text == default_timeout_time) {
                    select_timeout_format.selectedIndex = i;
                }
            }
        }

        // var oReq = new XMLHttpRequest(); // New request object
        // oReq.onload = function() {
        //     alert(this.responseText); // testing
        //     // if (this.responseText == 0) {
        //     //     alert("success: analyse began");
        //     // }
        // };
        // oReq.open("get", "analyse.php", true);
        // oReq.send();


    });
});