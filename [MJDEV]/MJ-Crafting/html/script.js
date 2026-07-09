$(document).ready(function() {
    window.addEventListener('message', function(event) {
        if (event.data.notification === 'notification') {
            $(".notification").fadeIn();
            $(".notification").html(' <div class="notification-box"> <div class="notification-box-title"> <div class="notification-box-text-head"> การแจ้งเตือน </div><div class="notification-box-text-sub"> ' + event.data.text + ' </div></div><button class="notification-box-button">รับทราบ</button> </div>')
            $('.notification-box-button').click(function() {
                $(".notification").hide();
            });
        }

        if (event.data.acton === 'closemenus') {
            $(".ui").hide();
            $(".notification").hide();
            $(".menu").hide();
        } else if (event.data.acton === 'openmenu') {
            let number = 1
            let category = 1

            if (event.data.slesc === 'choose') {
                $(".ui").show();
            } else {
                $(".ui").fadeIn();
            }

            if (event.data.category >= 1) {
                category = event.data.category
            }

            if (event.data.number >= 1) {
                number = event.data.number
            }

            $(".craft").show();
            
            // $(".loading").show();
            // $(".loading").html('<div class="spinner spinner--steps icon-spinner"></div>')

            $(".menu").show();
            $(".menu").html('<div class="headertoptext"><i class="fad fa-list-alt"></i> Crafting Table</div>'+
            '<div class="header-menu"> <div class="menu-data-type"></div> </div> ' + 
            '<div class ="all">'+
            '<div class="menu-listitem"> <div  class="headeritem"><i class="fad fa-box-open"></i> รายชื่อไอเทม</div><div id="box-list-item"> </div></div> '+
            '<div class="left">'+
            '<div class ="topleft"><div class="data-item-name"></div>'+
            '<div class="timerequired">เวลาในการคราฟ : 10 วิ</div></div>'+
            '<div class ="bottomleft"><div class="menu-data"></div></div>'+
            '<div class="bottom"><div class="menu-crafe-amont"></div> <button class="menu-crafe-botton"></button> <div class="moneycash"><span class="box-item-money"></span></div></div>'+
            '</div>')


            $(".menu-crafe-amont").html(' จำนวน : <div class="craft-button-minus">-</div><input id="unmber" type="number" class="craft-info-number" min="1" max="100" value="' + number + '"> <div class="craft-button-plus" >+</div>');
            $(".menu-crafe-botton").html('<span class="craft-submit"><i class="fas fa-check-circle"></i> CRAFT</span>')

            $('.craft-submit').click(function() {
                $.post("http://MJ-Crafting/Crafting", JSON.stringify({
                    data: $("#unmber").val()
                }));
            });

            $("#unmber").keyup(function() {
                var precio = $("#unmber").val();
                if (precio > 100) {
                    precio = 100
                }

                if (type == "item_weapon") {
                    precio = 1
                }

                $("#unmber").val(precio);
                $.post("http://MJ-Crafting/SetCount", JSON.stringify({
                    number: precio
                }));
            });


            $(".craft-button-minus").on("click", function() {
                var $button = $(this);
                var oldValue = $button.parent().find("input").val();
                if ($button.text() == "+") {
                    var newVal = parseFloat(oldValue) + 1;
                } else {
                    // Don't allow decrementing below zero
                    if (oldValue > 0) {
                        var newVal = parseFloat(oldValue) - 1;
                    } else {
                        newVal = 1;
                    }
                }
                if (type == "item_weapon") {
                    newVal = 1
                }
                $button.parent().find("input").val(newVal);
                $.post("http://MJ-Crafting/SetCount", JSON.stringify({
                    number: newVal
                }));
            });

            $(".craft-button-plus").on("click", function() {
                var $button = $(this);
                var oldValue = $button.parent().find("input").val();
                if ($button.text() == "+") {
                    var newVal = parseFloat(oldValue) + 1;
                } else {
                    // Don't allow decrementing below zero
                    if (oldValue > 0) {
                        var newVal = parseFloat(oldValue) - 1;
                    } else {
                        newVal = 1;
                    }
                }
                if (type == "item_weapon") {
                    newVal = 1
                }
                $button.parent().find("input").val(newVal);
                $.post("http://MJ-Crafting/SetCount", JSON.stringify({
                    number: newVal
                }));
            });
            
            $(".menu-data-type").html("");

            $.each(event.data.datatype, function(index, data) {
                if (data.Category == category) {
                    $(".menu-data-type").append(' <div class="data-item-type-name"><div id="box-type-data-' + index + '" class="data-box-type-name-atv"><div class="data-box-text-name"> ' + data.categoryname + ' </div></div></div>');
                } else {
                    $(".menu-data-type").append(' <div class="data-item-type-name"><div id="box-type-data-' + index + '" class="data-box-type-name"><div class="data-box-text-name"> ' + data.categoryname + ' </div></div></div>');

                }
                $('#box-type-data-' + index).data('type-data', data);
            });

            $('.data-box-type-name').click(function() {
                category = $(this).data("type-data").Category
                $.post("http://MJ-Crafting/ChooseType", JSON.stringify({
                    category: category,
                }));
            });

            $("#box-list-item").html("");

            $.each(event.data.data, function(index, data) {
                if (data.Category == category) {
                    $("#box-list-item").append('<div id="box-list-item-data-' + index + '" class="box-item"><div class="box-item-image"><div class="item" style = "background-image: url(\'nui://vorp_inventory/html/img/items/' + data.item + '.png\')" ></div></div><div class="box-item-name">' + data.label + '</div></div>')

                    if (data.status == true) {
                        type = data.type

                        if (data.type == "item_weapon") {
                            number = 1
                            $("#unmber").val(number)
                        }

                        if (data.equipment !== undefined) {
                            $(".menu-data").html('<div></div><div class="data-item-required"> <i class="fad fa-align-left"></i>ไอเทมที่ต้องการ</div><div class="box-item-weapon"></div><div class="data-item-required"> ส่วนประกอบ</div><div class="box-item-required"></div><div class="data-item-required"><i class="fad fa-gifts"></i> อุปกรณ์ที่ต้องใช้</div><div class="box-item-equipent"></div>');
                        } else if (data.equipment == undefined) {
                            $(".menu-data").html('<div></div><div class="data-item-required"> <i class="fad fa-align-left"></i>ไอเทมที่ต้องการ</div><div class="box-item-weapon"></div><div class="data-item-required"> ส่วนประกอบ</div><div class="box-item-required"></div>');
                        } else if (data.equipment !== undefined) {
                            $(".menu-data").html('<div></div><div class="data-item-required">ส่วนประกอบ</div><div class="box-item-required"></div><div class="data-item-required2"> อุปกรณ์ที่ต้องใช้  <div class="box-item-equipent"></div></div>');
                        } else {
                            $(".menu-data").html('<div></div></span><div class="data-item-required"> ส่วนประกอบ</div><div class="box-item-required"></div>');
                        }

                        $('#box-list-item-data-' + index).addClass('box-item-active');

                        $(".data-item-name").html('<div class="data-item-name-font"> ' + data.label + '</div>');

                        if (data.cost !== undefined) {
                            $(".box-item-money").html("");
                            $.each(data.cost, function(index, data) {
                                $(".box-item-money").append('<div class="box-item-required-list-money"></div><div class="box-text-required-list-money"><i class="fad fa-coins"></i><div class="item-required-img" style = "background-image: url(\'nui://vorp_inventory/html/img/items/' + data.name + '.png\')"> </div> <span class="money">' + data.label + ' x ' + formatMoney(data.amox * number) + '</span></div></div>')
                            });
                        }

                        if (data.blueprint !== undefined) {
                            $(".box-item-required").html("");
                            $.each(data.blueprint, function(index, data) {
                                $(".box-item-required").append('<div class="box-item-required-list"><div class="box-item-required-img"><div class="item-required-img" style = "background-image: url(\'nui://vorp_inventory/html/img/items/' + data.name + '.png\')"> </div></div><div class="box-text-required-list"><div class="">' + data.label + ' <div class="numbercount">x ' + data.amox * number + '</div></div></div></div>')
                            });
                        }

                        if (data.equipment !== undefined) {
                            $(".box-item-equipent").html("");
                            $.each(data.equipment, function(index, data) {
                                $(".box-item-equipent").append('<div class="box-item-required-list"><div class="box-item-required-img"><div class="item-required-img" style = "background-image: url(\'nui://vorp_inventory/html/img/items/' + data.name + '.png\')"> </div></div><div class="box-text-required-list"><div class="item-required">' + data.label + '</div></div></div>')
                            });
                        }

                        $(".box-item-receive").html("");
                        $(".box-item-receive").append('<div class="box-item-required-list"><div class="box-item-required-img"><div class="item-required-img" style = "background-image: url(\'nui://vorp_inventory/html/img/items/' + data.item + '.png\')"> </div></div><div class="box-text-required-list"><div class="item-required">' + data.label + '</div></div></div>')

                    }

                    $('#box-list-item-data-' + index).data('item-data', data);
                }
            });

            $('.box-item').click(function() {
                $.post("http://MJ-Crafting/Choose", JSON.stringify({
                    data: $(this).data("item-data"),
                    number: number
                }));
            });


        } else if (event.data.acton === 'Sound') {

            let audioPlayer = null;

            if (event.data.transactionType == "playSound") {

                if (audioPlayer != null) {
                    audioPlayer.pause();
                }

                audioPlayer = new Audio("./sounds/" + event.data.transactionFile + ".mp3");
                audioPlayer.volume = event.data.transactionVolume;
                audioPlayer.play();

            }

            if (event.data.transactionType == "playSoundFlash") {

                if (audioPlayer != null) {
                    audioPlayer.pause();
                }

                audioPlayer = new Audio("./sounds/" + event.data.transactionFile + ".mp3");
                audioPlayer.play();
                audioPlayer.volume = event.data.transactionVolume;

                var start = (event.data.transactionVolume * 100)
                setTimeout(() => {
                    var vol = event.data.transactionVolume
                    var i = start;
                    var interval = setInterval(function() {
                        if (i > 0) {
                            if (vol <= 0.1) {
                                vol = 0.1
                            } else {
                                vol -= 0.01
                            }
                            audioPlayer.volume = vol
                            i--;
                        } else {
                            clearInterval(interval);
                        }
                    }, event.data.transactionTime);
                }, event.data.transactionHold)
            }//item-required
        }
    })
})

document.onkeyup = function(data) {
    if (data.which == 27) {
        $(".ui").hide();
        $(".notification").hide();
        $(".menu").hide();
        $.post("http://MJ-Crafting/Close", JSON.stringify({}));
    }
}

function formatMoney(n, c, d, t) {
    var c = isNaN(c = Math.abs(c)) ? 2 : c,
        d = d == undefined ? "." : d,
        t = t == undefined ? "," : t,
        s = n < 0 ? "-" : "",
        i = String(parseInt(n = Math.abs(Number(n) || 0).toFixed(c))),
        j = (j = i.length) > 3 ? j % 3 : 0;

    return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t);
};
