<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis - Home</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?12-02-2020:12 04" />
        <link rel="icon" type="image/png" href="favicon.png?13-02-2020:13 02" sizes="32x32"/>
    </head>

    <body>

        <?php session_start(); ?>

        <div class="outer-page-container">

            <div class="center">

                <div class="container">                 
                    <form id="analysis_form" method="POST" enctype="multipart/form-data">        
                        <fieldset>

                            <div class="div-question">
                                <button type='button' class="button question info" id="info-page">?</button>
                            </div>

                            <div id="modal-info-page" class="modal">
                                <div class="modal-content">
                                    <div class="question modal-header">
                                        <span class="close modal-close-info-page">&times;</span>
                                        <h2>What is this page?</h2>
                                    </div>
                                    <div class="modal-body">
                                        <p>
                                            This is intended to run analysis of Nanopore-sequenced DNA.<br>
                                            If you want to run a job just pick your options and click the "i" button beside them if you're unsure of their purpose.<br>
                                            Press "start real-time analysis" to start a job.<br>
                                            <br>
                                            The command-tools that are the backend of this website and the website code itself can be accessed <a href="https://github.com/sashajenner/realf5p" target="_blank">on GitHub</a>.<br>
                                            Enjoy saving hours of wait-time with realtime analysis!
                                            <br>
                                        </p>
                                        <p style="float: left;">
                                            Author: Sasha Jenner
                                        </p>
                                        <p style="float: right">
                                            Date: 12/02/2020
                                        </p>
                                        <br>
                                    </div>
                                </div>      
                            </div>

                            <div id="resuming">
                                <label for="resume" id="resume_label" style="font-weight: bold;">Resuming</label>
                                <?php
                                    if ($_POST["resuming"] == "on") {
                                        $checked = "checked='checked' ";
                                    } else {
                                        $checked = "";
                                    }
                                    echo "<input type='checkbox' name='resuming' id='resume' $checked/>";
                                ?>
                                <button type='button' class="button info" id="info-resume">i</button>

                                <div id="modal-info-resume" class="modal">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <span class="close modal-close-info-resume">&times;</span>
                                            <h2>Resuming - Information</h2>
                                        </div>
                                        <div class="modal-body">
                                            <p>
                                                If analysis halted or failed irrecoverably, but the run has not been completely sequenced.
                                                <br>Resuming will try to begin from where analysis ended.
                                                <br>Note: this option only works for realtime analysis.
                                            </p>
                                        </div>
                                    </div>      
                                </div>
                            </div>

                                <label for="format" style="font-weight: bold;">Format</label>
                                <button type='button' class="button info" id="info-format" style="margin-right: 20%">i</button>

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

                            <label for="dir" id="dir_label" style="font-weight: bold;">Monitor Directory</label>
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

                            <label for="timeout" id="timeout_label" style="font-weight: bold;">Timeout</label>
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
                            <label for="sim" id="sim_label" style="font-weight: bold;">Simulate</label>
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

                            <br><br>

                            <label for="non-real-time" id="non-real-time_label" style="font-weight: bold;">Non-real-time Analysis</label>
                            <?php
                                if ($_POST["non-real-time"] == "on") {
                                    $checked = "checked='checked' ";
                                } else {
                                    $checked = "";
                                }
                                echo "<input type='checkbox' name='non-real-time' id='non-real-time' $checked/>";
                            ?>
                            <button type='button' class="button info" id="info-non-real-time">i</button>

                            <div id="modal-info-non-real-time" class="modal">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <span class="close modal-close-info-non-real-time">&times;</span>
                                        <h2>Non-real-time Analysis - Information</h2>
                                    </div>
                                    <div class="modal-body">
                                        <p>This analyses in the traditional static way. Assumes file_list.cfg is in data directory.</p>
                                    </div>
                                </div>      
                            </div>
                        </fieldset>

                        <fieldset class="invisible">
                            <input type="submit" class="button" id="start" name="execute" value="start real-time analysis" />
                        </fieldset>

                    </form>
                </div>

            </div>

            <div class="right">
                <div class="container-right">
                    <h2 class="title">
                        Extra
                    </h2>

                    <fieldset class="invisible">
                        <input type="submit" class="button" id="reset" name="reset" value="reset to default options" />
                    </fieldset>

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

                        <h3>Options specified</h3>
                        <br>
                        <?php

                            function int64($i) {
                                return is_int($i) ? pack("q", $i) : unpack("q", $i)[1];
                            }

                            echo "<pre>";

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
                                $analysis_script = __DIR__ . "/../scripts/" . $_POST['existing_script'];
                            }
                            if (isset($_POST['uploaded_script'])) {
                                echo "<ul><ul>Analysis script (prev uploaded): ", $_POST['uploaded_script'], "</ul></ul>";
                                $analysis_script = __DIR__ . "/uploads/$php_id/" . $_POST['uploaded_script'];
                            }
                            if (isset($_FILES['new_script']['name']) && $_FILES['new_script']['name'] != "") {
                                echo "<ul><ul>Analysis script (new): ", $_FILES['new_script']['name'], "</ul></ul>";
                                $analysis_script = __DIR__ . "/uploads/$php_id/" . $_POST['new_script']['name'];
                            }

                            if ($analysis_script == "") {
                                echo "No script chosen :(";
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
                            $realtime = true;
                            if (isset($_POST["non-real-time"])) {
                                if ($_POST["non-real-time"] == "on") {
                                    echo "Non-real-time: on";
                                    $realtime = false;
                                } else {
                                    echo "Non-real-time: off";
                                }
                            }

                            $resuming = false;
                            if (isset($_POST["resuming"])) {
                                if ($_POST["resuming"] == "on") {
                                    echo "Resuming: on";
                                    $resuming = true;
                                } else {
                                    echo "Resuming: off";
                                }
                            }

                            $num_screens = 0;
                            $header = true;
                            if (($handle = fopen("database.csv", "r")) !== FALSE) {
                                while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
                                    if ($header) {
                                        $header = false;
                                        continue;
                                    }

                                    $val = intval(substr($data[0], 0));
                                    if ($val >= $num_screens) {
                                        $num_screens = $val + 1;
                                    }
                                }

                                fclose($handle);
                            }

                            echo "<br>No. screens: $num_screens";
                            if ($num_screens == "" || $num_screens < 0) {
                                $num_screens = 0;
                            }
                            $name = $num_screens . "_" . str_replace("/", "-", $monitor_dir);

                            echo "<ul>Screen name: $name</ul>";

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
                                if ($_POST['execute'] == "start real-time analysis") {

                                    if ($analysis_script == "") {
                                        echo "<script>alert('No script was chosen. Analysis uninitiated.')</script>";
                                    } else {

                                        if ($realtime) {

                                            if ($simulate) {
                                                // $cmd = sprintf("screen -S $name -L -Logfile $log_name-screen -d -m bash -c 'cd ../ && echo y | " .
                                                // "bash run.sh -f $format -l front/$log_name-run -m $monitor_dir -8 $simulate_dir$real_sim --t=$time_between_reads --n=$no_reads -t $timeout_format$timeout_time -s $analysis_script'");
                                                $cmd = "$name\tfront/$log_name/screen_log.txt\t-f $format -m $monitor_dir -8 $simulate_dir$real_sim --t=$time_between_reads --n=$no_reads -t $timeout_format$timeout_time -s $analysis_script --results-dir=front/$log_name -y";

                                            } else {

                                                if ($resuming) {
                                                    $resume="-r ";
                                                } else {
                                                    $resume="";
                                                }
                                                
                                                // $cmd = sprintf("screen -S $name -L -Logfile $log_name-screen -d -m bash -c 'cd ../ && echo y | " . 
                                                // "bash run.sh -f $format -l front/$log_name-run $resume-m $monitor_dir -t $timeout_format$timeout_time -s $analysis_script'");
                                                $cmd = "$name\tfront/$log_name/screen_log.txt\t-f $format $resume-m $monitor_dir -t $timeout_format$timeout_time -s $analysis_script --results-dir=front/$log_name -y";
                                            }

                                        } else {
                                            // $cmd = sprintf("screen -S $name -L -Logfile $log_name-screen -d -m bash -c 'cd ../ && echo y |" .
                                            // "bash run.sh -f $format -l front/$log_name-run --non-real-time -s $analysis_script");
                                            $cmd = "$name\tfront/$log_name/screen_log.txt\t-f $format --non-real-time -s $analysis_script --results-dir=front/$log_name -y";
                                        }

                                        echo "\nCommand being run:<br>";
                                        echo $cmd;

                                        if ( shell_exec("ls '$log_name'") != "") {
                                            system("rm -r '$log_name'");
                                        }

                                        system("mkdir '$log_name'");

                                        // Sending cmd to cluster head node
                                        $fp = fsockopen("127.0.0.1", 20022, $errno, $errstr, 30); // 30s timeout
                                        if (!$fp) {
                                            echo "$errstr ($errno)<br />\n";
                                        } else {
                                            $len = int64(strlen($cmd));
                                            fwrite($fp, $len);
                                            fwrite($fp, $cmd);
                                            while (!feof($fp)) {
                                                echo fgets($fp, 4096);
                                            }
                                            fclose($fp);
                                        }

                                        if (shell_exec("cat database.csv") == "") {
                                            system("printf 'Name,Resuming,Log_file,Format,Monitor_dir,Analysis_script,Timeout_format,Timeout_time,Simulate,Simulate_dir,Real_sim,Time_between_reads,Num_reads,Real-time\n' >> database.csv");
                                        }

                                        system("printf '$name,$resuming,$log_name,$format,$monitor_dir,$analysis_script,$timeout_format,$timeout_time,$simulate,$simulate_dir,$real_sim,$time_between_reads,$no_reads,$realtime\n' >> database.csv");
                                    }
                                }
                                
                            }

                            echo "<br>";
                            print_r(get_defined_vars());
                        ?>
                    </p>
                </div>

            </div>

            <div class="left">
                <div id='log'>
                    <h2 class="title">Jobs</h2>
                    <form id="job_buttons" method="POST" onSubmit="return confirm('Are you sure? This action is irreversible.');">
                        <input type='submit' class='button kill' name='kill all' value='kill all jobs' />
                        <br><br>
                        <?php

                            if (isset($_POST["kill_all"])) {
                                // Sending cmd to cluster head node
                                $cmd = "kill all";

                                $fp = fsockopen("127.0.0.1", 20022, $errno, $errstr, 30); // 30s timeout
                                if (!$fp) {
                                    echo "$errstr ($errno)<br />\n";
                                } else {
                                    $len = int64(strlen($cmd));
                                    fwrite($fp, $len);
                                    fwrite($fp, $cmd);
                                    while (!feof($fp)) {
                                        echo fgets($fp, 4096);
                                    }
                                    fclose($fp);
                                }

                                system("cp /dev/null database.csv");
                                system("rm -rf log_*_*");
                            }

                            $jobs_str = shell_exec("cat database.csv | tail -n +2 | cut -d , -f1"); // extract list of screen pids
                            $jobs_arr = explode("\n", $jobs_str);
                            if (empty($jobs_arr[count($jobs_arr)-1])) { // remove last element if empty
                                unset($jobs_arr[count($jobs_arr)-1]);
                            }

                            foreach ($jobs_arr as $job) {
                                $job_name = $job;

                                if (isset($_POST["kill_$job_name"])) {

                                    $cmd = "kill\t$job_name";

                                    $fp = fsockopen("127.0.0.1", 20022, $errno, $errstr, 30); // 30s timeout
                                    if (!$fp) {
                                        echo "$errstr ($errno)<br />\n";
                                    } else {
                                        $len = int64(strlen($cmd));
                                        fwrite($fp, $len);
                                        fwrite($fp, $cmd);
                                        while (!feof($fp)) {
                                            echo fgets($fp, 4096);
                                        }
                                        fclose($fp);
                                    }

                                    if (($file = fopen("database.csv", "r")) != FALSE) {

                                        $header = true;
                                        while (($data = fgetcsv($file)) != FALSE) {
                                            if ($header) {
                                                for ($x = 0; $x < count($data); $x ++) {
                                                    if ($data[$x] == "Log_file") {
                                                        $col_log = $x;

                                                    } else if ($data[$x] == "Name") {
                                                        $col_name = $x;
                                                    }

                                                }

                                                $header = false;

                                            } else if ($data[$col_name] == $job_name) {
                                                $log_filename = $data[$col_log];
                                            }
                                        }

                                        fclose($file);
                                        
                                        if ($log_filename != "") {
                                            system("rm -r $log_filename");
                                        }
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

                                echo "<button type='button' class='button log-info' id='$job_name' style='float: left; position: relative'>$job_name</button>";
                                echo "<br>";
                                echo "<div id='$job_name-options' class='hidden options'>";
                                echo "<input type='submit' class='button kill' name='kill $job_name' value='kill job' />";
                                echo "<button type='button' class='button show-log' id='$job_name-output'>show output</button>";
                                echo "<br>";

                                if (($file = fopen("database.csv", "r")) != FALSE) {

                                    $first = true;
                                    while (($data = fgetcsv($file)) != FALSE) {

                                        if ($first) {
                                            $header = $data;
                                            $first = false;

                                        } else if ($data[0] == $job_name) {
                                            for ($x = 0; $x < count($data); $x ++) {
                                                echo $header[$x] . ": " . $data[$x] . "<br>";
                                            }
                                        }
                                    }

                                    fclose($file);
                                }

                                echo "</div>";
                                echo "<br>";

                                echo "
                                <script type='text/javascript'>
                                    $(document).ready(function() {
                                        $('#$job_name').click(function() {
                                            element = document.getElementById('$job_name-options');
                                            if (element.classList.contains('hidden')) {
                                                $('#$job_name-options').removeClass('hidden');
                                                $('#$job_name').addClass('js-dark-turquoise');
                                            } else {
                                                $('#$job_name-options').addClass('hidden');
                                                $('#$job_name').removeClass('js-dark-turquoise');
                                            }
                                        });
                                    });
                                </script>";

                                echo "
                                <script type='text/javascript'>
                                    $(document).ready(function() {
                                        $('#$job_name-output').click(function() {
                                            window.open('show_log.php?log_filename=log_$job_name/screen_log.txt', '_blank');
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
        <script src="js/button.js?17-02-2020:11 55"></script>
        <script src="js/disabled.js?13-02-2020:10 33"></script>
    </body>
</html>