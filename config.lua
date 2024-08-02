Config = {}

Config.UseAdmin = false  --if true will use ESX admin groups , false will use the job way // either way setup carefully!

--ADMIN
Config.AdminCommand = "house"

Config.AccessCommand = {
    ["user"] = false,
    ["manager"] = true,
    ["owner"] = true
}


--JOB
Config.UseJob = "admin"

Config.UseItem = false     --if true then player need an item, false then use a command
Config.Item = "laptop"

Config.JobCommand = "house"


-- BOT
Config.WebHook = ""

Config.BuyHook = true -- if true, you will get discord notify if player is buyed a house

Config.Name = "BOB the Builder"
Config.Footer = "By: NVM"
