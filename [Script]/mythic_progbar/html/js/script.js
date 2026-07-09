$('document').ready(function() {
    MythicProgBar = {};

    MythicProgBar.Progress = function(data) {
        maxTime = data.duration;
        start = new Date();
        timeoutVal = Math.floor(data.duration / 100);
        MythicProgBar.animateUpdate()

        $("#block").css({"display":"block"});
        $("#block").slideDown(0)
        $("#progress-label").text(data.label);
        // $("#progress-bar").stop().css({"width": 0, "background-color": "#FFFFFF"}).animate({
        //   width: '100%'
        // }, {
        //   duration: parseInt(data.duration),
        //   complete: function() {
        //     $("#block").slideUp(200)
        //     $("#progress-bar").css("width", 0);
        //     $.post('http://mythic_progbar/actionFinish', JSON.stringify({
        //         })
        //     );
        //   }
        // });
    };

    MythicProgBar.animateUpdate = function() {
        var now = new Date();
        var timeDiff = now.getTime() - start.getTime();
        var perc = Math.round((timeDiff / maxTime) * 100);
        if (perc <= 100) {
            $("#progress-bar").css("width", + perc +"%");
            setTimeout(MythicProgBar.animateUpdate, timeoutVal);
        } else {
            $("#block").slideUp(200)
            $("#progress-bar").css("width", 0);
            $.post('http://mythic_progbar/actionFinish', JSON.stringify({
                })
            );
        }
    }

    MythicProgBar.ProgressCancel = function() {
        $("#block").css({"display":"block"});
        $("#progress-label").text("ยกเลิก");
        $("#progress-bar").stop().css( {"width": "100%", "background-color": "#585858"});

        setTimeout(function () {
            $("#block").slideUp(200)
            $("#progress-bar").css("width", 0);
            $.post('http://mythic_progbar/actionCancel', JSON.stringify({
                })
            );
        }, 1000);
    };

    MythicProgBar.CloseUI = function() {
        $('.main-container').css({"display":"none"});
        $(".character-box").removeClass('active-char');
        $(".character-box").attr("data-ischar", "false")
        $("#delete").css({"display":"none"});
    };
    
    window.addEventListener('message', function(event) {
        switch(event.data.action) {
            case 'mythic_progress':
                MythicProgBar.Progress(event.data);
                break;
            case 'mythic_progress_cancel':
                MythicProgBar.ProgressCancel();
                break;
        }
    })
});