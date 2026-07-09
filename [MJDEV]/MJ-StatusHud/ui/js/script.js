
let https = "https://MJ-StatusHud/";
let slideTimeout = null;
let isMountedState = false; // เก็บสถานะล่าสุดของ isMounted
let hudVisible = true;

window.addEventListener('message', e => {
    const MJDEV = e.data;
    const id = MJDEV.id;
    const temp = MJDEV.temp;
    const health = MJDEV.health;
    const armor = MJDEV.armor;
    const stemina = parseInt(MJDEV.stamina);
    
    $("#temp").html(temp);
    $("#id").html(Math.round(id));
    $("#data-armorload").css("width", armor + "%");

    var maxstemina = 255;
    var steminaPercent = Math.min(Math.floor((stemina / maxstemina) * 100), 100);
    $("#data-steminaload").css("width", steminaPercent + "%");

    var maxHealth = 600;
    var healthPercent = Math.min(Math.floor((health / maxHealth) * 100), 100);
    $("#data-healtprecent").html(healthPercent + "%");
    $("#data-healthload").css("width", healthPercent + "%");

    var healthColor = health > 600 ? "gold" : "red";
    $("#data-healthload").css("background", healthColor);

    if (MJDEV.thirst !== undefined) {
        $("#thirst").css("background", `conic-gradient(var(--base-hungerload) ${MJDEV.thirst}%, transparent 0%)`);
    }

    if (MJDEV.hunger !== undefined) {
        $("#hunger").css("background", `conic-gradient(var(--base-hungerload) ${MJDEV.hunger}%, transparent 0%)`);
    }

    if (MJDEV.modeTalk == 1) {
        $("#data-voice").html('กระซิบ');
    } else if (MJDEV.modeTalk == 2) {
        $("#data-voice").html('ปกติ');
    } else if (MJDEV.modeTalk == 3) {
        $("#data-voice").html('ตะโกน');
    }

    $("#data-voice").css('color', MJDEV.talkActive ? '#50286d' : 'white');

    if (MJDEV.isMounted) {
        $(".hud").css("transform", "translateX(65%)");
    
        $(".MJDev-Status-Horse-Box-main").css({
            display: "flex",
            opacity: 1,
            transform: "translateY(0)"
        });
    
        if (MJDEV.stress !== undefined) {
            $("#stress").css("background", `conic-gradient(var(--base-stressload) ${MJDEV.stress}%, transparent 0%)`);
        }
    
        if (MJDEV.horsehealth !== undefined) {
            $("#horsehealth").css("background", `conic-gradient(var(--base-hungerload) ${MJDEV.horsehealth}%, transparent 0%)`);
        }
    
        if (MJDEV.horsestamina !== undefined) {
            $("#horsestamina").css("background", `conic-gradient(var(--base-hungerload) ${MJDEV.horsestamina}%, transparent 0%)`);
        }
    
        if (MJDEV.horseclean !== undefined) {
            $("#horseclean").css("background", `conic-gradient(var(--base-hungerload) ${MJDEV.horseclean}%, transparent 0%)`);
        }
    
    } else {
        $(".hud").css("transform", "translateX(0%)");
    
        $(".MJDev-Status-Horse-Box-main").css({
            opacity: 0,
            transform: "translateY(20px)"
        });
    
        // รอ transition จบค่อย hide
        setTimeout(() => {
            $(".MJDev-Status-Horse-Box-main").css("display", "none");
        }, 500);
    }

    if (MJDEV.action === "toggleHud") {
        hudVisible = MJDEV.state;
        if (!hudVisible) {
            $(".hud").addClass("hud-hidden");
        } else {
            $(".hud").removeClass("hud-hidden");
        }        
        return;
    }
    

    if (!hudVisible) return; // ไม่ทำงานถ้า UI ปิด
    
});

$(document).ready(() => {
    $.post(https + "setup", JSON.stringify()).then((luadata) => {
        if (luadata) {
            MJDEVSetUpUi(luadata.style);
        }
    });
});

function MJDEVSetUpUi(style) {
    $(":root").css({
        "--base-primary-color": style.primarycolor,
        "--base-healthload-color": style.healthloadcolor,
        "--base-armorload-color": style.armorloadcolor,
        "--base-steminaload-color": style.steminaloadcolor,
        "--base-hungerload": style.hungerloadcolor,
        "--base-stressload": style.stressloadcolor,
    });
}

let dateToday = document.getElementById("calendar");
let today = new Date();
let day = `${today.getDate() < 10 ? "0" : ""}${today.getDate()}`;
let month = `${(today.getMonth() + 1) < 10 ? "0" : ""}${today.getMonth() + 1}`;
let year = today.getFullYear();
dateToday.textContent = `${day}/${month}/${year}`;

function checkTime(i) {
    if (i < 10) {
        i = "0" + i;
    }
    return i;
}

function startTime() {
    var today = new Date();
    var h = today.getHours();
    var m = today.getMinutes();
    var s = today.getSeconds();
    m = checkTime(m);
    s = checkTime(s);
    document.getElementById('time').textContent = `${h}:${m}:${s}`;
    t = setTimeout(function () {
        startTime()
    }, 500);
}
startTime();
