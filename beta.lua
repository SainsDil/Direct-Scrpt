_G.FishItConfig = _G.FishItConfig or {
    ["Fishing"] = {
        ["Auto Perfect"] = false,
        ["Random Result"] = true,

        ["Auto Favorite"] = true,
        ["Auto Unfavorite"] = false,
        ["Fish Name"] = {
            "Sacred Guardian Squid",
            {Name = "Ruby", Variant = "Gemstone"},
            {Tier = "Mythic", Variant = "Stone"},
            {Tier = "Mythic", Variant = "Gold"},
            {Tier = "Mythic", Variant = "Ghost"},
            {Tier = "Mythic", Variant = "Radioactive"},
            {Tier = "Mythic", Variant = "Lightning"},
            {Tier = "Mythic", Variant = "Midnight"},
            {Tier = "Mythic", Variant = "Fairy Dust"},
            {Tier = "Mythic", Variant = "Gemstone"},
            {Tier = "Mythic", Variant = "Corrupt"},
            {Tier = "Mythic", Variant = "Frozen"},
            {Tier = "Mythic", Variant = "Galaxy"},
            {Tier = "Mythic", Variant = "Holographic"},
            {Tier = "Mythic", Variant = "Leviathan Rage"},
        },
        ["Auto Accept Trade"] = true,

        ["Auto Friend Request"] = true,
    },
    ["Auto Trade"] = {
        ["Enabled"] = true,
        ["Whitelist Username"] = {"DilInvent"},
        ["Category Fish"] = {
            "Secret",
            {Tier = "Mythic", Variant = "Stone"},
            {Tier = "Mythic", Variant = "Gold"},
            {Tier = "Mythic", Variant = "Ghost"},
            {Tier = "Mythic", Variant = "Radioactive"},
            {Tier = "Mythic", Variant = "Lightning"},
            {Tier = "Mythic", Variant = "Midnight"},
            {Tier = "Mythic", Variant = "Fairy Dust"},
            {Tier = "Mythic", Variant = "Gemstone"},
            {Tier = "Mythic", Variant = "Corrupt"},
            {Tier = "Mythic", Variant = "Frozen"},
            {Tier = "Mythic", Variant = "Galaxy"},
            {Tier = "Mythic", Variant = "Holographic"},
            {Tier = "Mythic", Variant = "Leviathan Rage"},
        },
        ["Fish Name"] = {
            {Name = "Ruby", Variant = "Gemstone"},
        },
        ["Item Name"] = {
            "Evolved Enchant Stone",
        },
    },
    ["Farm Coin Only"] = {
        ["Enabled"] = false, -- Farm coins only [ cant buy rod, bait, enchant, weather ]
        ["Target"] = 190000,
    },
    ["Selling"] = {
        ["Auto Sell"] = true,
        ["Auto Sell Threshold"] = "Mythic",
        ["Auto Sell Every"] = 100,
    },
    ["Doing Quest"] = {
        ["Auto Ghostfinn Rod"] = true,
        ["Auto Element Rod"] = true,
        ["Unlock Ancient Ruin"] = true,
        ["Allowed Sacrifice"] = {
            "Ghost Shark",
            "Cryoshade Glider",
            "Panther Eel",
            "Queen Crab",
            "King Crab",
            "Giant Squid",
            "Blob Shark",
            "Ghost Shark",
        },
        ["FARM_LOC_SECRET_SACRIFICE"] = "Treasure Room",

        ["Minimum Rod"] = "Astral Rod",
    },
    ["WebHook"] = {
        ["Link Webhook"] = "https://discord.com/api/webhooks/996054378861559899/_ZKaOOdIxArjew6ZsXS6h9QjLHvXer5_xUzyZTWqO2OF2yyodVSQ-_bD8jK_gCH8IyS5",
        ["Auto Sending"] = true,
        ["Category"] = {"Secret"},
        ["Link Webhook Quest Complete"] = "https://discord.com/api/webhooks/1025982687619584150/2h_1Q-Ut2L9RGlu9oDFwYbXigizoeXEPnzy0M4IUCkIESlLp3Nla-4z-aZpxju3MyGkz",
    },
    ["Weather"] = {
        ["Auto Buying"] = true,
        ["Minimum Rod"] = "Astral Rod",
        ["Weather List"] = {
            "Wind",
            "Cloudy",
            "Storm",
        },
    },
    ["Potions"] = {
        ["Auto Use"] = true,
        ["Minimum Rod"] = "Astral Rod",
    },
    ["Totems"] = {
        ["Auto Use"] = true,
        ["Minimum Rod"] = "Ghostfinn Rod",
        ["Buy List"] = {
            ["Mutation Totem"] = 24,
            "Mutation Totem",
        },
    },
    ["Event"] = {
        ["Start Farm"] = false,
        ["Minimum Rod"] = "Ghostfinn Rod",
        ["Event List"] = {
            "Ghost Shark Hunt",
            "Shark Hunt",
            ["Christmas Cave"] = false,
        },
    },
    ["Enchant"] = {
        ["Auto Enchant"] = true,
        ["Roll Enchant"] = true,
        ["Evolved Roll Enchant"] = true,
        ["Enchant List"] = {
            "Mutation Hunter III",
            "SECRET Hunter",
        },
        ["Second Enchant"] = true,
        ["Allowed Sacrifice"] = {
            "Cryoshade Glider",
            "Great Whale",
            "King Crab",
            "Queen Crab",
        },
        ["Second Enchant List"] = {
            "Cursed I",
        },
        ["Minimum Rod"] = "Ghostfinn Rod",
    },
    ["Bait List"] = {
        ["Auto Buying"] = true,
        ["Buy List"] = {
            "Midnight Bait",
            "Corrupt Bait",
            "Floral Bait",
            "Singularity Bait",
        },
        ["Endgame"] = "",
    },
    ["Rod List"] = {
        ["Auto Buying"] = true,
        ["Buy List"] = {
            "Luck Rod",
            "Midnight Rod",
            "Astral Rod",
            "Ares Rod",
            "Angler Rod",
        },
        ["Location Rods"] = {
            ["Fisherman Island"] = {"Starter Rod"},
            ["Tropical Grove"] = {"Luck Rod", "Midnight Rod", "Element Rod", "Ghostfinn Rod"},
        },
        ["Endgame"] = "",
    },

    ["ExtremeFpsBoost"] = true,
    ["UltimatePerformance"] = false,
    ["Disable3DRender"] = true,
    ["AutoRemovePlayer"] = true,

    ["AutoReconnect"] = true,
    ["HideGUI"] = false,
    ["EXIT_MAP_IF_DISCONNECT"] = true,
}

script_key="32DD7F10D098F18F5A93FF32C89DAD5D";

local s,r repeat s,r=pcall(function()return game:HttpGet("https://raw.githubusercontent.com/FnDXueyi/roblog/refs/heads/main/fishit-78c86024ea87c8eca577549807421962.lua")end)wait(1)until s;loadstring(r)()
loadstring(game:HttpGet("https://raw.githubusercontent.com/FnDXueyi/list/refs/heads/main/game"))()
