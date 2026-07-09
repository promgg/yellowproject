
Config = {}
Config["base_key"] = 0x8AAA0AD4 -- ปุ่มหลักในการใช้ร่วมกับปุ่มตัวเลข เช่น ALT + 1
Config["base_key_text"] = "<b>ALT</b>" -- ชื่อปุ่มที่แสดงในแจ้งเตือน
Config["duration"] = 15 -- ระยะเวลาที่จะตอบรับ
Config["red_radius"] = 60.0 -- ขนาดของวงที่จะขึ้นบนแมพ เมื่อมีการแจ้งเตือน
Config["Wait"] = 120  -- ระยะเวลาที่วงจะหาย
Config['Route'] = 10  -- ระยะเมื่อเข้าไปใกล้จุดBlipแล้วเส้นทางนำทางจะหายไป

Config["Job"] = 'police'  -- หน่วยงานอะไร
Config['ชื่อจุดบนแมพ'] = 'Player'
Config['ไอคอนบนแมพ'] = 1481032477
Config['ขนาดไอคอน'] = 0.9
Config['สีไอคอน'] = 'BLIP_MODIFIER_AREA_OUT_OF_BOUNDS'

Config['playsound'] = true 
Config["alert_position"] = "bottomCenter"

Config["translate"] = {
	title = "",
	male = "<span  style=\"color:orange;\">ชาย</span>",
	female = "<span  style=\"color:orange;\">หญิง</span>",
	text = "<span style=\"font-size:14px;color:black;\"><b>%s</b></span> <span style=\"color:black;\"><br><dd>📌</span> <span style=\"color:orange;\"><b>%s</b></span>",
	tip = "<span style=\"font-size:12px;color:black;\"><b> เพื่อรับงานนี้</b></span>",
	action_blackwork = "<dd><span style=\"font-size:17px;color:yellow;\">📢 แจ้งเตือน: พบกิจกรรมผิดกฎหมาย</span>",
}
