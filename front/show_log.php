<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis - Log Viewer</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?20-02-2020:14 34" />
        <link rel="icon" type="image/png" href="favicon.png?13-02-2020:13 02" sizes="32x32"/>
        <meta name="google" content="notranslate">
    </head>

    <body>
        <div class="button_container">
            <button class="button toggle toggle-green" id="toggle-refresh">Auto Refresh: ON</button>
        </div>
        <div class="log">
            <?php
                if (isset($_GET["log_filename"])) {
                    $log_filename = $_GET["log_filename"];

                    $output = shell_exec("cat -n $log_filename | awk '{ x = $0 " . '"\n" x } END { printf "%s", x }' ."'");
                    $dictionary = array(
                        '[34m'    =>  '<span style="color:rgba(62, 194, 10, 1)">',
                        '[0;31m'  =>  '<span style="color:red">',
                        '[1;31m'  =>  '<span style="color:red">',
                        '[0;33m'  =>  '<span style="color:orange">',
                        '[1;33m'  =>  '<span style="color:orange">',
                        '[1;34m'  =>  '<span style="color:magenta">',
                        '[1;35m'  =>  '<span style="color:yellow">',
                        '[0;33m'  =>  '<span style="color:rgba(36, 109, 245, 1)">',
                        '[0m'     =>  '</span>',
                        '[0;39m'  =>  '</span>',
                    );

                    $output_color = str_replace(array_keys($dictionary), $dictionary, $output);

                    echo "<pre>$output_color</pre>";
                }
            ?>
        </div>
    </body>

    <script src="js/button.js?17-02-2020:12 44"></script>
    <script src="js/refresh.js?17-02-2020:12 44"></script>
</html>
