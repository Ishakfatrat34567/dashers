local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Config = {
    GridUnit = 4,
    ForwardSpeed = 32,
    JumpVelocity = 54,
    ShipLift = 82,
    WaveSpeed = 38,
    Gravity = 150,
    SpawnPosition = Vector3.new(-40, 6, 0),
    CameraOffset = Vector3.new(24, 18, 42),
    GroundRayLength = 2.6,
    RotationSpeed = math.rad(360),
    RestartDelay = 0,
    Colors = {
        Player = Color3.fromRGB(80, 220, 255),
        Ground = Color3.fromRGB(45, 45, 60),
        Accent = Color3.fromRGB(255, 255, 255),
        Hazard = Color3.fromRGB(255, 80, 110),
        PortalCube = Color3.fromRGB(100, 215, 255),
        PortalShip = Color3.fromRGB(255, 195, 70),
        PortalWave = Color3.fromRGB(170, 120, 255),
        PortalBall = Color3.fromRGB(120, 255, 170),
    },
}

local currentCamera = Workspace.CurrentCamera

local Util = {}

function Util:createPart(properties)
    local part = Instance.new("Part")
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Material = properties.Material or Enum.Material.SmoothPlastic
    part.Size = properties.Size or Vector3.new(1, 1, 1)
    part.CFrame = properties.CFrame or CFrame.new()
    part.Color = properties.Color or Color3.new(1, 1, 1)
    part.Name = properties.Name or "Part"
    part.CanCollide = properties.CanCollide ~= false
    part.Transparency = properties.Transparency or 0
    part.CastShadow = properties.CastShadow ~= false
    if properties.Shape then
        part.Shape = properties.Shape
    end
    for key, value in pairs(properties.Attributes or {}) do
        part:SetAttribute(key, value)
    end
    part.Parent = properties.Parent or Workspace
    return part
end

function Util:createAttachment(part, position)
    local attachment = Instance.new("Attachment")
    attachment.Position = position or Vector3.zero
    attachment.Parent = part
    return attachment
end

local LevelLoader = {}
LevelLoader.__index = LevelLoader

function LevelLoader.new(root)
    local self = setmetatable({}, LevelLoader)
    self.Root = root
    self.Hazards = {}
    self.Portals = {}
    self.CourseLength = 0
    return self
end

function LevelLoader:clear()
    for _, child in ipairs(self.Root:GetChildren()) do
        child:Destroy()
    end
    table.clear(self.Hazards)
    table.clear(self.Portals)
    self.CourseLength = 0
end

function LevelLoader:addGround(startX, width, height)
    local unit = Config.GridUnit
    local ground = Util:createPart({
        Name = "Ground",
        Size = Vector3.new(width, height, unit * 4),
        CFrame = CFrame.new(startX + width / 2, -height / 2, 0),
        Color = Config.Colors.Ground,
        Material = Enum.Material.Slate,
        Parent = self.Root,
    })
    self.CourseLength = math.max(self.CourseLength, startX + width)
    return ground
end

function LevelLoader:addBlock(tileX, tileY, tileWidth, tileHeight)
    local unit = Config.GridUnit
    local size = Vector3.new(tileWidth * unit, tileHeight * unit, unit * 2)
    local cframe = CFrame.new(tileX * unit + size.X / 2, tileY * unit + size.Y / 2, 0)
    return Util:createPart({
        Name = "Block",
        Size = size,
        CFrame = cframe,
        Color = Config.Colors.Ground,
        Material = Enum.Material.Slate,
        Parent = self.Root,
    })
end

function LevelLoader:addSpike(tileX, tileY)
    local unit = Config.GridUnit
    local spike = Util:createPart({
        Name = "Spike",
        Size = Vector3.new(unit, unit, unit),
        CFrame = CFrame.new(tileX * unit + unit / 2, tileY * unit + unit / 2, 0) * CFrame.Angles(0, 0, math.rad(45)),
        Color = Config.Colors.Hazard,
        Material = Enum.Material.Neon,
        Parent = self.Root,
        Attributes = {
            IsHazard = true,
        },
    })
    spike.CanCollide = false
    table.insert(self.Hazards, spike)
    self.CourseLength = math.max(self.CourseLength, (tileX + 1) * unit)
    return spike
end

