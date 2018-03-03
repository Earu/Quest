local Tag = "Quest"
local Quest = {}
_G.Quest = Quest

--[[
This loads every quest script in "quest_core/quests/"
Returns void
]]--
Quest.Load = include("quest_core/loader.lua")
Quest.Print = function(txt)
    local prefix = "[Quest] >> "
    print(prefix .. txt)
end

if CLIENT then
    surface.CreateFont("QuestDialogFont",{
        font = "Arial",
        extended = true,
        size = 18,
        weight = 600,
        antialias = true,
        italic = true,
        shadow = true,
        additive = true,
    })

    local width = ScrW() - 20
    local height = 100
    local xpos = 10
    local ypos = ScrH() - 110
    local textmargin = 5

    Quest.CurrentDialog = {
        Components = {},
        Authors = {},
        CurrentIndex = 1,
        CurrentChar = 1,
        Next = 0,
        Display = false,
        OnFinish = function() end,
    }

    local WordWrap = function(str,maxwidth)
        if not str then return "" end
        local lines    = {}
        local strlen   = string.len(str)
        local strstart = 1
        local strend   = 1

        while (strend < strlen) do
            strend = strend + 1
            local width,_ = surface.GetTextSize(string.sub(str,strstart,strend))

            if width and width > maxwidth then
                local n = string.sub(str,strend,strend)
                local I = 0

                for i = 1, 15 do
                    I = i

                    if (n ~= " " and n ~= "," and n ~= "." and n ~= "\n") then
                        strend = strend - 1
                        n = string.sub(str,strend,strend)
                    else
                        break
                    end
                end

                if (I == 15) then
                    strend = strend + 14
                end

                local finalstr = string.Trim(string.sub(str,strstart,strend))
                table.insert(lines,finalstr)
                strstart = strend + 1
            end
        end

        table.insert(lines,string.sub(str,strstart,strend))

        return table.concat(lines,"\n")
    end

    --[[
        Shows a panel with choices to the localplayer
            msg: The message to display
            title: The title of the panel
            choicex: The name of the choice
            callbackx: The callback to be executed for the choice corresponding
        Returns the query panel object
    ]]--
    Quest.Query = function(msg,title,choice1,callback1,choice2,callback2,choice3,callback3,choice4,callback4)
        local panel = Derma_Query(msg,title,choice1,callback1,choice2,callback2,choice3,callback3,choice4,callback4)
        panel.Paint = function(self,w,h)
            surface.SetDrawColor(0,0,0,200)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(0,0,0,220)
            surface.DrawRect(0,0,w,25)
            surface.SetDrawColor(100,100,100,255)
            surface.DrawOutlinedRect(0,0,w,h)
            surface.DrawLine(0,25,w,25)
        end
        for _,obj in pairs(panel:GetChildren()[6]:GetChildren()) do
            if obj:GetName() == "DButton" then
            obj:SetTextColor(Color(255,255,255))
                obj.Paint = function(self,w,h)
                    surface.SetDrawColor(75,75,75,200)
                    surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(200,200,200,255)
                    surface.DrawOutlinedRect(0,0,w,h)
                end
            end
        end

        return panel
    end

    --[[
        Shows a RPGish dialog box on the localplayer screen
            components: A table of strings that compose the whole dialog
            onfinish: The function to be called on the dialog end
                signature is "void function()"
        Returns void
    ]]--
    Quest.ShowDialog = function(components,authors,onfinish)
        if not Quest.CurrentDialog.Display then
            Quest.CurrentDialog.Components = {}
            for _,str in pairs(components) do
                local wrapped = WordWrap(str,width - textmargin*2)
                table.insert(Quest.CurrentDialog.Components,wrapped)
            end
            if type(authors) == "string" then
                for i=1,#Quest.CurrentDialog.Components do
                    table.insert(Quest.CurrentDialog.Authors,authors)
                end
            else
                Quest.CurrentDialog.Authors = authors
            end
            Quest.CurrentDialog.CurrentIndex = 1
            Quest.CurrentDialog.CurrentChar = 1
            Quest.CurrentDialog.Display = true
            Quest.Next = CurTime() + 1
            Quest.CurrentDialog.OnFinish = onfinish
        end
    end

    local fix = 0
    --[[
        Called on each call of KeyRelease hook
            ply: The player that released the key (Always localplayer)
            key: A key enum corresponding to the key released
        Returns void
    ]]--
    local OnKeyRelease = function(ply,key)
        if Quest.CurrentDialog.Display then
            if key == IN_ATTACK or key == IN_USE then
                fix = fix + 1
                if fix > 2 and CurTime() > Quest.CurrentDialog.Next then
                    Quest.CurrentDialog.CurrentIndex = Quest.CurrentDialog.CurrentIndex + 1
                    Quest.CurrentDialog.CurrentChar = 1
                    Quest.CurrentDialog.Next = CurTime() + 1
                    fix = 0
                end
            end
        end
    end

    local blockeds =
    {
        ["CHudHealth"] = true,
	    ["CHudBattery"] = true,
        ["CHudAmmo"] = true,
    }
    --[[
        Called on each call of HUDShouldDraw hook
            element: The hud element name
        Returns false if internal conditions are met
    ]]--
    local OnShouldDraw = function(element)
        if Quest.CurrentDialog.Display and blockeds[element] then
            return false
        end
    end

    --[[
        Called on each call of HUDPaint hook
        Returns void
    ]]--
    local OnPaint = function()
        if Quest.CurrentDialog.Display then
            surface.SetDrawColor(0,0,0,200)
            surface.DrawRect(xpos,ypos,width,height)
            surface.SetDrawColor(100,100,100,200)
            surface.DrawOutlinedRect(xpos,ypos,width,height)
            surface.SetTextColor(Color(255,255,255))
            surface.SetFont("QuestDialogFont")
            local display = "Press MOUSE1 or USE to continue"
            local x,y = surface.GetTextSize(display)
            surface.SetTextPos(width - x, ypos - y - textmargin)
            surface.DrawText(display)
            local cur = Quest.CurrentDialog.Components[Quest.CurrentDialog.CurrentIndex]
            if not cur then
                Quest.CurrentDialog.Display = false
                local s,e = Quest.CurrentDialog and pcall(Quest.CurrentDialog.OnFinish) or true,nil
                if not s then
                    Quest.Print("The current dialog OnFinish method generated an error:\n" .. e)
                end
            else
                Quest.CurrentDialog.CurrentChar = Quest.CurrentDialog.CurrentChar + 1
                local author = Quest.CurrentDialog.Authors[Quest.CurrentDialog.CurrentIndex]
                if author then
                    local ax,ay = surface.GetTextSize(author)
                    local x,y = xpos + 30,ypos - 25
                    local w,h = ax + 20,26
                    surface.SetDrawColor(0,0,0,200)
                    surface.DrawRect(x,y,w,h)
                    surface.SetDrawColor(100,100,100,200)
                    surface.DrawOutlinedRect(x,y,w,h)
                    surface.SetTextPos(x + 10,y + 5)
                    surface.DrawText(author)
                end
                for k,v in pairs(string.Explode("\n",string.sub(cur,1,Quest.CurrentDialog.CurrentChar))) do
                    local i = ypos + textmargin + ((k - 1) * 15)
                    surface.SetTextPos(xpos + textmargin, i)
                    surface.DrawText(v)
                end
            end
        end
    end

    hook.Add("KeyRelease",Tag,OnKeyRelease)
    hook.Add("HUDPaint",Tag,OnPaint)
    hook.Add("HUDShouldDraw",Tag,OnShouldDraw)
