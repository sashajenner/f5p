<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis - Home</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?05-02-2020:11 34" />
        <link rel="icon" type="image/png" href="favicon.png?05-02-2020:11 53" sizes="32x32"/>
    </head>

    <body>
        <fieldset class="invisible">
            <form id="logs_button" action="manage_jobs.php" method="POST">
                <input type="submit" class="button" name="logs" value="view jobs" />
            </form>

            <input type="submit" class="button" name="reset" value="reset to default options" />
        </fieldset>
        
        <form id="analysis_form" method="POST">        
            <fieldset>
                <label for="format" style="font-weight: bold;">Format</label>
                <button type='button' class="info" id="myBtn">i</button>

                <div id="myModal" class="modal">
                    <div class="modal-content">
                        <div class="modal-header">
                            <span class="close">&times;</span>
                            <h2>Format Information</h2>
                        </div>
                        <div class="modal-body">
                            <p>
        Specify folder & file format of the sequencer's output:<br><br>
            &emsp;--778&emsp;[directory]&emsp;&emsp;(Old format that's not too bad)<br>
                &emsp;&emsp;|-- fast5/<br>
                &emsp;&emsp;&emsp;|-- [prefix].fast5.tar<br>
                &emsp;&emsp;|-- fastq/<br>
                &emsp;&emsp;&emsp;|-- fastq_*.[prefix].fastq.gz<br>
                &emsp;&emsp;|-- logs/ (optional - for realistic testing<br>
                &emsp;&emsp;&emsp;&emsp;or automatic timeout)<br>
                &emsp;&emsp;|-- sequencing_summary.[prefix].txt.gz<br>
            <br>
            &emsp;--NA&emsp;[directory]&emsp;&emsp;(Newer format with terrible folders)<br>
                &emsp;&emsp;|-- fast5/<br>
                &emsp;&emsp;&emsp;|-- [prefix].fast5<br>
                &emsp;&emsp;|-- fastq/<br>
                &emsp;&emsp;&emsp;|-- [prefix]/<br>
                &emsp;&emsp;&emsp;&emsp;|-- [prefix].fastq<br>
                &emsp;&emsp;&emsp;&emsp;|-- sequencing_summary.txt (optional -<br>
                &emsp;&emsp;&emsp;&emsp;&emsp;for realistic testing or automatic timeout)<br>
            <br>
            &emsp;--zebra&emsp;[directory]&emsp;&emsp;(Newest format)<br>
                    &emsp;&emsp;|-- fast5/<br>
                    &emsp;&emsp;&emsp;|-- [prefix].fast5<br>
                    &emsp;&emsp;|-- fastq/<br>
                    &emsp;&emsp;&emsp;|-- [prefix].fastq<br>
                    &emsp;&emsp;|-- sequencing_summary.txt<br>
                            
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
                <br>
                <label for="script-exist">1) Existing pipelines</label>
                <select name="existing_script" id="script-exist">
                    <?php
                        $scripts_arr = explode("\n", shell_exec("ls -p ../scripts | grep -v / | grep fast5_pipeline"));
                        if (empty($scripts_arr[count($scripts_arr)-1])) { // remove last element if empty
                            unset($scripts_arr[count($scripts_arr)-1]);
                        }

                        foreach ($scripts_arr as $script) {

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
                <label for="script-new">2) Your own pipeline</label>
                <input type="file" name="new_script" id="script-new" accept=".sh" />
                <?php
                    if ($_POST['new_script'] != "") {
                        echo "<br>Previously: ", $_POST['new_script'];
                    }
                ?>
                <br><br>

                <label for="timeout" style="font-weight: bold;">Timeout</label>
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
                <br>
                <label for="sim-real">Realistic</label>
                    <?php
                        if ($_POST["real_simulation"] == "on") {
                            $checked = "checked='checked' ";
                        } else {
                            $checked = "";
                        }
                        echo "<input type='checkbox' name='real simulation' id='sim-real' $checked/>";
                    ?>
                <br>
                <label for="sim-dir">Simulate Directory</label>
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
                <br>
                <label for="sim-time">Time between batches</label>
                    <?php
                        if ($_POST["time_between_batches"] != "") {
                            $time = $_POST["time_between_batches"];
                            $value = "value='$time' ";
                        } else {
                            $value = "";
                        }
                        echo "<input type='text' name='time between batches' id='sim-time' placeholder='0' $value/>";
                    ?>
                <br>
                <label for="sim-batch_num">Number of batches</label>
                    <?php
                        if ($_POST["number_of_batches"] != "") {
                            $prev_no_batches = $_POST["number_of_batches"];
                            $value = "value='$prev_no_batches' ";
                        } else {
                            $value = "";
                        }
                        echo "<input type='number' name='number of batches' id='sim-batch_num' placeholder='all' min='0' $value/>";
                    ?>
            </fieldset>

            <fieldset class="invisible">
                <input type="submit" class="button" name="execute" value="start realtime analysis" />
                <input type="submit" class="button" name="halt" value="stop all" />
            </fieldset>
        </form>

        <p><br>
            Options specified
            <br>
            <?php
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
                    $script = $_POST['existing_script'];
                }
                if (isset($_POST['new_script'])) {
                    echo "<ul><ul>Analysis script (new): ", $_POST['new_script'], "</ul></ul>";
                    $script = $_POST['new_script'];
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
                if (isset($_POST['time_between_batches'])) {
                    if ($_POST['time_between_batches'] == "") {
                        echo "<ul><ul>Time between batches: ", 0, "</ul></ul>";
                        $time_between_batches = 0;
                    } else {
                        echo "<ul><ul>Time between batches: ", $_POST['time_between_batches'], "</ul></ul>";
                        $time_between_batches = $_POST['time_between_batches'];
                    }
                }
                if (isset($_POST['number_of_batches'])) {
                    if ($_POST['number_of_batches'] == "") {
                        echo "<ul><ul>No. batches: all</ul></ul>";
                        $no_batches = -1;
                    } else {
                        echo "<ul><ul>No. batches: ", $_POST['number_of_batches'], "</ul></ul>";
                        $no_batches = $_POST['number_of_batches'];
                    }
                }

                $num_screens = shell_exec("screen -list | wc -l");
                $num_screens -= 2;
                echo "<br>No. screens: $num_screens";
                if ($num_screens == "" || $num_screens < 0) {
                    $num_screens = 0;
                }
                $name = $num_screens . "_" . str_replace("/", "-", $monitor_dir);

                echo "<ul>Screen name: $name</ul>"; // testing

                $log_name = "log_$name";

                if (isset($_POST['execute'])) {
                    if ($_POST['execute'] == "start realtime analysis") {

                        if ($simulate) {
                            $cmd = sprintf("screen -S %s -L -Logfile $log_name -d -m bash -c 'cd ../ && echo y | bash run.sh -f %s -m %s -8 %s%s --t %s --n %s -t %s%s'", 
                                            $name, $format, $monitor_dir, $simulate_dir, $real_sim, $time_between_batches, $no_batches, $timeout_format, $timeout_time);

                        } else {
                            $cmd = sprintf("screen -S %s -L -Logfile $log_name -d -m bash -c 'cd ../ && echo y | bash run.sh -f %s -m %s -t %s%s'", 
                                            $name, $format, $monitor_dir, $timeout_format, $timeout_time);
                        }

                        echo "Command being run:<br>";
                        echo $cmd;

                        if ( shell_exec("ls '$log_name'") == "$log_name\n") {
                            system("rm '$log_name'");
                        }

                        system($cmd);

                        if (shell_exec("cat database.csv") == "") {
                            system("printf 'Name,Log_file,Format,Monitor_dir,Analysis_script,Timeout_format,Timeout_time,Simulate,Simulate_dir,Real_sim,Time_between_batches,Num_batches\n' >> database.csv");
                        }

                        system("printf '$name,$log_name,$format,$monitor_dir,$script,$timeout_format,$timeout_time,$simulate,$simulate_dir,$real_sim,$time_between_batches,$no_batches\n' >> database.csv");
                    }
                    
                } else if (isset($_POST['halt'])) {
                    if ($_POST['halt'] == "stop all") {
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
        <!-- <script src="js/oldbutton.js"></script> -->
        <script src="js/disabled.js?05-02-2020:09 57"></script>
        <script src="js/button.js?05-02-2020:10 16"></script>
    </body>
</html>