function LevelLoader:addPortal(mode, tileX, tileY)
    local unit = Config.GridUnit
    local colors = {
        Cube = Config.Colors.PortalCube,
        Ship = Config.Colors.PortalShip,
        Wave = Config.Colors.PortalWave,
        Ball = Config.Colors.PortalBall,
    }
    local portal = Util:createPart({
        Name = mode .. "Portal",
        Size = Vector3.new(unit, unit * 3, unit * 2),
        CFrame = CFrame.new(tileX * unit + unit / 2, tileY * unit + unit * 1.5, 0),
        Color = colors[mode],
        Material = Enum.Material.Neon,
        Parent = self.Root,
        Transparency = 0.15,
        CanCollide = false,
        Attributes = {
            PortalMode = mode,
        },
    })
    table.insert(self.Portals, portal)
    self.CourseLength = math.max(self.CourseLength, (tileX + 1) * unit)
    return portal
end

function LevelLoader:build()
    self:clear()
    local unit = Config.GridUnit

    self:addGround(-80, unit * 48, unit)
    self:addGround(unit * 62, unit * 16, unit)

    self:addSpike(6, 0)
    self:addSpike(10, 0)
    self:addSpike(11, 0)
    self:addSpike(16, 0)
    self:addSpike(20, 0)
    self:addSpike(24, 0)
    self:addSpike(25, 0)
    self:addSpike(28, 0)
    self:addSpike(29, 0)
    self:addSpike(35, 0)

    self:addBlock(39, 0, 2, 2)
    self:addSpike(41, 2)
    self:addSpike(42, 0)

    self:addPortal("Ship", 47, 0)

    local ceiling = Util:createPart({
        Name = "Ceiling",
        Size = Vector3.new(unit * 14, unit, unit * 3),
        CFrame = CFrame.new(unit * 55, unit * 7, 0),
        Color = Config.Colors.Ground,
        Material = Enum.Material.Slate,
        Parent = self.Root,
    })
    table.insert(self.Hazards, ceiling)
    ceiling:SetAttribute("IsHazard", true)

    self:addSpike(51, 1)
    self:addSpike(53, 4)
    self:addSpike(57, 1)
    self:addSpike(59, 4)

    self:addPortal("Wave", 62, 0)
    self:addSpike(66, 0)
    self:addSpike(68, 2)
    self:addSpike(70, 0)
    self:addSpike(72, 2)

    self:addPortal("Ball", 76, 0)
    self:addBlock(80, 0, 3, 1)
    self:addSpike(84, 2)
    self:addBlock(87, 4, 2, 1)
    self:addSpike(90, 0)

    self.CourseLength = math.max(self.CourseLength, 92 * unit)
end

local ModeHandler = {}
ModeHandler.__index = ModeHandler

ModeHandler.ModeDefinitions = {
    Cube = {
        Shape = Enum.PartType.Block,
        Size = Vector3.new(Config.GridUnit, Config.GridUnit, Config.GridUnit),
        Material = Enum.Material.Neon,
    },
    Ship = {
        Shape = Enum.PartType.Wedge,
        Size = Vector3.new(Config.GridUnit * 1.25, Config.GridUnit, Config.GridUnit),
        Material = Enum.Material.Neon,
    },
    Wave = {
        Shape = Enum.PartType.Wedge,
        Size = Vector3.new(Config.GridUnit, Config.GridUnit * 0.75, Config.GridUnit),
        Material = Enum.Material.ForceField,
    },
    Ball = {
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(Config.GridUnit, Config.GridUnit, Config.GridUnit),
        Material = Enum.Material.Neon,
    },
}

function ModeHandler.new(playerPart)
    local self = setmetatable({}, ModeHandler)
    self.PlayerPart = playerPart
    self.Mode = "Cube"
    self.GravityDirection = -1
    self.Held = false
    self.LastPortal = nil
    self:apply("Cube")
    return self
end

function ModeHandler:apply(mode)
    local definition = self.ModeDefinitions[mode]
    self.Mode = mode
    self.PlayerPart.Shape = definition.Shape
    self.PlayerPart.Size = definition.Size
    self.PlayerPart.Material = definition.Material
end

function ModeHandler:setHeld(isHeld)
    self.Held = isHeld
end

function ModeHandler:flipGravity()
    self.GravityDirection *= -1
end

function ModeHandler:reset()
    self.LastPortal = nil
    self.GravityDirection = -1
    self.Held = false
    self:apply("Cube")
end

local MovementHandler = {}
MovementHandler.__index = MovementHandler

