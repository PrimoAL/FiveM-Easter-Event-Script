ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS easter_eggs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            x FLOAT NOT NULL,
            y FLOAT NOT NULL,
            z FLOAT NOT NULL,
            poem_id INT NOT NULL,
            label VARCHAR(255) DEFAULT 'Osterei'
        )
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS easter_poems (
            id INT AUTO_INCREMENT PRIMARY KEY,
            poem_start TEXT NOT NULL,
            poem_end TEXT NOT NULL
        )
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS easter_collected (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL,
            egg_id INT NOT NULL,
            collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(identifier, egg_id)
        )
    ]], {})

    MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM easter_poems', {}, function(result)
        if result[1].count == 0 then
            local defaultPoems = {
                {
                    start = "Backe, backe Kuchen, der Bäcker hat",
                    ending = "gerufen"
                },
                {
                    start = "Hoppe hoppe Reiter, wenn er fällt, dann schreit",
                    ending = "er"
                },
                {
                    start = "Häschen in der Grube saß und",
                    ending = "schlief"
                },
                {
                    start = "Alle meine Entchen schwimmen auf dem",
                    ending = "See"
                },
                {
                    start = "Hänschen klein ging allein in die weite Welt",
                    ending = "hinein"
                },
                {
                    start = "Summ, summ, summ, Bienchen summ",
                    ending = "herum"
                },
                {
                    start = "Morgens früh um sechs, kommt die kleine",
                    ending = "Hex"
                },
                {
                    start = "Grün, grün, grün sind ____ meine Kleider",
                    ending = "alle"
                },
                {
                    start = "Es regnet, es regnet, die Erde wird",
                    ending = "nass"
                },
                {
                    start = "Der Kuckuck und der Esel, die hatten einen",
                    ending = "Streit"
                },
                {
                    start = "Im grünen _____ liegt bunt versteckt das Osterei",
                    ending = "Gras"
                },
                {
                    start = "Der Osterhase kommt geschwind und bringt was für jedes",
                    ending = "Kind"
                },
                {
                    start = "Bunte Eier, Zuckerei – alles liegt im Nest",
                    ending = "dabei"
                },
                {
                    start = "Klingeling, der ________ ruft, durch Wald und über Blumenduft",
                    ending = "Frühling"
                },
                {
                    start = "Has’ und Henne, Hand in Hand, laufen fröhlich übers",
                    ending = "Osterland"
                }
            }
    
            for _, poem in ipairs(defaultPoems) do
                MySQL.Async.execute('INSERT INTO easter_poems (poem_start, poem_end) VALUES (@start, @end)', {
                    ['@start'] = poem.start,
                    ['@end'] = poem.ending
                })
            end
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        TriggerClientEvent('easter:syncEggs', -1)
        Citizen.Wait(60000)
    end
end)

RegisterNetEvent('easter:requestSync')
AddEventHandler('easter:requestSync', function()
    local src = source
    syncEggsForPlayer(src)
end)

function syncEggsForPlayer(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local identifier = xPlayer.identifier
    
    MySQL.Async.fetchAll('SELECT e.*, CASE WHEN c.egg_id IS NOT NULL THEN 1 ELSE 0 END as collected FROM easter_eggs e LEFT JOIN easter_collected c ON e.id = c.egg_id AND c.identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(eggs)
        TriggerClientEvent('easter:receiveEggs', source, eggs)
    end)
end

RegisterCommand('addeasteregg', function(source, args)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer.getGroup() == 'user' then
        TriggerClientEvent('esx:showNotification', src, 'Du hast keine Berechtigung!')
        return
    end
    
    local poemId = tonumber(args[1])

    poemId = math.random(1,15)

    if not poemId then
        TriggerClientEvent('esx:showNotification', src, 'Bitte gib eine gültige Gedicht-ID an!')
        return
    end
    
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM easter_poems WHERE id = @id', {
        ['@id'] = poemId
    }, function(count)
        if count > 0 then
            TriggerClientEvent('easter:placeEgg', src, poemId)
        else
            TriggerClientEvent('esx:showNotification', src, 'Gedicht mit ID ' .. poemId .. ' nicht gefunden!')
        end
    end)
