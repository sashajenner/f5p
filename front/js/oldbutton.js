$(document).ready(function() {

    $('.button').click(function() {
        var clickBtnValue = $(this).val();
        var ajaxurl = 'analyse.php';
        btn_data = {'action': clickBtnValue};

        console.log(clickBtnValue);
        console.log(btn_data);

        $.post(ajaxurl, btn_data, function(response) {
            alert("success");
        });

        $.ajax({
            type: "POST",
            url: ajaxurl,
            data: btn_data,
            dataType: "json",
            contentType: "application/x-www-form-urlencoded",
            success: function(msg) {
                console.log(msg);
                alert("Hi");
            },
            error: function(xhr, textStatus, thrownError, data) {
                alert("Error" + thrownError + textStatus + data);
            }
        });

        var oReq = new XMLHttpRequest(); // New request object
        oReq.onload = function() {
            alert(this.responseText); // testing
            // if (this.responseText == 0) {
            //     alert("success: analyse began");
            // }
        };
        oReq.open("get", "analyse.php", true);
        oReq.send();
    });

});