function MovementHandler.new(playerPart, modeHandler)
    local self = setmetatable({}, MovementHandler)
    self.PlayerPart = playerPart
    self.ModeHandler = modeHandler
    self.Position = Config.SpawnPosition
    self.Velocity = Vector3.new(Config.ForwardSpeed, 0, 0)
    self.Rotation = 0
    self.IsGrounded = false
    return self
end

function MovementHandler:reset()
    self.Position = Config.SpawnPosition
    self.Velocity = Vector3.new(Config.ForwardSpeed, 0, 0)
    self.Rotation = 0
    self.IsGrounded = false
    self.PlayerPart.CFrame = CFrame.new(self.Position)
    self.PlayerPart.AssemblyLinearVelocity = Vector3.zero
    self.PlayerPart.AssemblyAngularVelocity = Vector3.zero
end

function MovementHandler:isOnGround()
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {self.PlayerPart, self.PlayerPart.Parent}
    local direction = Vector3.new(0, Config.GroundRayLength * self.ModeHandler.GravityDirection, 0)
    local result = Workspace:Raycast(self.Position, direction, rayParams)
    return result ~= nil and result.Instance and not result.Instance:GetAttribute("IsHazard")
end

function MovementHandler:jump()
    local mode = self.ModeHandler.Mode
    if mode == "Cube" and self.IsGrounded then
        self.Velocity = Vector3.new(Config.ForwardSpeed, Config.JumpVelocity * -self.ModeHandler.GravityDirection, 0)
    elseif mode == "Ball" then
        self.ModeHandler:flipGravity()
        self.Velocity = Vector3.new(Config.ForwardSpeed, -self.Velocity.Y, 0)
    end
end

function MovementHandler:update(dt)
    local mode = self.ModeHandler.Mode
    self.IsGrounded = self:isOnGround()

    if mode == "Cube" or mode == "Ball" then
        local gravityStep = Config.Gravity * self.ModeHandler.GravityDirection * dt
        self.Velocity = Vector3.new(Config.ForwardSpeed, self.Velocity.Y + gravityStep, 0)
        if self.IsGrounded then
            self.Velocity = Vector3.new(Config.ForwardSpeed, math.max(0, self.Velocity.Y) * 0, 0)
            self.Rotation = math.round(self.Rotation / (math.pi / 2)) * (math.pi / 2)
        else
            self.Rotation += Config.RotationSpeed * dt * (self.ModeHandler.GravityDirection == -1 and -1 or 1)
        end
    elseif mode == "Ship" then
        local lift = self.ModeHandler.Held and Config.ShipLift or -Config.Gravity
        self.Velocity = Vector3.new(Config.ForwardSpeed, self.Velocity.Y + lift * dt, 0)
        self.Rotation = math.clamp(self.Velocity.Y / 80, -0.8, 0.8)
    elseif mode == "Wave" then
        local diagonal = self.ModeHandler.Held and 1 or -1
        self.Velocity = Vector3.new(Config.ForwardSpeed, diagonal * Config.WaveSpeed, 0)
        self.Rotation = diagonal * 0.75
    end

    self.Position += self.Velocity * dt

    if self.IsGrounded and (mode == "Cube" or mode == "Ball") then
        local correction = Vector3.new(0, (Config.GridUnit / 2) * -self.ModeHandler.GravityDirection, 0)
        local origin = self.Position + correction
        local rayDirection = Vector3.new(0, Config.GridUnit * self.ModeHandler.GravityDirection, 0)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {self.PlayerPart, self.PlayerPart.Parent}
        local result = Workspace:Raycast(origin, rayDirection, rayParams)
        if result then
            local halfHeight = self.PlayerPart.Size.Y / 2
            self.Position = Vector3.new(self.Position.X, result.Position.Y + (halfHeight * -self.ModeHandler.GravityDirection), self.Position.Z)
        end
    end

    self.PlayerPart.CFrame = CFrame.new(self.Position) * CFrame.Angles(0, 0, self.Rotation)
    self.PlayerPart.AssemblyLinearVelocity = Vector3.zero
    self.PlayerPart.AssemblyAngularVelocity = Vector3.zero
end

local CollisionHandler = {}
CollisionHandler.__index = CollisionHandler

function CollisionHandler.new(levelLoader)
    local self = setmetatable({}, CollisionHandler)
    self.LevelLoader = levelLoader
    return self
end