end, false)

RegisterNetEvent('easter:saveEgg')
AddEventHandler('easter:saveEgg', function(position, poemId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer.getGroup() == 'user' then return end
    
    MySQL.Async.execute('INSERT INTO easter_eggs (x, y, z, poem_id) VALUES (@x, @y, @z, @poemId)', {
        ['@x'] = position.x,
        ['@y'] = position.y,
        ['@z'] = position.z,
        ['@poemId'] = poemId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', src, 'Osterei erfolgreich platziert!')
            TriggerClientEvent('easter:syncEggs', -1)
        else
            TriggerClientEvent('esx:showNotification', src, 'Fehler beim Platzieren des Ostereis!')
        end
    end)
end)

RegisterNetEvent('easter:checkPoem')
AddEventHandler('easter:checkPoem', function(eggId, userAnswer)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local identifier = xPlayer.identifier
    
    MySQL.Async.fetchAll('SELECT p.poem_end FROM easter_eggs e JOIN easter_poems p ON e.poem_id = p.id WHERE e.id = @eggId', {
        ['@eggId'] = eggId
    }, function(result)
        if #result > 0 then
            local correctAnswer = result[1].poem_end
            
            local normalizedUserAnswer = string.lower(string.gsub(userAnswer, "^%s*(.-)%s*$", "%1"))
            local normalizedCorrectAnswer = string.lower(string.gsub(correctAnswer, "^%s*(.-)%s*$", "%1"))
            
            local isCorrect = normalizedUserAnswer == normalizedCorrectAnswer
                          or normalizedUserAnswer == string.gsub(normalizedCorrectAnswer, "[%p]", "") 
                          or string.gsub(normalizedUserAnswer, "[%p]", "") == normalizedCorrectAnswer
            
            if isCorrect then
                MySQL.Async.fetchScalar('SELECT COUNT(*) FROM easter_collected WHERE identifier = @identifier AND egg_id = @eggId', {
                    ['@identifier'] = identifier,
                    ['@eggId'] = eggId
                }, function(count)
                    if count == 0 then
                        MySQL.Async.execute('INSERT INTO easter_collected (identifier, egg_id) VALUES (@identifier, @eggId)', {
                            ['@identifier'] = identifier,
                            ['@eggId'] = eggId
                        })

                        local rewardType = math.random(1, 5)
                        local notificationMsg = ''
                        
                        if rewardType == 1 then
                            local moneyAmount = math.random(50, 150)
                            xPlayer.addMoney(moneyAmount)
                            notificationMsg = 'Richtig! Du hast ein Osterei gefunden und ' .. moneyAmount .. '$ erhalten!'
                        
                        elseif rewardType == 2 then
                            local possibleItems = {
                                {name = 'bingchilling', label = 'Bing Chilling', count = 3},
                                {name = 'color_mk2_white', label = 'Weiße Farbe Mk. II', count = 1},
                                {name = 'farbe_mk2', label = 'Waffenfarbe Mk. II', count = 1},
                                {name = 'hatchet_lj', label = 'Farbeimer', count = 10},
                                {name = 'headlightb', label = 'Platin Waffenfarbe', count = 1},
                                {name = 'headlightbl', label = 'Goldene Waffenfarbe', count = 1},
                                {name = 'headlightg', label = 'Platin-Waffenfarbe', count = 1},
                                {name = 'headlightp', label = 'Pinke Waffenfarbe', count = 1},
                                {name = 'headlightr', label = 'Luxury Farbe', count = 1},
                                {name = 'mk2_color_0', label = 'Klassisch Schwarze Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_1', label = 'Klassisch Graue Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_10', label = 'Kontrast-blaue Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_11', label = 'Kontrast-gelbe Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_12', label = 'Kontrast-orangene Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_13', label = 'Pinke Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_14', label = 'Lila-gelbe Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_15', label = 'Orangene Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_16', label = 'Hellgrüne Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_17', label = 'Schwarz-rote Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_18', label = 'Schwarz-grüne Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_19', label = 'Schwarz-türkise Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_2', label = 'Klassisch Schwarz-weiße Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_20', label = 'Schwarz-gelbe Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_21', label = 'Weiß-rote Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_22', label = 'Weiß-blaue Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_23', label = 'Metallisch Goldene Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_24', label = 'Metallisch Platin Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_25', label = 'Metallisch Grau-lila Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_26', label = 'Metallisch Lila-hellgrün Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_27', label = 'Metallisch Rot Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_28', label = 'Metallisch Grün Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_29', label = 'Metallisch Blau Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_3', label = 'Klassisch Weiße Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_30', label = 'Metallisch Weiß-türkise Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_31', label = 'Metallisch Rot-gelbe Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_4', label = 'Klassisch Beige Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_5', label = 'Klassisch Grün Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_6', label = 'Klassisch Blau Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_7', label = 'Klassisch Hellgrau Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_8', label = 'Klassisch Braun Mk. II Waffenfarbe', count = 1},
                                {name = 'mk2_color_9', label = 'Kontrast-rote Mk. II Waffenfarbe', count = 1},
                            }
                            
                            local selectedItem = possibleItems[math.random(1, #possibleItems)]
                            xPlayer.addInventoryItem(selectedItem.name, selectedItem.count)
                            notificationMsg = 'Richtig! Du hast ein Osterei gefunden und ' .. selectedItem.count .. 'x ' .. selectedItem.label .. ' erhalten!'
                        
                        elseif rewardType == 3 then
                            local coinsAmount = 1
                            addCoinsDatabase(identifier, coinsAmount)
                            notificationMsg = 'Richtig! Du hast ein Osterei gefunden und ' .. coinsAmount .. ' Coin erhalten!'
                        
                        elseif rewardType == 4 then
                            local bonusMoneyAmount = math.random(75, 200)
                            xPlayer.addMoney(bonusMoneyAmount)
                            notificationMsg = 'Richtig! Du hast ein Osterei gefunden und ' .. bonusMoneyAmount .. '$ erhalten!'
                        
                        elseif rewardType == 5 then
                            local bonusMoneyAmount = math.random(75, 200)
                            xPlayer.addMoney(bonusMoneyAmount)
                            notificationMsg = 'Richtig! Du hast ein Osterei gefunden und ' .. bonusMoneyAmount .. '$ erhalten!'
                        end
                        
                        TriggerClientEvent('esx:showNotification', src, notificationMsg)
                        TriggerClientEvent('easter:eggCollected', src, eggId)
                        
                        checkAllEggsCollected(src, identifier)
                    else
                        TriggerClientEvent('esx:showNotification', src, 'Du hast dieses Ei bereits gefunden!')
                    end
                end)
            else
                TriggerClientEvent('esx:showNotification', src, 'Falsche Antwort! Versuche es nochmal.')
            end
        end
    end)
end)

function addCoinsDatabase(identifier, amount)
    MySQL.Async.fetchScalar('SELECT coins FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(currentCoins)
        local newCoins = tonumber(currentCoins) or 0
        newCoins = newCoins + amount
        
        MySQL.Async.execute('UPDATE users SET coins = @coins WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@coins'] = tostring(newCoins)
        })
    end)
end

function checkAllEggsCollected(source, identifier)
    MySQL.Async.fetchAll('SELECT COUNT(id) as total FROM easter_eggs', {}, function(totalResult)
        MySQL.Async.fetchAll('SELECT COUNT(id) as collected FROM easter_collected WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(collectedResult)
            local total = totalResult[1].total
            local collected = collectedResult[1].collected
            
            if total > 0 and total == collected then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then
                    local specialReward = math.random(1, 5)
                    
                    if specialReward == 1 then
                        local bonusMoney = math.random(50, 150)
                        xPlayer.addMoney(bonusMoney)
                        TriggerClientEvent('esx:showNotification', source, 'Glückwunsch! Du hast alle Ostereier gefunden und ' .. bonusMoney .. '$ als Bonus erhalten!')
                    elseif specialReward == 2 then
                        local bonusMoney = math.random(100, 150)
                        xPlayer.addMoney(bonusMoney)
                        TriggerClientEvent('esx:showNotification', source, 'Glückwunsch! Du hast alle Ostereier gefunden und ' .. bonusMoney .. '$ als Bonus erhalten!')
                    elseif specialReward == 3 then
                        local bonusMoney = math.random(150, 250)
                        xPlayer.addMoney(bonusMoney)
                        TriggerClientEvent('esx:showNotification', source, 'Glückwunsch! Du hast alle Ostereier gefunden und ' .. bonusMoney .. '$ als Bonus erhalten!')
                    elseif specialReward == 4 then
                        local bonusCoins = 5
                        addCoinsDatabase(identifier, bonusCoins)
                        TriggerClientEvent('esx:showNotification', source, 'Glückwunsch! Du hast alle Ostereier gefunden und ' .. bonusCoins .. ' Coins als Bonus erhalten!')
                    elseif specialReward == 5 then
                        local bonusMoney = math.random(100, 200)
                        xPlayer.addMoney(bonusMoney)
                        TriggerClientEvent('esx:showNotification', source, 'Glückwunsch! Du hast alle Ostereier gefunden und ' .. bonusMoney .. '$ als Bonus erhalten!')
                    end
                end
            end
        end)
    end)
end

ESX.RegisterServerCallback('easter:getPoem', function(source, cb, poemId)
    MySQL.Async.fetchAll('SELECT * FROM easter_poems WHERE id = @id', {
        ['@id'] = poemId
    }, function(result)
        if result and result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

ESX.RegisterServerCallback('easter:getProgress', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil, nil) end
    
    local identifier = xPlayer.identifier
    
    MySQL.Async.fetchAll('SELECT COUNT(id) as total FROM easter_eggs', {}, function(totalResult)
        MySQL.Async.fetchAll('SELECT COUNT(id) as collected FROM easter_collected WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(collectedResult)
            cb(collectedResult[1].collected, totalResult[1].total)
        end)
    end)
end)

-- Admin-Stuff:
RegisterCommand('easterstats', function(source)
    local src = source
    
    MySQL.Async.fetchAll([[
        SELECT 
            u.identifier,
            u.firstname, 
            u.lastname, 
            u.phone_number, 
            u.coins, 
            u.job,
            j.label AS job_label,
            jg.label AS grade_label,
            COUNT(ec.id) AS eggs_found, 
            (SELECT COUNT(id) FROM easter_eggs) AS total_eggs
        FROM 
            easter_collected ec
        JOIN 
            users u ON u.identifier = ec.identifier
        LEFT JOIN 
            jobs j ON j.name = u.job
        LEFT JOIN 
            job_grades jg ON jg.job_name = u.job AND jg.grade = u.job_grade
        GROUP BY 
            ec.identifier
        ORDER BY 
            eggs_found DESC, MAX(ec.collected_at) ASC
    ]], {}, function(results)
        if #results > 0 then
            TriggerClientEvent('easter:openStatsUI', src, results)
        else
            TriggerClientEvent('esx:showNotification', src, 'Keine Spieler haben bisher Ostereier gefunden!')
        end
    end)
end, false)

ESX.RegisterServerCallback('easter:getPlayerJobInfo', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    
    local job = xPlayer.getJob()
    cb({
        name = job.name,
        label = job.label,
        grade = job.grade,
        grade_label = job.grade_label
    })
end)

ESX.RegisterServerCallback('easter:isPlayerAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then 
        cb(false)
        return 
    end

    local isAdmin = xPlayer.getGroup() == 'projektleitung' or xPlayer.getGroup() == 'communitymanager'
    
    cb(isAdmin)
end)