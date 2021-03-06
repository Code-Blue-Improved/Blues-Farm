include("shared.lua")

local pourOffset = Vector(-17,0,0)

function ENT:Initialize()
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self.bfarm = {}
	self.partsReady = false
	self.partTimer = 0
	self:UseClientSideAnimation()
	self.openAmount = 0.0
	self.waterAmount = 0.0
	self.prefAngle = Angle(0,0,0)
end

local DirtParticleMaterial = Material("models/bluechu/bfarm/part_water.png")

function ENT:CreatePartSystem()
	self.emitter = ParticleEmitter(self:GetPos(), false)
	self.partsReady = true
	self.partTimer = 0
end

local icon_water = Material("models/bluechu/bfarm/icon_water.png","noclamp smooth")

function ENT:Think()
	self.prefAngle = LerpAngle(15*FrameTime(), self.prefAngle, self:GetPreferedAngles())
	local isOpen = false
	local tr = util.TraceLine( {
	start = self:GetPos() - pourOffset,
	endpos = (self:GetPos() - pourOffset) + Vector(0,0,-150),
	filter = {self}
} )

	if tr.Entity ~= nil and tr.Entity ~= NULL  then
		if tr.Entity:GetClass() == "bfarm_pot_01" or tr.Entity:GetClass() == "bfarm_pot_04" then
		isOpen = true
		end 
	end
	if isOpen then
		self.openAmount = Lerp(8*FrameTime()  ,self.openAmount , 1)
	else
		self.openAmount = Lerp(8*FrameTime()  ,self.openAmount , 0)
	end
	self.waterAmount = Lerp(3 * FrameTime() , self.waterAmount , self:GetWaterAmount()/1000.0)
	self.partTimer = self.partTimer - FrameTime()
	if self.partsReady and self:GetIsPouring() and self.partTimer <= 0 then
	  local part = self.emitter:Add(DirtParticleMaterial,self:GetPos() - pourOffset)
		if part then
			part:SetColor(math.random(120 , 180),math.random(120,180),math.random(200,255),100)
			part:SetVelocity(Vector(0,0,-math.random(30,80)))
			part:SetDieTime(math.random(0.4 , 1.2))
			part:SetLifeTime(0)
			part:SetStartSize(math.random(0.1,5))
			part:SetEndSize(math.random(5 , 15))
		end
		self.partTimer = 0.005
	end
	self:SetFlexWeight(0 , self.openAmount)
	self:SetFlexWeight(1 , self.waterAmount)
end 

function ENT:Draw()

	--render.DrawLine(self:GetPos() - pourOffset, (self:GetPos() - pourOffset) - Vector(0,0,75) , Color(0,0,255,255) , true)
	if self:GetIsPouring() and LocalPlayer():GetPos():Distance(self:GetPos()) < 600 then
		local drawDirt = false
		local tr = util.TraceLine( {
			start = self:GetPos() - pourOffset,
			endpos = (self:GetPos() - pourOffset) + Vector(0,0,-150),
			filter = {self}
		} )
		if tr.Entity ~= nil and tr.Entity ~= NULL then
			if tr.Entity:GetClass() == "bfarm_pot_01" or tr.Entity:GetClass() == "bfarm_pot_04" then
				drawDirt = true
			end 
		end
		if not self.partsReady and drawDirt then
			self:CreatePartSystem()
		end
		if drawDirt then
			self.emitter:SetPos(self:GetPos())
		end
	elseif self.partsReady then
		self.partsReady = false
		self.emitter:Finish()
		self:SetRenderAngles(self:GetLocalAngles())
	end
	if self:GetCarrierID() == LocalPlayer():UserID() then
		self:SetRenderAngles(self.prefAngle)
	else
		self:SetRenderAngles(self:GetLocalAngles())
	end
	self:DrawModel()

	--Draw Display
	if LocalPlayer():GetPos():Distance(self:GetPos()) < 400 then
		if self:GetCarrierID() == LocalPlayer():UserID() then
			render.DrawLine(self:GetPos() - pourOffset, (self:GetPos() - pourOffset) + Vector(0,0,-150), Color(50,75,200,150),true)
		end
		local alpha = (LocalPlayer():GetPos():Distance(self:GetPos()) / 300.0)
		alpha = math.Clamp(1.25 - alpha, 0 ,1)
		local a = Angle(0,0,0)
		a:RotateAroundAxis(Vector(1,0,0),90)
		a.y = LocalPlayer():GetAngles().y - 90
		cam.Start3D2D(self:GetPos() + Vector(0,0,19), a , 0.10)

			draw.RoundedBox(8,-50,-100,100,100 , Color(45,45,45,255 * alpha))
			local tri = {{x = -25 , y = 0},{x = 25 , y = 0},{x = 0 , y = 25}}
			surface.SetDrawColor(Color(45,45,45,255 * alpha))
			draw.NoTexture()
			surface.DrawPoly( tri )

			--Draw Soil
			surface.SetDrawColor(Color(123/2,156/2,255/2 , 255 * alpha))
			draw.Circle(0, 50 - 100 , 45, 18)

			surface.SetDrawColor(Color(123,156,255 , 255 * alpha))
			draw.Circle(0, 50 - 100 , 45, 18 , self.waterAmount * 100)

			surface.SetDrawColor(Color(60,60,60,255 * alpha))
			draw.Circle(0, 50 - 100 , 35, 18)

			surface.SetDrawColor(Color(123,156,255 , 255 * alpha))
			surface.SetMaterial(icon_water)
			surface.DrawTexturedRect( -25 , 50 - 100 - 25 , 50 , 50)
			draw.NoTexture()

		cam.End3D2D()
	end
end