function CollisionHandler:isColliding(playerPart, targets)
    local touching = Workspace:GetPartsInPart(playerPart)
    for _, hit in ipairs(touching) do
        for _, target in ipairs(targets) do
            if hit == target then
                return target
            end
        end
        if hit:GetAttribute("IsHazard") then
            return hit
        end
    end
    return nil
end

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new(playerPart)
    local self = setmetatable({}, CameraController)
    self.PlayerPart = playerPart
    return self
end

function CameraController:update()
    currentCamera.CameraType = Enum.CameraType.Scriptable
    local targetPosition = self.PlayerPart.Position + Config.CameraOffset
    currentCamera.CFrame = CFrame.new(targetPosition, self.PlayerPart.Position + Vector3.new(12, 4, 0))
end

local PlayerController = {}
PlayerController.__index = PlayerController

function PlayerController.new(root)
    local self = setmetatable({}, PlayerController)
    self.Root = root
    self.Model = Instance.new("Model")
    self.Model.Name = "PlayerModel"
    self.Model.Parent = root

    self.MainPart = Instance.new("Part")
    self.MainPart.Name = "MainPart"
    self.MainPart.Size = Vector3.new(Config.GridUnit, Config.GridUnit, Config.GridUnit)
    self.MainPart.Color = Config.Colors.Player
    self.MainPart.Material = Enum.Material.Neon
    self.MainPart.CanCollide = true
    self.MainPart.Anchored = false
    self.MainPart.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
    self.MainPart.Parent = self.Model
    self.Model.PrimaryPart = self.MainPart

    local face = Instance.new("Decal")
    face.Face = Enum.NormalId.Front
    face.Texture = "rbxassetid://13408257"
    face.Parent = self.MainPart

    local emitterAttachment = Util:createAttachment(self.MainPart)

    self.JumpBurst = Instance.new("ParticleEmitter")
    self.JumpBurst.Name = "JumpBurst"
    self.JumpBurst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    self.JumpBurst.Rate = 0
    self.JumpBurst.Speed = NumberRange.new(5, 10)
    self.JumpBurst.Lifetime = NumberRange.new(0.2, 0.35)
    self.JumpBurst.SpreadAngle = Vector2.new(180, 180)
    self.JumpBurst.Color = ColorSequence.new(Config.Colors.Accent, Config.Colors.Player)
    self.JumpBurst.Parent = emitterAttachment

    self.TrailA = Util:createAttachment(self.MainPart, Vector3.new(0, Config.GridUnit * 0.35, 0))
    self.TrailB = Util:createAttachment(self.MainPart, Vector3.new(0, -Config.GridUnit * 0.35, 0))
    self.Trail = Instance.new("Trail")
    self.Trail.Attachment0 = self.TrailA
    self.Trail.Attachment1 = self.TrailB
    self.Trail.Color = ColorSequence.new(Config.Colors.Player, Config.Colors.Accent)
    self.Trail.LightEmission = 1
    self.Trail.Lifetime = 0.18
    self.Trail.Enabled = false
    self.Trail.Parent = self.MainPart

    self.ModeHandler = ModeHandler.new(self.MainPart)
    self.MovementHandler = MovementHandler.new(self.MainPart, self.ModeHandler)

    return self
end

function PlayerController:emitJumpFx()
    self.JumpBurst:Emit(16)
end

function PlayerController:setMode(mode)
    self.ModeHandler:apply(mode)
    self.Trail.Enabled = (mode == "Ship" or mode == "Wave")
end

function PlayerController:reset()
    self.ModeHandler:reset()
    self:setMode("Cube")
    self.MovementHandler:reset()
    self.MainPart.Color = Config.Colors.Player
    self.MainPart.Transparency = 0
end

