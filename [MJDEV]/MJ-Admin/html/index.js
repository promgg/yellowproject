var id = 0,
	playerData = [];
$(function () {
	let e = { user: '<i class="fas fa-user"></i>', mod: '<i class="fas fa-user-gear"></i>', admin: '<i class="fas fa-user-shield"></i>', superadmin: '<i class="fas fa-crown"></i>' };

	function a(e) { e ? $("#container").show() : ($("#container, #actions, #items, #inputmanager, #bans").hide(), $(".server").fadeOut(), $("#server").show(), i(!0), id = 0) }

	function t(e, a, t, n) { i(), $("#inputmanager").attr("action", n).slideDown(), $("#inputtitle").html(e), $("#datainput").val("").attr("placeholder", a).attr("type", t) }

	function i(e, a, t) {
		if (e) {
			if ($(".back").fadeOut(), $("#inputmanager").is(":Visible")) return void $("#inputmanager").slideUp();
			if ($("#confirmaction").is(":Visible")) return void $("#confirmaction").slideUp();
			let e = $("#back").attr("href"),
				a = $("#back").attr("current-window");
			a && ($(e).fadeIn(), $(a).hide(), $("#back").removeAttr("current-window"))
		} else a && t && ($(t).hide(), $(a).fadeIn(), $("#back").attr("current-window", a).attr("href", t)), $(".back").fadeIn()
	}
	window.addEventListener("message", function (t) {
		let i = t.data;
		if ("MJDEV-ADMIN" === i.type) 1 == i.status ? a(!0) : a(!1);

		else if ("MJ-Data" === i.type) {
			$("#listname").html("");
			let a = i.data,
				t = "";
			$.each(a, function (a, i) { $(".online").html(i.online); $("#listname").append(`<div class = "item" data-playerid=${i.playerid} data-playername=${i.rpname}><span class="playerid"> ${i.playerid}</span><span class="group"> ${e[i.group]}</span><span>${t} ${i.rpname} </span></div>`), playerData[i.playerid] = i })
			// $.each(a, function (a, x) {$("#listname").append(`<div class = "item" data-playerid=${x.playerid} data-playername=${x.name}><span class="playerid"> ${x.playerid}</span><span>${t} ${x.name}</span></div>`), playerData[i.playerid] = i })
		} else if ("bans" === i.type) {
			$("#banlist").html("");
			let e, a = i.banlist;
			$.each(a, function (a, t) { e = 0 == t.time ? "Permanently" : t.time < 0 ? "หมดอายุ" : "แบน " + t.time + " นาที", $("#banlist").append(`<div class = "banitem" data-license=${t.license}><span class="bannedplayer">${t.name}</span><span class="time">${e}</span><span class="reason">${t.reason}</span></div>`) })
		} else if ("items" === i.type) {
			$("#itemlist, #itemlistall, #weaponlist, #vehiclelist").html(""); // ล้างก่อน

			// 🔹 แสดงไอเทม
			$.each(i.itemslist, function (index, a) {
			$("#itemlist, #itemlistall").append(`
				<div id="inventoryitemwrap">
				<div class="inventoryitem" 
					data-itemname="${a.item}" 
					data-name="${a.item}" 
					data-label="${a.label}">
					<div class="img"><img src="nui://vorp_inventory/html/img/items//${a.item}.png" width="120" height="110" /></div>
					<div class="name">${a.label}</div>
				</div>
				</div>
			`);
			});

			// 🔹 แสดงอาวุธ
			$.each(i.weaponlist, function (index, w) {
			$("#weaponlist").append(`
				<div id="inventoryitemwrap">
				<div class="inventoryitem" 
					data-weaponname="${w.name}" 
					data-name="${w.name}" 
					data-label="${w.label || w.name}">
					<div class="img"><img src="nui://vorp_inventory/html/img/items//${w.name}.png" width="120" height="110" /></div>
					<div class="name">${w.label || w.name}</div>
				</div>
				</div>
			`);
			});

			// 🔹 แสดงยานพาหนะ
			$.each(i.vehiclelist, function (index, v) {
			$("#vehiclelist").append(`
				<div id="inventoryitemwrap">
				<div class="inventoryitem" 
					data-vehiclename="${v.model}" 
					data-name="${v.model}" 
					data-label="${v.label}">
					<div class="img"><i class="fas fa-horse centered" style="color:#fff;font-size:48px;"></i></div>
					<div class="name">${v.label}</div>
				</div>
				</div>
			`);
			});

			// 🔹 แสดง Job (dropdown)
			$("#jobs").html("");
			const rankMap = {};
			$.each(i.joblist, function (index, job) {
				$("#jobs").append(`<option value="${job.name}">${job.label}</option>`);
				rankMap[job.name] = job.ranks;
			});

			$("#jobs").on("change", function () {
			const jobName = $(this).val();
			$("#ranks").html("");
			if (rankMap[jobName]) {
				$.each(rankMap[jobName], function (i, r) {
					$("#ranks").append(`<option value="${r.grade}">${r.label}</option>`);
				});
			}

			// เรียก trigger change เพื่อแสดงตำแหน่งของ job แรก
            $("#jobs").trigger("change");
		});

		} else if ("coords" == i.type) {
			let e = i.coordData;
			$(".coords").attr("coordData", e.x + ", " + e.y + ", " + e.z).html("<b>X: " + e.x.toFixed(2) + " Y: " + e.y.toFixed(2) + " Z: " + e.z.toFixed(2) + "</b>")
		}
	}), $("body").on("input", "#search", function () {
		let e, a, t = $(this).val().toLowerCase();
		$(".item").each(function () { e = $(this).data("playername").toLowerCase(), a = parseInt($(this).data("playerid")), parseInt(t) != a ? ($(this).hide(), e.indexOf(t) < 0 ? $(this).hide() : $(this).show()) : $(this).show() })
	}), $("#confirminput").click(function () {
		let e = $("#datainput").val(),
			a = $("#inputmanager").attr("action");
		$.post(`https://${GetParentResourceName()}/` + a, JSON.stringify({ playerid: id, inputData: e })), i(!0)
	}), $("#confirm").click(function () {
		let e = $("#confirmaction").attr("data"),
			a = $("#confirmaction").attr("action");
		$.post(`https://${GetParentResourceName()}/` + a, JSON.stringify({ playerid: id, confirmoutput: e })), i(!0)
	}), $("body").on("click", "#cancelinput", function () { i(!0) }), $("body").on("click", ".server", function () { i(!0), $("#actions, #items, #bans, .server").hide(), $("#server").show(), $(".item").removeClass("selected") }), $("body").on("click", ".item", function () {
		$(".item").removeClass("selected"), $(this).addClass("selected"),
			function (e) {
				i(!0), id = e, $("#actions").fadeIn(), $(".playername").html(playerData[e].name), $("#server").hide(), $(".server").show();
				var a = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });
				$('.data[data-name="name"]').html(playerData[e].rpname), $('.data[data-name="license"]').html(playerData[e].identifier), $('.data[data-name="discord"]').html(playerData[e].discord), $('.data[data-name="money"]').html(a.format(Math.floor(playerData[e].cash)) + " (เงินในกระเป๋า) | " + a.format(Math.floor(playerData[e].bank)) + " (ทองคำ)"), $('.data[data-name="phone"]').html(playerData[e].phone), $('.data[data-name="jobs"]').html(playerData[e].job)
				// $('.data[data-name="name"]').html(playerData[e].rpname), $('.data[data-name="job"]').html(playerData[e].jobs), $('.data[data-name="license"]').html(playerData[e].identifier), $('.data[data-name="money"]').html(a.format(playerData[e].cash) + " (เงินในกระเป๋า) | " + a.format(playerData[e].bank) + " (ทอง)")
			}($(this).data("playerid"))
	}), $("body").on("click", ".banitem", function () {
		let e = $(this).data("license"),
			a = $(this).find(".bannedplayer").text();
		var t, n, s;
		t = "unban", n = e, s = "คุณแน่ใจหรือว่าต้องการยกเลิกการแบน " + a + "?", i(), $("#confirmaction").attr("action", t).attr("data", n).slideDown(), $("#confirmaction #inputtitle").html(s)
	}), $("#items").on("click", ".inventoryitem", function () {
		let e = $(this).data("itemname"),
			a = parseInt($("#qty").val());
		$.post(`https://${GetParentResourceName()}/giveitem`, JSON.stringify({ playerid: id, name: e, amount: a }))
	}), $("#itemsall").on("click", ".inventoryitem", function () {
		let e = $(this).data("itemname"),
			a = parseInt($("#qty").val());
		$.post(`https://${GetParentResourceName()}/giveitemall`, JSON.stringify({ name: e, amount: a }))
	}), $("#weapons").on("click", ".inventoryitem", function () {
		let e = $(this).data("weaponname");
		ab = parseInt($("#qty2").val());
		$.post(`https://${GetParentResourceName()}/weapon`, JSON.stringify({ playerid: id, weapon: e, amount: ab }))
	}), $("#vehicles").on("click", ".inventoryitem", function () {
		let e = $(this).data("vehiclename");
		$.post(`https://${GetParentResourceName()}/spawnvehicle`, JSON.stringify({ model: e }))
	}), $("body").on("click", ".btn", function () {
		let e, a, n, s = $(this).data("action");
		switch (s) {
			case "kick":
				t(a = "เตะ " + playerData[id].name + "", e = "ใส่เหตุผล", n = "text", s);
				break;

			case "kickall":
				t(a = "เตะ " + 'ทุกคน' + "", e = "ใส่เหตุผล", n = "text", s);
				break;

			case "addCash":
				t(a = "ให้เงินสด : " + playerData[id].name, e = "ใส่จำนวนเงิน", n = "number", s);
				break;

			case "anmid":
				t(a = "ประกาศถึง : " + playerData[id].name, e = "ใส่ข้อความ", n = "text", s);
				break;

			case "anmall":
				t(a = "ประกาศ " + 'ทุกคน' + "", e = "ใส่ข้อความ", n = "text", s);
				break;

			case "setmodel":
				t(a = "เปลี่ยนโมเดล : " + playerData[id].name, e = "ใส่ชื่อโมเดล", n = "text", s);
				break;

			case "jail":
				t(a = "เจล : " + playerData[id].name, e = "ใส่จำนวนเวลา", n = "number", s);
				break

			case "cjail":
				t(a = "ลดเวลาเจล : " + playerData[id].name, e = "ใส่จำนวนที่จะลดเวลา", n = "number", s);
				break;

			case "killall":
				t(a = "ฆ่า : " + 'ทุกคน', e = "พิมพ์ 1 เพื่อตกลง", n = "text", s);
				break;
			case "bringall":
				t(a = "ดึง : " + 'ทุกคน', e = "พิมพ์ 1 เพื่อตกลง", n = "text", s);
				break;

			case "healall":
				t(a = "ฮิล : " + 'ทุกคน', e = "พิมพ์ 1 เพื่อตกลง", n = "text", s);
				break;

			case "foodall":
				t(a = "รีหลอดอาหาร : " + 'ทุกคน', e = "พิมพ์ 1 เพื่อตกลง", n = "text", s);
				break;

			case "reviveall":
				t(a = "ชุบ : " + 'ทุกคน', e = "พิมพ์ 1 เพื่อตกลง", n = "text", s);
				break;

			case "addBank":
				t(a = "ให้ทอง : " + playerData[id].name, e = "ใส่จำนวน", n = "number", s);
				break;
			case "announce":
				t(a = "ประกาศช่องแชทของคุณ", e = "ใส่ข้อความ", n = "text", s);
				break;
			case "delcarall":
				t(a = "เกวียนทั้งหมด : " + 'ทุกคน', e = "พิมพ์ 1 เพื่อตกลง", n = "text", s);
				break;
			case "promote":
				let o = $(this).data("level");
				$.post(`https://${GetParentResourceName()}/promote`, JSON.stringify({ playerid: id, level: o }));
				break;
			case "giveWeapon":
				i(!1, "#weapons", "#actions");
				break;
			case "giveItem":
				i(!1, "#items", "#actions");
				break;
			case "spawnHorse":
				t(a = "ชื่อโมเดล : ", e = "ใส่ชื่อโมเดล", n = "text", s);
				break;
			case "giveitemsall":
				i(!1, "#itemsall", "#server");
				break;
			case "spawnVehicle":
				i(!1, "#vehicles", "#server");
				break;
			case "inventory":
				$.post(`https://${GetParentResourceName()}/inventory`, JSON.stringify({ playerid: id }));
				break;
			case "ban":
				t(a = "ตั้งเวลาแบน (นาที)", e = "ใส่เวลาการแบน", n = "number", s);
				break;
			case "permaban":
				t(a = "แบน " + playerData[id].name + " ด้วยเหตุผล", e = "เหตุผล", n = "text", s);
				break;
			case "banlist":
				i(!1, "#bans", "#server");
				break;
			case "setJob":
				let r = $("select#jobs option").filter(":selected").val(); // job value
				let rLabel = $("select#jobs option").filter(":selected").text(); // job label
				let l = $("select#ranks option").filter(":selected").val(); // rank value
				let lLabel = $("select#ranks option").filter(":selected").text(); // rank label
				$.post(`https://${GetParentResourceName()}/setJob`, JSON.stringify({ playerid: id, job: r, rank: l, label: lLabel }));
				break;
			case "setTime":
				t(a = "เปลี่ยนเวลาในเซิร์ฟเวอร์ <br /> (24 เวลาชั่วโมง)", e = "12:00", n = "time", s);
				break;
			case "changeWeather":
				let d = $("select#weatherTypes option").filter(":selected").val();
				$.post(`https://${GetParentResourceName()}/changeWeather`, JSON.stringify({ playerid: id, weather: d }));
				break;
			default:
				$.post(`https://${GetParentResourceName()}/` + s, JSON.stringify({ playerid: id }))
		}
	}), $("#back").on("click", function () { i(!0) }), $("#clipboard").click(function () {
		let e = $(".coords").attr("coordData");
		let h = $(".head").attr("heading");
		var a = $("<input>");
		$("body").append(a), a.val(e).select(), document.execCommand("copy"), a.remove()
		$("body").append(a), a.val(h).select(), document.execCommand("copy"), a.remove()
	});

	$("#inner").append(""), document.onkeyup = function (e) { if (27 == e.which) return $.post(`https://${GetParentResourceName()}/exit`, JSON.stringify({})), void a(!1) }, $("#tpwp-button").click(function () { $.post(`https://${GetParentResourceName()}/tp-wp`) }), $("header").on("mousedown", function (e) {
		var a = $("#container").addClass("drag").css("cursor", "move");
		height = a.outerHeight(), width = a.outerWidth(), ypos = a.offset().top + height - e.pageY, xpos = a.offset().left + width - e.pageX, $(document.body).on("mousemove", function (e) {
			var t = e.pageY + ypos - height,
				i = e.pageX + xpos - width;
			a.hasClass("drag") && a.offset({ top: t, left: i })
		}).on("mouseup", function (e) { a.removeClass("drag") })
	})
});

