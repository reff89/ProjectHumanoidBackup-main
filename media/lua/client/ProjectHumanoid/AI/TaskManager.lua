TaskManager = {}
TaskManager.__index = TaskManager

function TaskManager:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.character = character

    o.tasks = {}

    return o
end

function TaskManager:update()

    if self.tasks[0] ~= nil then
        if not self.tasks[0].task:update() then
            NPCPrint(true, "TaskManager", "Task stopped by false from update", self:getCurrentTaskName(), self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
            self:removeTask()
            return
        end

        if self.tasks[0].task:isComplete() then
            NPCPrint(true, "TaskManager", "Task completed", self:getCurrentTaskName(), self.character:getModData().NPC.ID, self.character:getDescriptor():getSurname()) 
            self:removeTask()
            return
        end        
    end
end

function TaskManager:addToTop(task, score)
    if self.tasks[0] ~= nil then
        self.tasks[0].task:stop()
    end

    self.tasks[0] = {}
    self.tasks[0].task = task    
    self.tasks[0].score = score
end

function TaskManager:removeTask()
    self.tasks[0] = nil
end

function TaskManager:getCurrentTaskScore()
    if self.tasks[0] == nil then return 0 end
    return self.tasks[0].score
end

function TaskManager:clear()
    if self.tasks[0] ~= nil then
        self.tasks[0].task:stop()
    end
    self.tasks = {}
end

function TaskManager:getCurrentTaskName()
    if self.tasks[0] == nil then return end
    return self.tasks[0].task.name
end