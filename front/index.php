<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?29-01-2020:11 18" />
    </head>

    <body>
        <form id="analysis_form" method="POST">
            <fieldset class="invisible">
                <input type="submit" class="button" name="reset" value="reset to default options" />
            </fieldset>
            <fieldset>
                <label for="format" style="font-weight: bold;">Format</label>
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
                <input type="checkbox" name="simulation" id="sim" />
                <br>
                <label for="sim-real">Realistic</label>
                <input type="checkbox" name="real simulation" id="sim-real" />
                <br>
                <label for="sim-dir">Simulate Directory</label>
                <select name="simulate dir" id="sim-dir">
                    <?php
                        $mnt_dirs_str = shell_exec("ls -d /mnt/*/");
                        $mnt_dirs_arr = explode("\n", $mnt_dirs_str);
                        if (empty($mnt_dirs_arr[count($mnt_dirs_arr)-1])) { // remove last element if empty
                            unset($mnt_dirs_arr[count($mnt_dirs_arr)-1]);
                        }

                        foreach ($mnt_dirs_arr as $dir) {

                            if ($dir == $_POST['sim-dir']) {
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
                <input type="text" name="time between batches" id="sim-time" placeholder="0" />
                <br>
                <label for="sim-batch_num">Number of batches</label>
                <input type="number" name="number of batches" id="sim-batch_num" placeholder="all" min="0" />
            </fieldset>

            <br>
            <fieldset class="invisible">
                <input type="submit" class="button" name="execute" value="start realtime analysis" />
                <input type="submit" class="button" name="halt" value="stop all" />
            </fieldset>
        </form>

        <form id="logs_button" action="logs.php" method="POST">
            <input type="submit" class="button" name="logs" value="view jobs" />
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
                    $real_sim = "--real ";
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

                if (isset($_POST['execute'])) {
                    if ($_POST['execute'] == "start realtime analysis") {

                        if ($simulate) {
                            echo "Command being run:<br>";
                            $cmd = sprintf("screen -S %s -L -d -m bash -c 'echo y | bash ../run.sh -f %s -m %s -8 %s%s --t %s --n %s -t %s%s'", 
                                            $name, $format, $monitor_dir, $simulate_dir, $real_sim, $time_between_batches, $no_batches, $timeout_format, $timeout_time);

                        } else {
                            echo "Command being run:<br>";
                            $cmd = sprintf("screen -S %s -L -d -m bash -c 'bash ../run.sh -f %s -m %s -t %s%s'", 
                                            $name, $format, $monitor_dir, $timeout_format, $timeout_time);
                        }

                        echo $cmd;
                        system($cmd);

                        system("printf '$name\nFormat:$format Monitor_dir:$monitor_dir Analysis_script:$script Timeout_format:$timeout_format Timeout_time:$timeout_time Simulate:$simulate Simulate_dir:$simulate_dir Real_simulation:$real_sim Time_between_batches:$time_between_batches Num_batches:$no_batches' >> database.txt");
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
                        
                        system("cp /dev/null database.txt");
                    }
                }
            ?>
        </p>
        <!-- <script src="js/oldbutton.js"></script> -->
        <script src="js/disabled.js"></script>
        <script src="js/button.js?31-01-2020:11 56"></script>
    </body>
</html>