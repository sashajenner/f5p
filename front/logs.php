<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?31-01-2020:15 44" />
        <!-- <meta http-equiv="refresh" content="5" /> -->
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
            <!-- <form id="job_buttons" action="logs.php" method="POST"> -->
                <?php

                    $jobs_str = shell_exec("screen -list | tail -n +2 | head -n -1 | cut -f2"); // extract list of screen pids
                    $jobs_arr = explode("\n", $jobs_str);
                    if (empty($jobs_arr[count($jobs_arr)-1])) { // remove last element if empty
                        unset($jobs_arr[count($jobs_arr)-1]);
                    }

                    foreach ($jobs_arr as $job) {
                        $job_name = explode(".", $job)[1];
                        if (isset($_POST["kill_$job_name"])) {
                            system("screen -X -S $job quit");
                        }
                    }

                    $jobs_str = shell_exec("screen -list | tail -n +2 | head -n -1 | cut -f2"); // extract list of screen pids
                    $jobs_arr = explode("\n", $jobs_str);
                    if (empty($jobs_arr[count($jobs_arr)-1])) { // remove last element if empty
                        unset($jobs_arr[count($jobs_arr)-1]);
                    }

                    foreach ($jobs_arr as $job) {
                        $job_name = explode(".", $job)[1];

                        echo "<button type='button' class='button' id='$job_name' style='float: left;'>$job_name</button>";
                        echo "<br>";
                        echo "<div id='$job_name-options' class='hidden'>";
                        echo "<input type='submit' class='button' name='kill $job_name' value='kill job' style='float: left;' />";
                        echo "<input type='submit' class='button' name='view job' value='show output' style='float: left;' />";
                        echo "</div>";

                        system("grep $job_name database.txt");
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
                    }

                    print_r(get_defined_vars());
                    
                    if (isset($_POST['job'])) {
                        $job_id = $_POST['job'];
                        
                        $output = shell_exec("tac ../log.txt");
                        $dictionary = array(
                            '[1;34m'    =>  '<span style="color:blue">',
                            '[1;331m'   =>  '<span style="color:red">',
                            '[1;33m'    =>  '<span style="color:yellow">',
                            '[0m'       =>  '</span>',
                        );
                        
                        $output_color = str_replace(array_keys($dictionary), $dictionary, $output);
                        
                        echo $output_color;
                    }
                ?>
            </form>
        </div>
    </body>
</html>