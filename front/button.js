$(document).ready(function() {

    $('.button').click(function() {
        var clickBtnValue = $(this).val();
        console.log(clickBtnValue);

        //$.ajax({
        //    type:'POST',
        //    url:'ajax.php',
        //    data:{'action': clickBtnValue},
        //    dataType:'json',
        //    success: function(msg) {
        //        console.log(msg);
        //        alert("Hi");
        //    },
        //    error: function(xhr, textStatus, thrownError, data) {
        //        alert("Error" + thrownError);
        //    },
        //    contentType: 'application/json; charset=utf-8'
        //});

        var hi = $.post('ajax.php', 
            {'action': clickBtnValue}, 
            function(response) {
                alert("action performed successfully");
            }
        )
            .done(function() {
                alert( "second success" );
            })
            .fail(function() {
                alert( "error" );
            })
            .always(function() {
                alert( "finished" );
            });
    });

});