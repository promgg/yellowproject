
var audio = new Audio('notif.mp3');
audio.volume = 0.5;

$(function(){
    $(".container").fadeOut();
    $(".container").css("animation", "step3 0.5s ease-out", "boat");
    $(".icon").css("animation", "step4 0.5s ease-out", "boat");
    window.addEventListener("message", function(event){
        let v = event.data;
        if (v.action == 'showHelp') {
            $(".container").show();
            $(".container").css("animation", "step1 0.5s ease-out", "boat");
            $(".icon").css("animation", "step2 0.5s ease-out", "boat");
            $("#text").html(v.message); 
            audio.play();
        } else if (v.action == 'hideHelp') {
            $(".container").fadeOut();
            $(".container").css("animation", "step3 0.5s ease-out", "boat");
            $(".icon").css("animation", "step4 0.5s ease-out", "boat");
        }
    })
})

