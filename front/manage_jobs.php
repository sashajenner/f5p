<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis - Manage Jobs</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?31-01-2020:15 44" />
        <link rel="icon" type="image/png" href="favicon.png?05-02-2020:11 53" sizes="32x32"/>
    </head>

    <body>
        <div style="position: absolute; left: 1%;">
            <form id="main_button" action="index.php" method="POST">
                <input type="submit" class="button" name="return main" value="go back" />
            </form>
        </div>

        <div id='log' style="margin: 0 20% 0 20%;">
            Jobs:
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

                        } else if (isset($_POST["view_$job_name"])) {
                            if (($file = fopen("database.csv", "r")) != FALSE) {
                                while (($data = fgetcsv($file)) != FALSE) {
                                    if ($data[0] == $job_name) {
                                        $log_filename = $data[1];
                                    }
                                }

                                fclose($file);

                                header("Location: show_log.php?log_filename=$log_filename");
                                exit;
                            }
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
                        echo "<input type='submit' class='button' id='$job_name-output' name='view $job_name' value='show output' style='float: left;' />";
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
                                    
                                });
                            });
                        </script>";
                    }

                    print_r(get_defined_vars());
                ?>
            </form>
        </div>
    </body>
</html>