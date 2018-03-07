if not SERVER then return end

local task = {
    Started = {},
    Quest = "Undefined",
    Name = "Undefined",
    Description = "Undefined",
    OnStart = function(ply) end,
    OnFinish = function(ply) end,
    OnRun = function(ply) return true end,
    IsFaulted = false,
    Execute = function(task,ply)
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

}

return function(quest,printname,description,onrun,onstart,onfinish)
    local obj       = setmetatable({},{ __index = task })
    obj.Quest       = quest.Name or obj.Quest
    obj.Name        = printname or obj.Name
    obj.Description = description or obj.Description
    obj.OnStart     = onstart or obj.OnStart
    obj.OnFinish    = onfinish or obj.OnFinish
    obj.OnRun       = onrun or obj.OnRun

    return obj
end