$(document).ready(function () {
	$(".itemSearch, .itemSearchall").on("keyup", function () {
		var value = $(this).val().toLowerCase().trim();
		var container = $(this).closest("div[id^='items']");
		var itemList = container.find("div[id^='itemlist']");
		var allItems = container.find(".inventoryitem");
		var matchedItems = [];

		allItems.show();
		itemList.find('.not-found').remove();

		if (value === "") {
			itemList.prepend(allItems);
			return;
		}

		allItems.each(function () {
			var name = $(this).data("name") || $(this).attr("data-name") || $(this).text();
			var label = $(this).data("label") || $(this).attr("data-label") || "";
			var combinedText = (name + " " + label + " " + $(this).text()).toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");

			var match = combinedText.indexOf(value) > -1;
			$(this).toggle(match);

			if (match) {
				matchedItems.push(this);
			}
		});

		if (matchedItems.length > 0) {
			itemList.prepend(matchedItems);
		} else {
			itemList.append('<div class="not-found" style="color:red;text-align:center;padding:10px;">ไม่พบไอเทม</div>');
		}
	});
});

function clicks() {
	var sound = new Audio('click.mp3');
	sound.volume = 0.5;
	sound.play();
}

$(function () {
	$("#tool").click(function () {
		$("#rightbarr").toggle();
		clicks()
	});
});
