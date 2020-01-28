<?php
    // if (isset($_GET['execute'])) {
    //     switch ($_GET['execute']) {
    //         case 'start realtime analysis':
    //             execute();
    //             break;
    //     }
    // }

    // if (isset($_GET['halt'])) {
    //     switch ($_GET['halt']) {
    //         case 'stop it':
    //             halt();
    //             break;
    //     }
    // }

    // function execute() {   
    //     header('Content-Type:application/json;');
    //     echo json_encode(42);
    //     exit;
    // }

    // function halt() {
    //     header('Content-Type:application/json;');
    //     echo json_encode(-1);
    //     exit;
    // }

    header('Content-Type:application/json;');
    system(printf("screen -S %s bash /home/sasha/realf5p/run.sh -f %s -m %s", $name, $format, $monitor_dir));
    echo json_encode(0);
?>