var Config = new Object();
Config.closeKeys = [27];
function SendMessage(namespace, data) {
    $.post('https://MJ-Animal/' + namespace, JSON.stringify(data));
}

$(function() {
    closemenu = function() {
        $('.container').fadeOut();

        SendMessage("CloseMenu", {});
    }

    $(document).ready(function() {
        $("body").on("keyup", function(key) {
            if (Config.closeKeys.includes(key.which)) {
                closemenu();
            }
        });
    });

    window.addEventListener('message', function(event) {
        if (event.data.action == 'OpenMenu') {
            $('.container').fadeIn();
            $('#animalcount').html(event.data.AnimalCount);
            $('#price').html(event.data.AnimalPrice + "$");
            document.getElementById("AnimalFeed").src = `./img/${event.data.AnimalFeed}.png`;
        } else if (event.data.action == 'UpdateStatus') {
            let AnimalNumber = event.data.AnimalNumber;
            var perc = Math.round((event.data.AnimalAge / event.data.AnimalMaxAge) * 100);
            $(`[data-animalload="${AnimalNumber}"]`).css("width", + perc +"%");
        } else if (event.data.action == 'UpdateHungry') {
            let AnimalNumber = event.data.AnimalNumber;
            $(`[data-animalstatus="${AnimalNumber}"]`).html(`<i class="fa-solid fa-carrot"></i>`);
            document.querySelector(`[data-animalicon="${AnimalNumber}"]`).setAttribute("onclick", `FeedAnimal('${AnimalNumber}')`);
    
            // เพิ่มอนิเมชั่นซูมเข้าซูมออก
            document.getElementById('AnimalFeed').classList.add('zoom-animation');
            setTimeout(() => showPetAlert("hungry", event.data.AnimalFeed), 10000); // แจ้งเตือนหิวหลัง 8 วิ
        } else if (event.data.action == 'UpdateFeedAnimal') {
            let AnimalNumber = event.data.AnimalNumber;
            $(`[data-animalstatus="${AnimalNumber}"]`).html(`
                <div class="loading-icon">
                    <div class="line"></div>
                    <div class="line"></div>
                    <div class="line"></div>
                </div>
            `);
            document.querySelector(`[data-animalicon="${AnimalNumber}"]`).removeAttribute("onclick");
            // ลบอนิเมชั่น
            document.getElementById('AnimalFeed').classList.remove('zoom-animation');
        } else if (event.data.action == 'UpdateMaxAge') {
            let AnimalNumber = event.data.AnimalNumber;
            $(`[data-animalstatus="${AnimalNumber}"]`).html(`<i class="fa-solid fa-heart" style="color: #f2002d;"></i>`);
            document.querySelector(`[data-animalicon="${AnimalNumber}"]`).setAttribute("onclick", `GetAnimal('${AnimalNumber}')`);
        } else if (event.data.action == 'UpdateGetAnimal') {
            $('#animalcount').html(event.data.AnimalCount);
            let AnimalNumber = event.data.AnimalNumber;
            
            // รีเซ็ตสถานะของสัตว์
            $(`[data-animalstatus="${AnimalNumber}"]`).html(`<i class="fa-solid fa-bone" style="color: #ffffffd7;"></i>`);
            
            // รีเซ็ตไอคอนของสัตว์ที่ต้องการให้มีปุ่มซื้อใหม่
            $(`[data-animalicon="${AnimalNumber}"]`).html(`
                <i class="fa-solid fa-plus" 
                    style="font-size: 50px; color: green; cursor: pointer;" 
                    onclick="BuyAnimal('${AnimalNumber}')">
                </i>
            `); 

            // รีเซ็ตความคืบหน้าของการโหลด
            $(`[data-animalload="${AnimalNumber}"]`).css("width", "0%");

            // รีเซ็ตการคลิกปุ่ม (เพื่อให้สามารถซื้อสัตว์ได้ใหม่)
            document.querySelector(`[data-animalicon="${AnimalNumber}"]`).removeAttribute("onclick");
        } else if (event.data.action == 'UpdateAnimal') {
            $('#animalcount').html(event.data.AnimalCount);
            let AnimalNumber = event.data.AnimalNumber;
            let Model = event.data.Model;
            $(`[data-animalstatus="${AnimalNumber}"]`).html(`
                <div class="loading-icon">
                    <div class="line"></div>
                    <div class="line"></div>
                    <div class="line"></div>
                </div>
            `);
            $(`[data-animalicon="${AnimalNumber}"]`).html(`
                <img id="animal" src="./img/${Model}.png">
                <i class="fa-solid fa-trash delete-btn" onclick="RemoveAnimal('${AnimalNumber}')"></i>
            `);            
                     
            document.querySelector(`[data-animalicon="${AnimalNumber}"]`).removeAttribute("onclick");
            $(`[data-animalload="${AnimalNumber}"]`).css("width", "0%");
        }
    })
})

function PlaySounds(name) {
    var sound = new Audio(`sounds/` + name + `.mp3`);
    sound.volume = 0.5;
    sound.play();
}

function BuyAnimal(AnimalNumber){
    PlaySounds("click")
    SendMessage("BuyAnimal", {
        AnimalNumber: AnimalNumber,
    });
}

function RemoveAnimal(AnimalNumber) {
    PlaySounds("click");
    
    SendMessage("RemoveAnimal", {
        AnimalNumber: AnimalNumber,
    });
}

function FeedAnimal(AnimalNumber){
    PlaySounds("click")
    SendMessage("FeedAnimal", {
        AnimalNumber: AnimalNumber,
    });
}

function GetAnimal(AnimalNumber){
    PlaySounds("click")
    SendMessage("GetAnimal", {
        AnimalNumber: AnimalNumber,
    });
}

function showPetAlert(type,Feed) {
    let alertBox = document.getElementById("pet-alert");
    let alertImg = document.getElementById("pet-alert-img");
    let alertText = document.getElementById("pet-alert-text");

    if (type === "hungry") {
        alertImg.src = `./img/${Feed}.png`;  // เปลี่ยนรูปภาพแจ้งเตือน
        alertText.innerText = "สัตว์เลี้ยงของคุณหิวแล้ว!";
    } else if (type === "sell") {
        alertImg.src = `./img/${Feed}.png`;
        alertText.innerText = "สัตว์เลี้ยงของคุณถูกขายแล้ว!";
    }

    alertBox.style.display = "flex";

    setTimeout(() => {
        alertBox.style.display = "none";
    }, 5000); // ซ่อนแจ้งเตือนหลัง 1000 วินาที
}