function PlayerController:kill(onFinished)
    self.MainPart.Transparency = 1
    self.Trail.Enabled = false

    local fragmentOffsets = {
        Vector3.new(-0.4, -0.4, 0),
        Vector3.new(0.4, -0.4, 0),
        Vector3.new(-0.4, 0.4, 0),
        Vector3.new(0.4, 0.4, 0),
        Vector3.new(-0.2, 0, -0.2),
        Vector3.new(0.2, 0, -0.2),
        Vector3.new(-0.2, 0, 0.2),
        Vector3.new(0.2, 0, 0.2),
    }
    local fragmentVelocities = {
        Vector3.new(-18, 18, 0),
        Vector3.new(18, 18, 0),
        Vector3.new(-12, 24, 0),
        Vector3.new(12, 24, 0),
        Vector3.new(-10, 14, -4),
        Vector3.new(10, 14, -4),
        Vector3.new(-10, 14, 4),
        Vector3.new(10, 14, 4),
    }

    for index, offset in ipairs(fragmentOffsets) do
        local fragment = Instance.new("Part")
        fragment.Size = Vector3.new(0.6, 0.6, 0.6)
        fragment.CFrame = self.MainPart.CFrame * CFrame.new(offset)
        fragment.Color = Config.Colors.Hazard
        fragment.Material = Enum.Material.Neon
        fragment.CanCollide = false
        fragment.Anchored = false
        fragment.Parent = Workspace
        fragment.AssemblyLinearVelocity = fragmentVelocities[index]
        Debris:AddItem(fragment, 0.45)
    end

    local flash = Instance.new("ColorCorrectionEffect")
    flash.TintColor = Config.Colors.Hazard
    flash.Brightness = 0.1
    flash.Parent = game:GetService("Lighting")
    TweenService:Create(flash, TweenInfo.new(0.25), {Brightness = 0, Saturation = 0}):Play()
    Debris:AddItem(flash, 0.3)

    task.delay(Config.RestartDelay, onFinished)
end

local GameController = {}
GameController.__index = GameController

function GameController.new()
    local self = setmetatable({}, GameController)
    self.WorldRoot = Instance.new("Folder")
    self.WorldRoot.Name = "DashersWorld"
    self.WorldRoot.Parent = Workspace

    self.LevelRoot = Instance.new("Folder")
    self.LevelRoot.Name = "Level"
    self.LevelRoot.Parent = self.WorldRoot

    self.PlayerRoot = Instance.new("Folder")
    self.PlayerRoot.Name = "Actors"
    self.PlayerRoot.Parent = self.WorldRoot

    self.LevelLoader = LevelLoader.new(self.LevelRoot)
    self.PlayerController = PlayerController.new(self.PlayerRoot)
    self.CollisionHandler = CollisionHandler.new(self.LevelLoader)
    self.CameraController = CameraController.new(self.PlayerController.MainPart)
    self.IsAlive = true
    self.Connection = nil
    return self
end

function GameController:spawnLevel()
    self.LevelLoader:build()
    self.PlayerController:reset()
    Workspace.Gravity = 0
end

function GameController:restart()
    self.IsAlive = true
    self.PlayerController:reset()
end

function GameController:onInputBegan(input, processed)
    if processed or not self.IsAlive then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
        or input.KeyCode == Enum.KeyCode.Space then
        self.PlayerController.ModeHandler:setHeld(true)
        self.PlayerController.MovementHandler:jump()
        self.PlayerController:emitJumpFx()
    end
end

function GameController:onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
        or input.KeyCode == Enum.KeyCode.Space then
        self.PlayerController.ModeHandler:setHeld(false)
    end
end

function GameController:checkPortals()
    local playerPart = self.PlayerController.MainPart
    local portal = self.CollisionHandler:isColliding(playerPart, self.LevelLoader.Portals)
    if portal and portal ~= self.PlayerController.ModeHandler.LastPortal then
        self.PlayerController.ModeHandler.LastPortal = portal
        self.PlayerController:setMode(portal:GetAttribute("PortalMode"))
        self.PlayerController:emitJumpFx()
    end
end

function GameController:checkHazards()
    local playerPart = self.PlayerController.MainPart
    local hazard = self.CollisionHandler:isColliding(playerPart, self.LevelLoader.Hazards)
    local outOfBounds = playerPart.Position.Y < -28 or playerPart.Position.Y > 44 or playerPart.Position.X > self.LevelLoader.CourseLength + 20
    if (hazard or outOfBounds) and self.IsAlive then
        self.IsAlive = false
        self.PlayerController:kill(function()
            self:restart()
        end)
    end
end

function GameController:update(dt)
    if not self.IsAlive then
        self.CameraController:update()
        return
    end

    self.PlayerController.MovementHandler:update(dt)
    self:checkPortals()
    self:checkHazards()
    self.CameraController:update()
end

function GameController:start()
    self:spawnLevel()

    UserInputService.InputBegan:Connect(function(input, processed)
        self:onInputBegan(input, processed)
    end)

    UserInputService.InputEnded:Connect(function(input)
        self:onInputEnded(input)
    end)

    self.Connection = RunService.RenderStepped:Connect(function(dt)
        self:update(dt)
    end)
end

local gameController = GameController.new()
gameController:start()
