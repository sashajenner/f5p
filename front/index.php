<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis - Home</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?07-02-2020:10 42" />
        <link rel="icon" type="image/png" href="favicon.png?05-02-2020:11 53" sizes="32x32"/>
    </head>

    <body>

        <?php session_start(); ?>

        <div class="outer-page-container">

            <div class="center">

                <div class="container">
                    <fieldset class="invisible">
                        <!-- <form id="logs_button" action="manage_jobs.php" method="POST">
                            <input type="submit" class="button" id="logs" name="logs" value="view jobs" />
                        </form> -->

                        <input type="submit" class="button" id="reset" name="reset" value="reset to default options" />
                    </fieldset>
                    
                    <form id="analysis_form" method="POST" enctype="multipart/form-data">        
                        <fieldset>
                            <label for="format" style="font-weight: bold;">Format</label>
                            <button type='button' class="button info" id="info-format">i</button>

                            <div id="modal-info-format" class="modal">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <span class="close modal-close-info-format">&times;</span>
                                        <h2>Format - Information</h2>
                                    </div>
                                    <div class="modal-body modal-body-info-format">
                                        <p>
            Specify folder & file format of the sequencer's output:<br><br>
            &emsp;--zebra&emsp;[directory]&emsp;&emsp;(Newest format)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;|-- fast5/<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;|-- [prefix].fast5<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;|-- fastq/<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;|-- [prefix].fastq<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;|-- sequencing_summary.txt<br>
            <br>
            &emsp;--NA&emsp;[directory]&emsp;&emsp;(Newer format with terrible folders)<br>
            &emsp;&emsp;&emsp;&emsp;&nbsp;|-- fast5/<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;|-- [prefix].fast5<br>
            &emsp;&emsp;&emsp;&emsp;&nbsp;|-- fastq/<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;|-- [prefix]/<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;&nbsp;|-- [prefix].fastq<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;&nbsp;|-- sequencing_summary.txt (optional -<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;for realistic testing or automatic timeout)<br>
            <br>
            &emsp;--778&emsp;[directory]&emsp;&emsp;(Old format that's not too bad)<br>
            &emsp;&emsp;&emsp;&emsp;&nbsp;|-- fast5/<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;|-- [prefix].fast5.tar<br>
            &emsp;&emsp;&emsp;&emsp;&nbsp;|-- fastq/<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;|-- fastq_*.[prefix].fastq.gz<br>
            &emsp;&emsp;&emsp;&emsp;&nbsp;|-- logs/ (optional - for realistic testing<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;or automatic timeout)<br>
            &emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;|-- sequencing_summary.[prefix].txt.gz<br>
                                        
                                        </p>
                                    </div>
                                </div>      
                            </div>

                            <br>
                            <select name="format" id="format" required>
                                <?php
                                    $formats = explode("\n", shell_exec("bash ../run.sh --avail"));
                                    if (empty($formats[count($formats)-1])) { // remove last element if empty
                                        unset($formats[count($formats)-1]);
                                    }

                                    foreach ($formats as $format) {

                                        if ($format == $_POST['format']) {
                                            $selected = " selected='selected'";
                                        } else {
                                            $selected = "";
                                        }

                                        echo "<option value='$format'$selected>$format</option>";
                                    }
                                ?>
                            </select>
                            <br><br>

                            <label for="dir" style="font-weight: bold;">Monitor Directory</label>
                            <button type='button' class="button info" id="info-monitor-dir">i</button>

                            <div id="modal-info-monitor-dir" class="modal">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <span class="close modal-close-info-monitor-dir">&times;</span>
                                        <h2>Monitor Directory - Information</h2>
                                    </div>
                                    <div class="modal-body">
                                        <p>The directory to be monitored for the sequencer's output.</p>
                                    </div>
                                </div>      
                            </div>
                            <br>
                            <select name="dir" id="dir" required>
                                <?php
                                    $cmd = 'find /mnt/ -maxdepth 3 -type d | grep -v "/fast5\|/fastq\|/log2\|/logs\|/sam\|/methylation\|/bam"';
                                    $mnt_dirs_str = shell_exec($cmd);
                                    $mnt_dirs_arr = explode("\n", $mnt_dirs_str);
                                    if (empty($mnt_dirs_arr[count($mnt_dirs_arr)-1])) { // remove last element if empty
                                        unset($mnt_dirs_arr[count($mnt_dirs_arr)-1]);
                                    }

                                    foreach ($mnt_dirs_arr as $dir) {

                                        if ($dir == $_POST['dir']) {
                                            $selected = " selected='selected'";
                                        } else {
                                            $selected = "";
                                        }

                                        echo "<option value='$dir'$selected>$dir</option>";
                                    }
                                ?>
                            </select>
                        </fieldset>
                        <br>

                        <fieldset>
                            <strong>Analysis Script</strong>
                            <button type='button' class="button info" id="info-analysis-script">i</button>

                            <div id="modal-info-analysis-script" class="modal">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <span class="close modal-close-info-analysis-script">&times;</span>
                                        <h2>Analysis Script - Information</h2>
                                    </div>
                                    <div class="modal-body">
                                        <p>The script used to analyse each sequenced read.</p>
                                    </div>
                                </div>      
                            </div>
                            <br>
                            
                            <label for="script-exist" id="script-exist_label">1) Existing pipelines</label>
                            <select name="existing_script" id="script-exist">
                                <?php
                                    $scripts_arr = explode("\n", shell_exec("ls -p ../scripts | grep -v / | grep fast5_pipeline"));
                                    if (empty($scripts_arr[count($scripts_arr)-1])) { // remove last element if empty
                                        unset($scripts_arr[count($scripts_arr)-1]);
                                    }
                                    
                                    $first = TRUE;
                                    foreach ($scripts_arr as $script) {

                                        if ($first) {
                                            echo "<option hidden disabled selected value='unselected'>-- not selected --</option>";
                                            $first = FALSE;
                                        }

                                        if ($script == $_POST['existing_script']) {
                                            $selected = " selected='selected'";
                                        } else {
                                            $selected = "";
                                        }

                                        echo "<option value='$script'$selected>$script</option>";
                                    }
                                ?>
                            </select>
                            <br>
                            <label for="script-new" id="script-new_label">2) Your own pipeline</label>
                            <select name="uploaded_script" class="hidden" id="script-upload">
                            <?php
                                $php_id = $_COOKIE['PHPSESSID'];

                                if (shell_exec("ls uploads/$php_id") != "") {
                                    echo "<script>document.getElementById('script-upload').classList.remove('hidden')</script>";
                                    
                                    $uploaded_scripts_arr = explode("\n", shell_exec("ls -p uploads/$php_id"));
                                    if (empty($uploaded_scripts_arr[count($uploaded_scripts_arr)-1])) { // remove last element if empty
                                        unset($uploaded_scripts_arr[count($uploaded_scripts_arr)-1]);
                                    }

                                    $first = TRUE;
                                    foreach ($uploaded_scripts_arr as $script) {

                                        if ($first) {
                                            echo "<option hidden disabled selected value='unselected'>-- not selected --</option>";
                                            $first = FALSE;
                                        }

                                        if ($script == $_POST['uploaded_script']) {
                                            $selected = " selected='selected'";
                                        } else {
                                            $selected = "";
                                        }

                                        echo "<option value='$script'$selected>$script</option>";
                                    }
                                    echo '</select>';

                                }
                            ?>
                            <input type="file" name="new_script" id="script-new" accept=".sh" />
                            <br><br>

                            <label for="timeout" style="font-weight: bold;">Timeout</label>
                            <button type='button' class="button info" id="info-timeout">i</button>

                            <div id="modal-info-timeout" class="modal">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <span class="close modal-close-info-timeout">&times;</span>
                                        <h2>Timeout - Information</h2>
                                    </div>
                                    <div class="modal-body">
                                        <p>The time period after no new files have been received to then quit analysis.</p>
                                    </div>
                                </div>      
                            </div>
                            <br>
                            <select name="timeout_format" id="timeout-format">
                                <?php
                                    $time_formats = array("Seconds", "Minutes", "Hours", "Automatic");
                                    foreach ($time_formats as $time) {

                                        if ($time == $_POST['timeout_format'] ||
                                            ( !isset($_POST['timeout_format']) &&
                                            $time == "Hours")
                                            ) {
                                            $selected = " selected='selected'";
                                        } else {
                                            $selected = "";
                                        }

                                        echo "<option value='$time'$selected>$time</option>";                         
                                    }
                                ?>
                            </select>
                            <?php
                                if (isset($_POST['timeout_time']) && $_POST['timeout_time'] != "") {
                                    $placeholder = $_POST['timeout_time'];
                                } else {
                                    $placeholder = 1;
                                }
                                        
                                echo "<input type='number' name='timeout_time' id='timeout-time' min='0' placeholder='$placeholder' />";
                            ?>
                        </fieldset>
                        <br>

                        <fieldset>
                            <label for="sim" style="font-weight: bold;">Simulate</label>
                                <?php
                                    if ($_POST["simulation"] == "on") {
                                        $checked = "checked='checked' ";
                                    } else {
                                        $checked = "";
                                    }
                                    echo "<input type='checkbox' name='simulation' id='sim' $checked/>";
                                ?>
                                <button type='button' class="button info" id="info-sim">i</button>

                                <div id="modal-info-sim" class="modal">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <span class="close modal-close-info-sim">&times;</span>
                                            <h2>Simulation - Information</h2>
                                        </div>
                                        <div class="modal-body">
                                            <p>Simulate a historical sequencing run for testing purposes.</p>
                                        </div>
                                    </div>      
                                </div>
                            <br>
                            <label for="sim-real" id="sim-real_label">Realistic</label>
                                <?php
                                    if ($_POST["real_simulation"] == "on") {
                                        $checked = "checked='checked' ";
                                    } else {
                                        $checked = "";
                                    }
                                    echo "<input type='checkbox' name='real simulation' id='sim-real' $checked/>";
                                ?>
                                <button type='button' class="button info" id="info-sim-real">i</button>

                                <div id="modal-info-sim-real" class="modal">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <span class="close modal-close-info-sim-real">&times;</span>
                                            <h2>Realistic Simulation - Information</h2>
                                        </div>
                                        <div class="modal-body">
                                            <p>Simulate a historical sequencing run realistically given sequencing summary files.</p>
                                        </div>
                                    </div>      
                                </div>
                            <br>
                            <label for="sim-dir" id="sim-dir_label">Simulate Directory</label>
                            <select name="simulate dir" id="sim-dir">
                                <?php
                                    $cmd = 'find /mnt/ -maxdepth 3 -type d | grep -v "/fast5\|/fastq\|/log2\|/logs\|/sam\|/methylation\|/bam"';
                                    $mnt_dirs_str = shell_exec($cmd);
                                    $mnt_dirs_arr = explode("\n", $mnt_dirs_str);
                                    if (empty($mnt_dirs_arr[count($mnt_dirs_arr)-1])) { // remove last element if empty
                                        unset($mnt_dirs_arr[count($mnt_dirs_arr)-1]);
                                    }

                                    foreach ($mnt_dirs_arr as $dir) {

                                        if ($dir == $_POST['simulate_dir']) {
                                            $selected = " selected='selected'";
                                        } else {
                                            $selected = "";
                                        }

                                        echo "<option value='$dir'$selected>$dir</option>";
                                    }
                                ?>
                            </select>
                            <button type='button' class="button info" id="info-sim-dir">i</button>

                                <div id="modal-info-sim-dir" class="modal">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <span class="close modal-close-info-sim-dir">&times;</span>
                                            <h2>Simulation Directory - Information</h2>
                                        </div>
                                        <div class="modal-body">
                                            <p>The directory from which the historical sequencing run is held.</p>
                                        </div>
                                    </div>      
                                </div>
                            <br>
                            <label for="sim-time" id="sim-time_label">Time between reads</label>
                            <?php
                                if ($_POST["time_between_reads"] != "") {
                                    $time = $_POST["time_between_reads"];
                                    $value = "value='$time' ";
                                } else {
                                    $value = "";
                                }
                                echo "<input type='text' name='time between reads' id='sim-time' placeholder='0' $value/>";
                            ?>
                            <button type='button' class="button info" id="info-sim-time">i</button>

                            <div id="modal-info-sim-time" class="modal">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <span class="close modal-close-info-sim-time">&times;</span>
                                        <h2>Simulation Time Between Reads - Information</h2>
                                    </div>
                                    <div class="modal-body">
                                        <p>
                                            Simulate a consistent time delay between reads.<br>
                                            Default is seconds. Use letters with time for specificity.<br><br>
                                            E.g. For 30 seconds: enter "30s" or "30"<br>
                                            For 1 hour: enter "1h"<br><br>
                                            Cannot be concurrently set with realistic simulation option.
                                        </p>
                                    </div>
                                </div>      
                            </div>
                            <br>
                            <label for="sim-read_num" id="sim-read_num_label">Number of reads</label>
                            <?php
                                if ($_POST["number_of_reads"] != "") {
                                    $prev_no_reads = $_POST["number_of_reads"];
                                    $value = "value='$prev_no_reads' ";
                                } else {
                                    $value = "";
                                }
                                echo "<input type='number' name='number of reads' id='sim-read_num' placeholder='all' min='0' $value/>";
                            ?>
                            <button type='button' class="button info" id="info-sim-read-num">i</button>

                            <div id="modal-info-sim-read-num" class="modal">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <span class="close modal-close-info-sim-read-num">&times;</span>
                                        <h2>Simulation Number of Reads - Information</h2>
                                    </div>
                                    <div class="modal-body">
                                        <p>The number of reads to simulate. Leave empty to simulate all reads.</p>
                                    </div>
                                </div>      
                            </div>
                        </fieldset>

                        <fieldset class="invisible">
                            <input type="submit" class="button" id="start" name="execute" value="start realtime analysis" />
                            <input type="submit" class="button" id="kill" name="halt" value="kill all jobs" />
                        </fieldset>
                    </form>
                </div>

            </div>

            <div class="right">

                <p><br>

                    <?php
                    
                    // Upload file
                    
                    $php_id = $_COOKIE['PHPSESSID'];

                    if ($_FILES["new_script"]["name"] != "") {
                        $target_dir = __DIR__ . "/uploads/$php_id/";
                        $target_file = $target_dir . basename($_FILES["new_script"]["name"]);
                        $__FILE_UPLOAD_STATUS__ = 0;
                        $fileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

                        // Check if file already exists
                        if (file_exists($target_file)) {
                            //echo "File already exists";
                            $__FILE_UPLOAD_STATUS__ = -1;
                        }

                        // Check file size
                        if ($_FILES["new_script"]["size"] > 500000) { // too large
                            //echo "File to large";
                            $__FILE_UPLOAD_STATUS__ = 1;
                        }

                        // Allow certain file formats
                        if ($fileType != "sh" ) {
                            $__FILE_UPLOAD_STATUS__ = 2;
                        }

                        // Check if $uploadOk is set to 0 by an error
                        if ($__FILE_UPLOAD_STATUS__ == 0) {

                            system("mkdir -p $target_dir");

                            if (move_uploaded_file($_FILES["new_script"]["tmp_name"], $target_file)) {
                                //echo "<br>Successful upload!";
                                
                            } else {
                                //echo "<br>Sorry, there was an error uploading your file.";
                                $__FILE_UPLOAD_STATUS__ = 3;
                            }
                        }
                    }

                    ?>

                    Options specified
                    <br>
                    <?php
                        echo "<pre>";
                        print_r(get_defined_vars());
                        if (isset($_POST['format'])) {
                            echo "<ul>Format: ", $_POST['format'], "</ul>";
                            $format = $_POST['format'];
                        }

                        if (isset($_POST['dir'])) {
                            echo "<ul>Monitor dir: ", $_POST['dir'], "</ul>";
                            $monitor_dir = $_POST['dir'];
                        }

                        echo "<ul>Scripts</ul>";
                        if (isset($_POST['existing_script'])) {
                            echo "<ul><ul>Analysis script (existing): ", $_POST['existing_script'], "</ul></ul>";
                            $script = __DIR__ . "/../scripts/" . $_POST['existing_script'];
                        }
                        if (isset($_POST['uploaded_script'])) {
                            echo "<ul><ul>Analysis script (prev uploaded): ", $_POST['uploaded_script'], "</ul></ul>";
                            $script = __DIR__ . "/uploads/$php_id/" . $_POST['uploaded_script'];
                        }
                        if (isset($_FILES['new_script']['name']) && $_FILES['new_script']['name'] != "") {
                            echo "<ul><ul>Analysis script (new): ", $_FILES['new_script']['name'], "</ul></ul>";
                            $script = __DIR__ . "/uploads/$php_id/" . $_POST['new_script']['name'];
                        }

                        echo "<ul>Timeout</ul>";
                        if (isset($_POST['timeout_format'])) {
                            echo "<ul><ul>Timeout format: ", $_POST['timeout_format'], "</ul></ul>";

                            switch ($_POST['timeout_format']) {
                                case "Seconds":
                                    $timeout_format = "-s";
                                    break;
                                case "Minutes":
                                    $timeout_format = "-m";
                                    break;
                                case "Hours":
                                    $timeout_format = "-hr";
                                    break;
                                case "Automatic":
                                    $timeout_format = "-a";
                                    break;
                            }
                        }
                        if (isset($_POST['timeout_time'])) {
                            if ($_POST['timeout_time'] == "") {
                                if ($timeout_format == "Automatic") {
                                    $timeout_time = "";
                                } else {
                                    echo "<ul><ul>Timeout format: ", 1, "</ul></ul>";
                                    $timeout_time = " 1";
                                }
                            } else {
                                echo "<ul><ul>Timeout format: ", $_POST['timeout_time'], "</ul></ul>";
                                $timeout_time = " " . $_POST['timeout_time'];
                            }
                        }

                        if (isset($_POST['simulation'])) {
                            echo "<ul>Simulation: ", $_POST['simulation'], "</ul>";
                            $simulate = true;
                        } else {
                            echo "<ul>Simulation: off</ul>";
                            $simulate = false;
                        }
                        if (isset($_POST['simulate_dir'])) {
                            echo "<ul><ul>Simulate dir: ", $_POST['simulate_dir'], "</ul></ul>";
                            $simulate_dir = $_POST['simulate_dir'];
                        }
                        if (isset($_POST['real_simulation'])) {
                            echo "<ul><ul>Realistic: ", $_POST['simulation'], "</ul></ul>";
                            $real_sim = " --real";
                        } else {
                            echo "<ul><ul>Realistic: off</ul></ul>";
                            $real_sim = "";
                        }
                        if (isset($_POST['time_between_reads'])) {
                            if ($_POST['time_between_reads'] == "") {
                                echo "<ul><ul>Time between reads: ", 0, "</ul></ul>";
                                $time_between_reads = 0;
                            } else {
                                echo "<ul><ul>Time between reads: ", $_POST['time_between_reads'], "</ul></ul>";
                                $time_between_reads = $_POST['time_between_reads'];
                            }
                        }
                        if (isset($_POST['number_of_reads'])) {
                            if ($_POST['number_of_reads'] == "") {
                                echo "<ul><ul>No. reads: all</ul></ul>";
                                $no_reads = -1;
                            } else {
                                echo "<ul><ul>No. reads: ", $_POST['number_of_reads'], "</ul></ul>";
                                $no_reads = $_POST['number_of_reads'];
                            }
                        }

                        $num_screens = shell_exec("ls log_*- | wc -l");
                        $num_screens = str_replace("\n", "", $num_screens);
                        echo "<br>No. screens: $num_screens";
                        if ($num_screens == "" || $num_screens < 0) {
                            $num_screens = 0;
                        }
                        $name = $num_screens . "_" . str_replace("/", "-", $monitor_dir);

                        echo "<ul>Screen name: $name</ul>"; // testing

                        $log_name = "log_$name";

                        if ($__FILE_UPLOAD_STATUS__ == -1) {
                            echo "File already exists";

                        } else if ($__FILE_UPLOAD_STATUS__ == 1) {
                            echo "File size is too large";
                        
                        } else if ($__FILE_UPLOAD_STATUS__ == 2) {
                            echo "File is not of type .sh";
                        
                        } else if ($__FILE_UPLOAD_STATUS__ == 3) {
                            echo "File failed during upload";

                        } else if (isset($_POST['execute'])) {
                            if ($_POST['execute'] == "start realtime analysis") {

                                if ($simulate) {
                                    $cmd = sprintf("screen -S %s -L -Logfile $log_name -d -m bash -c 'cd ../ && echo y | bash run.sh -f %s -m %s -8 %s%s --t=%s --n=%s -t %s%s -s %s'", 
                                                    $name, $format, $monitor_dir, $simulate_dir, $real_sim, $time_between_reads, $no_reads, $timeout_format, $timeout_time, $script);

                                } else {
                                    $cmd = sprintf("screen -S %s -L -Logfile $log_name -d -m bash -c 'cd ../ && echo y | bash run.sh -f %s -m %s -t %s%s -s %s'", 
                                                    $name, $format, $monitor_dir, $timeout_format, $timeout_time, $script);
                                }

                                echo "Command being run:<br>";
                                echo $cmd;

                                if ( shell_exec("ls '$log_name'") == "$log_name\n") {
                                    system("rm '$log_name'");
                                }

                                system($cmd);

                                if (shell_exec("cat database.csv") == "") {
                                    system("printf 'Name,Log_file,Format,Monitor_dir,Analysis_script,Timeout_format,Timeout_time,Simulate,Simulate_dir,Real_sim,Time_between_reads,Num_reads\n' >> database.csv");
                                }

                                system("printf '$name,$log_name,$format,$monitor_dir,$script,$timeout_format,$timeout_time,$simulate,$simulate_dir,$real_sim,$time_between_reads,$no_reads\n' >> database.csv");
                            }
                            
                        } else if (isset($_POST['halt'])) {
                            if ($_POST['halt'] == "kill all jobs") {
                                system("screen -list");
                                //$recent_screen = shell_exec("screen -list | sed -n 2p | cut -f2");
                                //$recent_screen = rtrim($recent_screen);

                                // if ($recent_screen == "") {
                                //     echo "<br>No process to stop";

                                // } else {

                                //     echo "<br>'$recent_screen'<br>";
                                //     system("screen -XS $recent_screen quit");
                                //     echo "<br>";
                                //     system("screen -list");
                                // }

                                system("pkill screen");
                                echo "<br>";
                                system("screen -list");
                                
                                system("cp /dev/null database.csv");
                                system("rm log_[^\.]*");
                            }
                        }
                    ?>
                </p>

            </div>

            <div class="left">
                <div id='log' style="margin: 0 20% 0 20%;">
                    <p>Jobs:</p>
                    <form id="job_buttons" method="POST">
                        <input type='submit' class='button' name='kill all' value='kill all jobs' style='float: left;' />
                        <br><br>
                        <?php

                            $jobs_str = shell_exec("cat database.csv | tail -n +2 | cut -d , -f1"); // extract list of screen pids
                            $jobs_arr = explode("\n", $jobs_str);
                            if (empty($jobs_arr[count($jobs_arr)-1])) { // remove last element if empty
                                unset($jobs_arr[count($jobs_arr)-1]);
                            }

                            foreach ($jobs_arr as $job) {
                                $job_name = $job;

                                if (isset($_POST["kill_all"])) {
                                    shell_exec("pkill screen");
                                    system("cp /dev/null database.csv");
                                    system("rm log_[^\.]*");
                                
                                } else if (isset($_POST["kill_$job_name"])) {
                                    system('for session in $(screen -ls | ' . 
                                    "grep -o '[0-9]*\.$job'); " . 
                                    'do screen -S "${session}" -X quit; done');

                                    if (($file = fopen("database.csv", "r")) != FALSE) {
                                        while (($data = fgetcsv($file)) != FALSE) {
                                            if ($data[0] == $job_name) {
                                                $log_filename = $data[1];
                                            }
                                        }

                                        fclose($file);

                                        system("rm $log_filename");
                                    }

                                    system("grep -vwE '($job_name)' database.csv > temp && mv temp database.csv");
                                }
                            }

                            $jobs_str = shell_exec("cat database.csv | tail -n +2 | cut -d , -f1"); // extract list of screen pids
                            $jobs_arr = explode("\n", $jobs_str);
                            if (empty($jobs_arr[count($jobs_arr)-1])) { // remove last element if empty
                                unset($jobs_arr[count($jobs_arr)-1]);
                            }

                            foreach ($jobs_arr as $job) {
                                $job_name = $job;

                                echo "<button type='button' class='button' id='$job_name' style='float: left;'>$job_name</button>";
                                echo "<br>";
                                echo "<div id='$job_name-options' class='hidden'>";
                                echo "<input type='submit' class='button' name='kill $job_name' value='kill job' style='float: left;' />";
                                echo "<button type='button' class='button' id='$job_name-output' style='float: left;'>show output</button>";
                                echo "<br>";
                                system("grep $job_name, database.csv");
                                echo "</div>";
                                echo "<br>";

                                echo "
                                <script type='text/javascript'>
                                    $(document).ready(function() {
                                        $('#$job_name').click(function() {
                                            element = document.getElementById('$job_name-options');
                                            if (element.classList.contains('hidden')) {
                                                $('#$job_name-options').removeClass('hidden');
                                            } else {
                                                $('#$job_name-options').addClass('hidden');
                                            }
                                        });
                                    });
                                </script>";

                                echo "
                                <script type='text/javascript'>
                                    $(document).ready(function() {
                                        $('#$job_name-output').click(function() {
                                            window.open('show_log.php?log_filename=log_$job_name', '_blank');
                                        });
                                    });
                                </script>";
                            }

                        ?>
                    </form>
                </div>
            </div>

        </div>

        <!-- <script src="js/oldbutton.js"></script> -->
        <script src="js/button.js?07-02-2020:15 49"></script>
        <script src="js/disabled.js?07-02-2020:15 43"></script>
    </body>
</html>