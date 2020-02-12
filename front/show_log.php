<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis - Log Viewer</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?10-02-2020:15 41" />
        <link rel="icon" type="image/png" href="favicon.png?05-02-2020:11 53" sizes="32x32"/>
    </head>

    <body>
        <div class="log">
            <div class="button_container">
                <button class="button toggle toggle-green" id="toggle-refresh">Auto Refresh: ON</button>
            </div>
            <?php
                if (isset($_GET["log_filename"])) {
                    $log_filename = $_GET["log_filename"];

                    $output = shell_exec("tac $log_filename");
                    $dictionary = array(
                        '[34m'    =>  '<span style="color:rgba(62, 194, 10, 1)">',
                        '[1;331m'   =>  '<span style="color:red">',
                        '[1;33m'    =>  '<span style="color:yellow">',
                        '[0;39m'       =>  '</span>',
                    );

                    $output_color = str_replace(array_keys($dictionary), $dictionary, $output);

                    echo "<pre>$output_color</pre>";
                }
            ?>
        </div>
    </body>

    <script src="js/button.js?12-02-2020:13 41"></script>
</html>
