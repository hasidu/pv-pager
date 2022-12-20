--QBCore = exports['qb-core']:GetCoreObject()
ESX = nil

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(30)
  end
end)

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function page(tune,text, src)
    local pagerTune = Config.Pager[tune];

    if(pagerTune == nil) then
        --TriggerClientEvent('QBCore:Notify', src, "The paged channel does not exist.", 'error')
        TriggerClientEvent('esx:showNotification', src, 'The paged channel does not exist.', "error", 3000)
        --TriggerClientEvent('okokNotify:Alert', src, "PAGER", "The paged channel does not exist.", 3000, 'error') -- this is okok notify uncomment this if you have script
    end

    --local Player = QBCore.Functions.GetPlayer(src)
    local Player = ESX.GetPlayerFromId(src)
    local authorized=false;

    if pagerTune.jobPermissions ~= nil then
        for k,v in ipairs(pagerTune.jobPermissions) do
            if(Player.PlayerData.job.name == v) then
                authorized=true;
                break
            end
        end

        if authorized == false then
            --TriggerClientEvent('QBCore:Notify', src, "You are not authenticated to broadcast on the paged channel.", 'error');
            TriggerClientEvent('esx:showNotification', src, 'You are not authenticated to broadcast on the paged channel.', "error", 3000);
            --TriggerClientEvent('okokNotify:Alert', src, "PAGER", "You are not authenticated to broadcast on the paged channel.", 3000, 'error'); -- this is okok notify uncomment this if you have script
            return false;
        end

    end

    if pagerTune.discordPermissions ~= nil then
        authorized=exports["pv-discord-uac"]:doesUserHaveAnyRole(src,pagerTune.discordPermissions);

        if authorized == false then
            TriggerClientEvent('QBCore:Notify', src, "You are not authenticated to broadcast on the paged channel.", 'error');
            TriggerClientEvent('esx:showNotification', src, 'You are not authenticated to broadcast on the paged channel.', "error", 3000);
            --TriggerClientEvent('okokNotify:Alert', src, "PAGER", "You are not authenticated to broadcast on the paged channel.", 3000, 'error'); -- this is okok notify uncomment this if you have script
            return false;
        end
    end

    if authorized then
        -- local players = QBCore.Functions.GetQBPlayers()
        local players = ESX.GetPlayerFromId(src)
        for _, v in pairs(players) do
            if(pagerTune.broadcastToJobs[v.PlayerData.job.name]) then
                if(pagerTune.broadcastToRoles ~= nil) then

                    if(exports["pv-discord-uac"]:doesUserHaveAnyRole(v.PlayerData.source,pagerTune.broadcastToRoles)) then
                        TriggerClientEvent("pv-pager:pager:received",  v.PlayerData.source, text);
                    end

                else
                    TriggerClientEvent("pv-pager:pager:received",  v.PlayerData.source, text);
                end

            end
        end
    end

    for k,v in ipairs(pagerTune.webhooks) do
        sendToDiscord(k,pagerTune.title,text,v);
    end

    sendToDiscord(Config.LogWebhook,pagerTune.title,text, "New pager!",src,true);
end

-- QBCore.Commands.Add("page", "Use the pager", {}, false, function(source, args)
--     local src = source

--     local pagerTune = args[1];
--     args[1]="";

--     local text=table.concat(args, " ");

--     page(pagerTune,text,src);
-- end)

ESX.RegisterCommand({'page', 'pg'}, 'user', function(source, args)
    --xPlayer.triggerEvent('chat:clear')

    local src = source

    local pagerTune = args[1];
    args[1]="";

    local text=table.concat(args, " ");

    page(pagerTune,text,src);

end, false, {help = 'page text'})
-- https://docs.esx-framework.org/legacy/Server/functions/registercommand


function sendToDiscord(url,title,text, content,src, admin)
    local embed = {
        {
            ["color"] = 10038562,
            ["title"] = "Pager - " .. title,
            ["description"] = text,
        }
    }

    if(admin ~= nil and admin == true) then

        local discord="";

        for k, v in pairs(GetPlayerIdentifiers(src)) do
            if string.sub(v, 1, string.len("discord:")) == "discord:" then
                discord = v
            end
        end

        discord = string.gsub(discord, "discord:", "");

        embed[1].fields = {
                {
                    ["name"]="Sent by",
                    ["value"]="<@" .. discord .. ">"
                }
        };
    end

    PerformHttpRequest(url, function(err, text, headers) end, 'POST', json.encode({username = "Pager", embeds = embed, content = content,}), { ['Content-Type'] = 'application/json' })
end