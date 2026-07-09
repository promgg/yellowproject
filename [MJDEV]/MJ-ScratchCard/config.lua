Config = {}

Config['imgPath'] = 'nui://vorp_inventory/html/img/items/'
-- กำหนดรายการรางวัลที่สามารถสุ่มได้
Config.Rewards = {
    {
        useitem = 'scratch_ticket', -- ใช้ไอเทม scratch_ticket
        rewards = {
            {
                name = "เงินสด",
                type = "money",
                itemName = "money",
                amountMin = 500,
                amountMax = 1000,
                chance = 10
            },
            {
                name = "ทอง",
                type = "gold",
                itemName = "gold",
                amountMin = 500,
                amountMax = 1000,
                chance = 5
            },
            {
                name = "hotdog",
                type = "item",
                itemName = "hotdog",
                amountMin = 1,
                amountMax = 3,
                chance = 5
            },
            {
                name = "น้ำ",
                type = "item",
                itemName = "water",
                amountMin = 1,
                amountMax = 1,
                chance = 20
            },
            {
                name = "iron",
                type = "item",
                itemName = "iron",
                amountMin = 1,
                amountMax = 1,
                chance = 10
            },
            {
                name = "copper",
                type = "item",
                itemName = "copper",
                amountMin = 1,
                amountMax = 1,
                chance = 15
            },
            {
                name = "stone",
                type = "item",
                itemName = "stone",
                amountMin = 1,
                amountMax = 1,
                chance = 10
            },
            {
                name = "sap",
                type = "item",
                itemName = "sap",
                amountMin = 1,
                amountMax = 1,
                chance = 5
            },
            {
                name = "honey",
                type = "item",
                itemName = "honey",
                amountMin = 1,
                amountMax = 1,
                chance = 5
            },
            {
                name = "BearC",
                type = "item",
                itemName = "bearc",
                amountMin = 1,
                amountMax = 1,
                chance = 10
            },
            {
                name = "wood",
                type = "item",
                itemName = "wood",
                amountMin = 1,
                amountMax = 1,
                chance = 5
            },
            {
                name = "hwood",
                type = "item",
                itemName = "hwood",
                amountMin = 1,
                amountMax = 1,
                chance = 3
            },
            {
                name = "Bear Bench",
                type = "item",
                itemName = "rubber",
                amountMin = 1,
                amountMax = 1,
                chance = 2
            },
            {
                name = "Beaver Tail",
                type = "item",
                itemName = "fibers",
                amountMin = 1,
                amountMax = 1,
                chance = 5
            },
            {
                name = "Biscuit Box",
                type = "item",
                itemName = "pulp",
                amountMin = 1,
                amountMax = 3,
                chance = 7
            }
        }
    },    
    {
        useitem = 'scratch_ticket2', -- ใช้ไอเทม scratch_ticket2
        rewards = {
            {
                name = "เงินสด",
                type = "money",
                amountMin = 500,
                amountMax = 1000,
                chance = 50
            },
            {
                name = "hotdog",
                type = "item",
                itemName = "hotdog",
                amountMin = 1,
                amountMax = 3,
                chance = 30
            },
            {
                name = "กาแฟ",
                type = "item",
                itemName = "coffeebeans",
                amountMin = 1,
                amountMax = 1,
                chance = 20
            }
        }
    }
}

Config.OnlyOneReward = true -- รับรางวัลแค่ 1 อย่างต่อการขูด 1 ครั้ง
Config.AutoScratch = true -- กำหนดให้รางวัลสุ่มอัตโนมัติเมื่อกดใช้ไอเทม
