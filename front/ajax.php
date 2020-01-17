<?php
    header("Content-Type: application/json", true); // enable sending JSON data

    if (isset($_POST['action'])) {
        switch ($_POST['action']) {
            case 'start realtime analysis':
                execute();
                break;
        }
    }

    print_r(get_defined_vars());

    function execute() {
        echo "The execute function is called.";
        exit;
    }
?>