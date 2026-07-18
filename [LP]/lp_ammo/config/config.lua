Config = {}

Config.Debug = false
Config.NotifyDuration = 5000

Config.Locale = {
    ammoFull = 'กระสุนชนิดนี้เต็ม หรือพื้นที่ไม่พอสำหรับกระสุนทั้งกล่อง',
    useFailed = 'ไม่สามารถใช้กล่องกระสุนได้ กรุณาลองใหม่อีกครั้ง'
}

-- All values are server-owned. Never accept an ammo type or amount from a client.
-- `amount` is the number of rounds in one item; `max` is the allowed ammo cap.
Config.AmmoItems = {
    ammorepeaternormal = { ammoType = 'AMMO_REPEATER', amount = 100, max = 200 },
    ammorepeaterexpress = { ammoType = 'AMMO_REPEATER_EXPRESS', amount = 100, max = 200 },
    -- Legacy config granted 30 with a cap of 10, making this item impossible to use.
    ammorepeaterexplosive = { ammoType = 'AMMO_REPEATER_EXPRESS_EXPLOSIVE', amount = 5, max = 10 },
    ammorepeatervelocity = { ammoType = 'AMMO_REPEATER_HIGH_VELOCITY', amount = 100, max = 200 },
    ammorepeatersplitpoint = { ammoType = 'AMMO_REPEATER_SPLIT_POINT', amount = 50, max = 100 },

    ammorevolvernormal = { ammoType = 'AMMO_REVOLVER', amount = 100, max = 200 },
    ammorevolverexpress = { ammoType = 'AMMO_REVOLVER_EXPRESS', amount = 100, max = 200 },
    ammorevolverexplosive = { ammoType = 'AMMO_REVOLVER_EXPRESS_EXPLOSIVE', amount = 5, max = 30 },
    ammorevolvervelocity = { ammoType = 'AMMO_REVOLVER_HIGH_VELOCITY', amount = 100, max = 200 },
    ammorevolversplitpoint = { ammoType = 'AMMO_REVOLVER_SPLIT_POINT', amount = 50, max = 100 },

    ammoriflenormal = { ammoType = 'AMMO_RIFLE', amount = 100, max = 200 },
    ammoelephant = { ammoType = 'AMMO_RIFLE_ELEPHANT', amount = 10, max = 20 },
    ammorifleexpress = { ammoType = 'AMMO_RIFLE_EXPRESS', amount = 100, max = 200 },
    ammorifleexplosive = { ammoType = 'AMMO_RIFLE_EXPRESS_EXPLOSIVE', amount = 5, max = 10 },
    ammoriflevelocity = { ammoType = 'AMMO_RIFLE_HIGH_VELOCITY', amount = 100, max = 200 },
    ammoriflesplitpoint = { ammoType = 'AMMO_RIFLE_SPLIT_POINT', amount = 50, max = 100 },

    ammoshotgunincendiary = { ammoType = 'AMMO_SHOTGUN_BUCKSHOT_INCENDIARY', amount = 100, max = 200 },
    -- Correct canonical VORP ammo key; the legacy config used AMMO_SHOTGUN_EXPRESS_EXPLOSIVE.
    ammoshotgunexplosive = { ammoType = 'AMMO_SHOTGUN_SLUG_EXPLOSIVE', amount = 100, max = 200 },
    ammoshotgunnormal = { ammoType = 'AMMO_SHOTGUN', amount = 5, max = 10 },
    ammoshotgunslug = { ammoType = 'AMMO_SHOTGUN_SLUG', amount = 100, max = 200 },

    ammopistolnormal = { ammoType = 'AMMO_PISTOL', amount = 100, max = 200 },
    ammopistolexpress = { ammoType = 'AMMO_PISTOL_EXPRESS', amount = 100, max = 200 },
    ammopistolexplosive = { ammoType = 'AMMO_PISTOL_EXPRESS_EXPLOSIVE', amount = 5, max = 10 },
    ammopistolvelocity = { ammoType = 'AMMO_PISTOL_HIGH_VELOCITY', amount = 100, max = 200 },
    ammopistolsplitpoint = { ammoType = 'AMMO_PISTOL_SPLIT_POINT', amount = 50, max = 100 },

    ammoarrownormal = { ammoType = 'AMMO_ARROW', amount = 20, max = 40 },
    ammoarrowdynamite = { ammoType = 'AMMO_ARROW_DYNAMITE', amount = 4, max = 8 },
    ammoarrowfire = { ammoType = 'AMMO_ARROW_FIRE', amount = 4, max = 10 },
    ammoarrowimproved = { ammoType = 'AMMO_ARROW_IMPROVED', amount = 20, max = 40 },
    ammoarrowsmallgame = { ammoType = 'AMMO_ARROW_SMALL_GAME', amount = 20, max = 40 },
    ammoarrowpoison = { ammoType = 'AMMO_ARROW_POISON', amount = 10, max = 10 },

    ammovarmint = { ammoType = 'AMMO_22', amount = 50, max = 100 },
    ammovarminttranq = { ammoType = 'AMMO_22_TRANQUILIZER', amount = 100, max = 200 },

    ammoknives = { ammoType = 'AMMO_THROWING_KNIVES', amount = 3, max = 3 },
    ammotomahawk = { ammoType = 'AMMO_TOMAHAWK', amount = 3, max = 3 },
    ammopoisonbottle = { ammoType = 'AMMO_POISONBOTTLE', amount = 3, max = 3 },
    ammobolla = { ammoType = 'AMMO_BOLAS', amount = 3, max = 3 },
    ammodynamite = { ammoType = 'AMMO_DYNAMITE', amount = 3, max = 3 },
    ammovoldynamite = { ammoType = 'AMMO_DYNAMITE_VOLATILE', amount = 3, max = 3 },
    ammomolotov = { ammoType = 'AMMO_MOLOTOV', amount = 3, max = 3 },
    ammovolmolotov = { ammoType = 'AMMO_MOLOTOV_VOLATILE', amount = 3, max = 3 }
}