end

if SERVER then
    Quest.Quests = {}
    Quest.Count = 0
    Quest.EntityRespawnDelay = 30
    Quest.ActiveQuest = {
        Name = "default",
        PrintName = "Default",
        Description = "The default quest",
        OnStart = function() end,
        OnFinish = function() end,
        Tasks = {},
        Entities = {},
        Players = {},
        Blacklist = {},
    }

    --[[
    Creates a quest table and registers it
        name: The name of the quest
        printname: The name that will be used for this quest in UIs
        description: The quest description to be displayed in UIs
        onstart: The callback to be executed on completion of the quest. Signature is "void function(Player ply)"
        onfinish: The callback to be executed on completion of the quest. Signature is "void function(Player ply)"
    Returns a new quest table corresponding to arguments passed
    ]]--
    Quest.CreateQuest = function(name,printname,description,onstart,onfinish)
        local quest = {
            Name = name,
            PrintName = printname,
            Description = description,
            OnStart = onstart,
            OnFinish = onfinish,
            Tasks = {},
            Entities = {},
            Players = {},
            Blacklist = {},
        }
        Quest.Quests[name] = quest
        Quest.Count = Quest.Count + 1

        return quest
    end

    --[[
    Add an entity to a quest so it can be used in tasks
        quest: The quest table to assign the entity to
        name: String, The name of the entity
        class: String, The class that the entity should have
        model: String, The model that the entity should have
        isnpc: Boolean, Is the entity a npc?
        spawnpoint: Vector, The position at which the entity spawns
        onuse: void function(Player ply), The function that will
            be fired when a player press use on the entity
    Returns the entity table created
    ]]--
    Quest.AddEntity = function(quest,name,class,model,isnpc,spawnpoint,onuse)
        local ent = {
            Name = name,
            Class = class,
            Model = model,
            OnUse = onuse,
            IsNPC = isnpc,
            SpawnPosition = spawnpoint,
            Instance = NULL,
            Interacted = {},
            Killed = {},
        }
        quest.Entities[name] = ent

        return ent
    end

    --[[
    Spawns a quest entity according to the ent table passed
        ent: The quest entity table
    Returns the newly created instance of the quest entity
    ]]--
    Quest.SpawnEntity = function(ent)
        if IsValid(ent.Instance) then
            ent.Instance.IsQuestEntity = false
            ent.Instance:Remove()
        end

        local inst = ents.Create(ent.Class)
        inst:SetModel(ent.Model)
        inst:SetPos(ent.SpawnPosition)
        inst:Spawn()
        inst.IsQuestEntity = true
        inst.QuestEntityName = ent.Name
        ent.Instance = inst

        return inst
    end

    --[[
    Called on KeyPress hook
        ply: The player pressing the key
        ent: They key being pressed
    Returns void
    ]]--
    local OnKeyPress = function(ply,key)
        if key == IN_USE and ply == earu then
            local tr = util.TraceLine({
                start = ply:EyePos(),
                endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100,
                filter = function(ent)
                    if ent.IsQuestEntity then
                        return true
                    end
                end
            })

            if tr.Entity:IsValid() then
                local active = Quest.ActiveQuest
                if active.Players[ply] then
                    local qent = active.Entities[tr.Entity.QuestEntityName]
                    local s,e = pcall(qent.OnUse,ply)
                    if not s then
                        Quest.Print("Entity[" .. qent.Name .. "] OnUse method generated error:\n" ..
                            e .. "\n /!\\ This method is now faulted and wont be ran anymore /!\\")
                        qent.OnUse = function() end
                    end
                    qent.Interacted[ply] = true
                end
            end
        end
    end

    --[[
    Called on EntityRemoved hook
        ent: The ent being removed
    Returns void
    ]]--
    local OnEntityRemoved = function(ent)
        if ent.IsQuestEntity then
            local qname = Quest.ActiveQuest.Name
            local active = Quest.ActiveQuest
            local qent = active.Entities[ent.QuestEntityName]
            timer.Simple(Quest.EntityRespawnDelay,function()
                if active.Name == qname then
                    Quest.SpawnEntity(qent)
                end
            end)
        end
    end

    --[[
    Called OnNPCKilled hook
        npc: The NPC being killed
        attacker: The attacker
        inflictor: The inflictor
    Returns void
    ]]--
    local OnNPCKilled = function(npc,attacker,inflictor)
        if not attacker:IsPlayer() then return end
        local active = Quest.ActiveQuest
        if npc.IsQuestEntity and active.Players[attacker] then
            local qent = active.Entities[npc.QuestEntityName]
            qent.Killed[attacker] = true
        end
    end

    hook.Add("KeyPress",Tag,OnKeyPress)
    hook.Add("EntityRemoved",Tag,OnEntityRemoved)
    hook.Add("OnNPCKilled",Tag,OnNPCKilled)

    --[[
    Sets the passed quest as active quest
        quest: The quest table to set as active
    Returns void
    ]]--
    Quest.SetActiveQuest = function(quest)
        for _,ent in pairs(Quest.ActiveQuest.Entities) do
            if IsValid(ent) then
                ent.IsQuestEntity = false
                ent:Remove()
            end
        end
        Quest.ActiveQuest = quest
        for _,ent in pairs(quest.Entities) do
            Quest.SpawnEntity(ent)
        end
    end

    --[[
    Creates a task table and assign it to the quest specified
        quest: The quest to assign this task to
        printname: The name of the task to be displayed in UIs
        description: The description of the task to be displayed in UIs
        onrun: A function of signature "bool function(Player ply)"
            where bool indicates wether or not the task has been completed by the player
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table corresponding to arguments passed
    ]]--
    Quest.AddTask = function(quest,printname,description,onrun,onstart,onfinish)
        local task = {
            Started = {},
            Quest = quest.Name,
            Name = printname,
            Description = description,
            OnStart = onstart,
            OnFinish = onfinish,
            OnRun = onrun,
            IsFaulted = false,
        }

        --Here we make the core function that will be called by this task safe from developer mistakes
        task.Execute = function(ply)
            if task.IsFaulted then return true end

            if not task.Started[ply:SteamID()] then
                local s,e = task.OnStart and pcall(task.OnStart,ply) or true,nil
                if not s then
                    task.IsFaulted = true
                    Quest.Print("Task[" .. task.Name .. "] OnStart method generated error:\n" ..
                        e .. "\n /!\\ This task is now faulted and wont be ran anymore /!\\")
                    return true
                end
                task.Started[ply:SteamID()] = true
            end

            local s,ret = pcall(task.OnRun,ply)
            if not s then
                task.IsFaulted = true
                Quest.Print("Task[" .. task.Name .. "] OnRun method generated error:\n" ..
                    ret .. "\n /!\\ This task is now faulted and wont be ran anymore /!\\")
                return true
            else
                ret = ret ~= nil and ret or false
                if ret then
                    local s,e = task.OnFinish and pcall(task.OnFinish,ply) or true,nil
                    if not s then
                        task.IsFaulted = true
                        Quest.Print("Task[" .. task.Name .. "] OnFinish method generated error:\n" ..
                            e .. "\n /!\\ This task is now faulted and wont be ran anymore /!\\")
                        return true
                    else
                        return ret
                    end
                else
                    return false
                end
            end
        end

        table.insert(quest.Tasks,task)

        return task
    end

    --[[
    A wrapper around Quest.AddTask that adds a task to the specified quest,
    the player should reach the specified pos to complete the task
        quest: The quest to assign this task to
        locname: The location name that will be used in UIs
        locpos: The position to be reached to complete the task
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table
    ]]--
    Quest.AddLocationTask = function(quest,locname,locpos,onstart,onfinish)
        local t = Quest.AddTask(quest,"Reach " .. locname,"Go and find the place called \"" .. locname .. "\"!",
        function(ply)
            return ply:GetPos():Distance(locpos) < 150
        end,onstart,onfinish)

        return t
    end

    --[[
    A wrapper around Quest.AddTask that adds a task to the specified quest,
    the player should talk to a specified entity to complete the task
        quest: The quest to assign this task to
        entprintname: The entity name that will be used in UIs
        entname: The entity name that was used to add the entity to the quest
        ent: The entity to talk to complete the task
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table
    ]]--
    Quest.AddUseTask = function(quest,entprintname,entname,onstart,onfinish)
        local t = Quest.AddTask(quest,entprintname,"Interact with " .. entprintname,
        function(ply)
            return quest.Entities[entname].Interacted[ply]
        end,onstart,onfinish)

        return t
    end

    --[[
    A wrapper around Quest.AddTask that adds a task to the specified quest,
    the player should kill a specified entity to complete the task
        quest: The quest to assign this task to
        entprintname: The entity name that will be used in UIs
        entname: The entity name that was used to add the entity to the quest
        ent: The entity to kill complete the task
        onstart: A function of signature "void function(ply)" that will be run on start of the task
        onfinish: A function of signature "void function(ply)" that will be run on end of the task
    Returns a new task table
    ]]--
    Quest.AddKillTask = function(quest,entprintname,entname,onstart,onfinish)
        local t = Quest.AddTask(quest,entprintname,"Get rid of " .. entprintname,
        function(ply)
            return quest.Entities[entname].Killed[ply]
        end,onstart,onfinish)

        return t
    end

    --[[
    Adds a player to a quest
        quest: The quest table to add the player to
        ply: The player to add
    Returns void
    ]]--
    Quest.AddPlayer = function(quest,ply)
        if quest.Blacklist[ply:SteamID()] then return end
        if not quest.Players[ply] then
            quest.Players[ply] = 1
            local s,e = quest.OnStart and pcall(quest.OnStart,ply) or true,nil
            if not s then
                Quest.Print("Quest[" .. quest.PrintName .. "] OnStart method generated error:\n" ..
                    e .. "\n /!\\ This method is now faulted and wont be ran anymore /!\\")
                quest.OnFinish = function() end --No more errors here
            end
        end
    end

    --[[
    Removes a player from a quest
        quest: The quest table to add the player to
        ply: The player to add
    Returns void
    ]]--
    Quest.RemovePlayer = function(quest,ply)
        if quest.Players[ply] then
            quest.Players[ply] = nil
        end
    end

    --[[
    Blacklists a player from a quest
        quest: The quest to blacklist the player from
        ply: The player to blacklist
    Returns void
    ]]--
    Quest.Blacklist = function(quest,ply)
        if not quest.Blacklist[ply:SteamID()] then
            quest.Blacklist[ply:SteamID()] = true
        end
    end

    --[[
    Called when a player disconnects
        ply: The player entity disconnecting
    Returns void
    ]]--
    local OnDisconnect = function(ply)
        if Quest.ActiveQuest.Players[ply] then
            Quest.ActiveQuest.Players[ply] = nil
        end
    end

    --[[
    Called each time Think hook is fired
    Returns void
    ]]--
    local OnThink = function()
        local active = Quest.ActiveQuest
        for ply,state in pairs(active.Players) do
            if ply:IsValid() and #active.Tasks > 0 then
                local finished = active.Tasks[state].Execute(ply)
                if finished then
                    local nextstate = state + 1
                    active.Players[ply] = nextstate
                    if nextstate > #active.Tasks then
                        local s,e = active.OnFinish and pcall(active.OnFinish,ply) or true,nil
                        if s then
                            Quest.RemovePlayer(active,ply)
                            Quest.Blacklist(active,ply)
                            local name = _G.UndecorateNick and (_G.UndecorateNick(ply:Nick())) or ply:Nick()
                            Quest.Print(name .. "[" .. ply:SteamID() .. "] completed quest <" .. active.PrintName .. ">")
                        else
                            Quest.Print("Quest[" .. active.PrintName .. "] OnFinish method generated error:\n" ..
                                e .. "\n /!\\ This method is now faulted and wont be ran anymore /!\\")
                            active.OnFinish = function() end -- Remove the function so it doesnt spam errors
                        end
                    end
                end
            end
        end
    end

    --[[
    Essentially spawns the npc giving the daily quest
    Returns void
    ]]--
    local OnInitPostEntity = function()
        local spanwpoint = Vector (-14415.375976562, 457.50762939453, 13363.03125)
        local ent = ents.Create("lua_npc_quest")
        ent:SetPos(spanwpoint)
        ent:SetAngles(Angle(0,-90,0))
        ent:Spawn()
        --ent:StartActivity(ACT_IDLE)
    end

    hook.Add("PlayerDisconnected",Tag,OnDisconnect)
    hook.Add("PlayerConnect",Tag,OnConnect)
    hook.Add("Think",Tag,OnThink)
    hook.Add("InitPostEntity",Tag,OnInitPostEntity)
end

--[[
This is called on quest initialization
Returns void
]]--
local OnInitialize = function()
    Quest.Load()
    if SERVER then
        if Quest.Count > 0 then
            local index = math.random(1,Quest.Count)
            Quest.SetActiveQuest(Quest.Quests[index])
        end
    end
end

hook.Add("Initialize",Tag,OnInitialize)