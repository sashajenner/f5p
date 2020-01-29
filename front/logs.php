<!DOCTYPE html>
<html>
    <head>
        <title>Realtime Analysis</title>
        <script src="js/jquery-3.4.1.min.js"></script>
        <link rel="stylesheet" href="css/style.css?29-01-2020:11 18" />
        <meta http-equiv="refresh" content="5" />
    </head>

    <body>
        <div id='log'>
            <?php
                $output = shell_exec("tac ../log.txt");
                $dictionary = array(
                    '[1;34m'    =>  '<span style="color:blue">',
                    '[1;331m'   =>  '<span style="color:red">',
                    '[1;33m'    =>  '<span style="color:yellow">',
                    '[0m'       =>  '</span>',
                );
                
                $output_color = str_replace(array_keys($dictionary), $dictionary, $output);
                
                echo $output_color;
            ?>
        </div>
    </body>
</html>