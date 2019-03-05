/*
 * Andrew Tollett, 2019
 * This is some compiled snippets of code from my Zombie Survival overhaul.
 * This is the displaying and clientside backend of the Arsenal Upgrade menu,
 * which displays 3 options of items, with a rendered 3d model, stats, and
 * a description of each items. reference screenshot available here:
 * https://github.com/orecros/orecros.github.io/blob/master/tzs2.jpg
 *
 * Upgrade cards render ITEMS, which has 2 mutually-exclusive types: "SITEM"
 * and "SWEP", and as such need to handle displaying both types.
 *
 * All of the code on this page was written by me for use in this project.
 */

CARD_COLOR_1 = Color(0,0,0,255)
CARD_COLOR_2 = Color(50,50,50,255)
CARD_COLOR_BASE = Color(100,100,100,125)
CARD_COLOR_BASE_HOVERED = Color(150,150,150,125)

--on every game tick...
hook.Add("Think", "UpgradeMenuThink", function()
	local pan = GAMEMODE.UpgradeInterface
	if pan and pan:IsValid() and pan:IsVisible() then

		--highlight whatever cards you are hovering
		if(GAMEMODE.UpgradeCards) then
			for k = 1, 3 do
				local card = GAMEMODE.UpgradeCards[k]
				if card.button:IsHovered() then
					card.base.Paint = function(self, w, h)
						local col = CARD_COLOR_BASE_HOVERED
						draw.RoundedBox( 10, 0, 0, w, h, col)
					end
				else
					card.base.Paint = function(self, w, h)
						local col = CARD_COLOR_BASE
						draw.RoundedBox( 10, 0, 0, w, h, col)
					end
				end
			end
		end


		--causes the menu to close if you quickly mouse out of it
		local mx, my = gui.MousePos()
		local x, y = pan:GetPos()
		if mx < x - 16 or my < y - 16 or mx > x + pan:GetWide() + 16 or my > y + pan:GetTall() + 16 then
			pan:SetVisible(false)
		end
	end
end)

--center mouse on upgrade menu
local function UpgradeMenuCenterMouse(self)
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	gui.SetMousePos(x + w / 2, y + h / 2)
end

----------------------------UPGRADING-------------------------------------------
--set one of the cards to display an item
--set this card to display the supplied item
function GM:SetCard( card, scale, item )

	if( item.item ) then
		self:LazyLoadSwepStats( item.item )
	end

	local sweptable = item.item or weapons.Get(item.swep)

	--update model
	card.modelPanel:SetModel( sweptable.WorldModel )
	card.modelPanel:SetAlpha( 255 )
	local mins, maxs = card.modelPanel.Entity:GetRenderBounds()
	card.modelPanel:SetCamPos(mins:Distance(maxs) * Vector(0.75, 0.75, 0.5))
	card.modelPanel:SetLookAt((mins + maxs) / 2)

	--update ammo sprite
	if item.swep and self:HasPurchaseableAmmo(sweptable) and self.AmmoNames[string.lower(sweptable.Primary.Ammo)] then
		local lower = string.lower(sweptable.Primary.Ammo)
		local ki = killicon.Get(self.AmmoIcons[lower])
  	card.ammoIcon:SetImage(ki[1])
  	if ki[2] then 	card.ammoIcon:SetImageColor(ki[2]) end
    card.ammoIcon:SetAlpha(255)
  else
    card.ammoIcon:SetAlpha(0)
  end

	--update name
	card.namePanel:SetText( translate.Get(sweptable.TranslationName,sweptable.PrintName ))

	--update description
	card.descPanel:SetText( translate.Get(sweptable.TranslationDesc,sweptable.Description or ""))

	--update chart bar heights
	local Stats = {
		sweptable.StatDPS or 0,
    sweptable.StatDPR or 0,
    sweptable.StatRange or 0,
    sweptable.StatSpecial or 0
	}
	for n, bar in ipairs(card.chartBars) do
    local statFrac = Stats[n]/5
    bar:SetTall(statFrac * card.chartHeight - 5 * scale)
    bar:AlignBottom()
  end

	--update weapon stat text
	local text = ""
	if sweptable.Stats then
		text = sweptable.Stats
	elseif sweptable.Base ~= "weapon_zs_basemelee" then
    if(sweptable.Primary.Damage) then
			text = "DAM: " .. sweptable.Primary.Damage
    	if sweptable.Primary.NumShots and sweptable.Primary.NumShots > 1 then
      	text = text .. "x" .. sweptable.Primary.NumShots .. "\n"
    	else
				text = text .. "\n"
			end
		end
		if(sweptable.Primary.Delay) then
	    local rof = string.format("%.2f",tostring(1 / sweptable.Primary.Delay))
	    text = text .. "RATE/s: " .. rof .. "\n"
		end
		if(sweptable.Primary.ClipSize) then
	    text = text .. "CLIP: " .. sweptable.Primary.ClipSize .. "\n"
		end
		if(sweptable.ConeMin and sweptable.ConeMax) then
			text = text .. "CONEm: " .. sweptable.ConeMin .. "\n"
			text = text .. "CONEM: " .. sweptable.ConeMax .. "\n"
		end
		if(sweptable.ReloadSpeed) then
	    text = text .. "RELOAD:" .. sweptable.ReloadSpeed .. "\n"
		end
		if(sweptable.WeightClass) then
    	text = text .. "WEIGHT: " .. self.WeightToText[sweptable.WeightClass] .. "\n"
		end
  else
    --create stats text if it's a melee
    text = "DAM: " .. sweptable.MeleeDamage
    text = text .. "\n" .. "RANGE: " .. sweptable.MeleeRange
    local rof = string.format("%.2f",tostring(1 / sweptable.Primary.Delay))
    text = text .. "\n" .. "RATE/s: " .. rof
    text = text .. "\n" .. "WEIGHT: " .. self.WeightToText[sweptable.WeightClass]
  end

	card.statsPanel:SetText(text)
end

--set this card to display nothing
function GM:ResetCard( card, scale )
	--update model
	card.modelPanel:SetAlpha( 0 )

	--update ammo sprite
  card.ammoIcon:SetAlpha(0)

	--update name
	card.namePanel:SetText( "" )

	--update description
	card.descPanel:SetText( "" )

	--update chart bar heights
	for n, bar in ipairs(card.chartBars) do
    bar:SetTall(0)
    bar:AlignBottom()
  end

	--update weapon stat text
	local text = ""
	card.statsPanel:SetText(text)
end

--load in the new list of upgrades and fix the menu
function GM:RegenerateUpgradeMenu()

		if self.UpgradeInterface and self.UpgradeInterface:IsValid() then
			local isOpen = self.UpgradeInterface.IsVisible
			self.UpgradeInterface:Remove()
			if isOpen then
				self:OpenUpgradeMenu(true)
			end
		end
end

--check if this particular upgrade weapon has purchaseable ammo
function GM:UpgradeHasAmmo( uptab )

	local tab = GM:GetItemFromUpgrade( uptab )

	return self:HasPurchaseableAmmo( tab )
end

--get the item table for this particular upgrade
function GM:GetItemFromUpgrade( uptab )
	local sig = uptab.signature
	local tab = self.Items[sig] or self.Items["ps_" .. sig]
	return tab
end

----------------------------GUI CREATION----------------------------------------
--Create a card
--Create the upgrade menu
function GM:OpenUpgradeMenu(wasOpen)

	local debug = false --refresh upgrade menu every open

	if not self.IsUpgrade then
		if !wasOpen then
			local key = self:GuessNextUpgrade()
			if(key) then --self.UpgradeGroups[key]
				self:CenterNotify(COLOR_ORANGE, translate.Format("no_upgrade_till_x",self.UpgradeGroups[key].points))
			else
				self:CenterNotify(COLOR_ORANGE, translate.Get("no_more_upgrades"))
			end
		end
		return
	end

	if self.UpgradeInterface and self.UpgradeInterface:IsValid() then

		if debug then
			self.UpgradeInterface:Remove()
		else
			self.UpgradeInterface:SetVisible(true)
			self.UpgradeInterface:CenterMouse()
			return
		end
	end

	--creates some size variables
	local screenscale = BetterScreenScale()
	local widMax = ScrW()
	GUISCALE = (math.min(widMax, 1100) * screenscale) / 1100
	local scale = GUISCALE
	local wid, hei = scale * 1100, scale * 600
	local tabhei = 24 * screenscale

	--create the big box
	local frame = vgui.Create("DFrame")
	frame:SetSize(wid, hei)
	frame:Center()
	frame:SetDeleteOnClose(false)
	frame:SetTitle(" ")
	frame:SetDraggable(false)
	if frame.btnClose and frame.btnClose:IsValid() then frame.btnClose:SetVisible(false) end
	if frame.btnMinim and frame.btnMinim:IsValid() then frame.btnMinim:SetVisible(false) end
	if frame.btnMaxim and frame.btnMaxim:IsValid() then frame.btnMaxim:SetVisible(false) end
	frame.CenterMouse = UpgradeMenuCenterMouse
	frame.Think = UpgradeMenuThink
	self.UpgradeInterface = frame

	--create top part
	local topSpace = vgui.Create("DPanel", frame)
	topSpace:SetWide(wid- 20 * scale)
	topSpace:SetTall(70 * scale)

	topSpace:AlignTop(10 * scale)
	topSpace:CenterHorizontal()
	topSpace.Paint = function(self, w, h)
		local col = Color(0,0,0,125)
		draw.RoundedBox( 10, 0, 0, w, h, col)
	end

	--add "CHOOSE ONE" text
	local text = self.UpgradeGroups[self.UpgradeGroup].name .. ": Choose One"
	local chooseLabel = EasyLabel(topSpace, text, "ZSHUDFontSmall", COLOR_WHITE)
	chooseLabel:CenterHorizontal()
	chooseLabel:CenterVertical()

	local cardSpacing = 365

	self.UpgradeCards = {}
	for n = -1, 1 do
		local card = self:CreateCard( frame, scale )
		self:SetCard( card, scale, self.UpgradeItems[n+2] )
		card.base:CenterHorizontal()
		--GetPos() returns x value first, and setPos sets x value first
		card.base:SetPos(card.base:GetPos() + n * cardSpacing * scale)
		card.base:AlignBottom(10 * scale)

		card.button:SetPos(card.base:GetPos())
		card.button.DoClick = function()
			RunConsoleCommand("zs_selectupgrade",tostring(n+2))
		end

		self.UpgradeCards[n+2] = card

		--Cards[n+2] = card
	end

	--CleanUp
	frame:MakePopup()
	if(not wasOpen) then
		frame:CenterMouse()
	end
end
--Create one of the three cards in the menu
function GM:CreateCard( parent, scale, item )

	local card = {}
	card.base = vgui.Create("DPanel", parent)

	--create card base
	card.base:SetWide(350 * scale)
	card.base:SetTall(500 * scale)
	card.base.Paint = function(self, w, h)
		local col = CARD_COLOR_BASE
		draw.RoundedBox( 10, 0, 0, w, h, col)
	end

	--create top panel
	self:CreateCardTopPanel( card, scale )

	--create description panel
	self:CreateCardDescPanel( card, scale )

	--create chart panel
	self:CreateCardChartPanel( card, scale )

	--create stats panel
	self:CreateCardStatsPanel( card, scale )

	--draw button on top
	card.button = vgui.Create("DButton", parent)
	--create card base
	card.button:SetWide(card.base:GetWide())
	card.button:SetTall(card.base:GetTall())
	card.button:SetText("")
	card.button.Paint = function(self, w, h)
	end

	return card
end
--Create the model/ammo type display on the top section of the card
function GM:CreateCardTopPanel( card, scale )
	--create base rectangle
	local topPanel = vgui.Create("DPanel", card.base)
	topPanel:SetWide(330 * scale)
	topPanel:SetTall(180 * scale)
	topPanel:AlignTop(10 * scale)
	topPanel.Paint = function(self, w, h)
		local col = CARD_COLOR_1
		draw.RoundedBox( 6, 0, 0, w, h, col)
	end
	topPanel:CenterHorizontal()

	--create the model as displayed in the top section
	local mdlpanel = vgui.Create("DModelPanel", topPanel)
	mdlpanel:Dock( FILL )
	mdlpanel:SetModel( "models/props_junk/TrafficCone001a.mdl" )
	mdlpanel:SetAlpha(0)
	--DModelPanel inherits from DButton, so we need to disable the button part
	mdlpanel:SetEnabled(false)

	card.modelPanel = mdlpanel

	--create the ammo icon in the top left
	local ammoIcon = vgui.Create("DImage", topPanel)
	local ki = killicon.Get(self.AmmoIcons["pistol"])
	ammoIcon:SetImage(ki[1])
	ammoIcon:SetSize(40 * scale, 40 * scale)
	ammoIcon:AlignLeft(5 * scale)
	ammoIcon:AlignTop(5 * scale)
	ammoIcon:SetAlpha(0)

	card.ammoIcon = ammoIcon
end
--create the middle panel with the name and description of the card
function GM:CreateCardDescPanel( card, scale )

	--create panel
	local descPanel = vgui.Create("DPanel", card.base)
	descPanel:SetWide(330 * scale)
	descPanel:SetTall(100 * scale)
	descPanel:AlignTop( 200 * scale)
	descPanel:CenterHorizontal()
	descPanel.Paint = function(self, w, h)
		local col = CARD_COLOR_1
		draw.RoundedBox( 6, 0, 0, w, h, col)
	end

	--draw name
	local title = EasyLabel(descPanel, "", "ZSHUDFontSmaller", COLOR_WHITE)
	title:SetSize(descPanel:GetWide() - 10 * scale, 30 * scale)
	title:SetContentAlignment(7) --top left
	title:AlignTop(5 * scale)
	title:AlignLeft(5 * scale)

	card.namePanel = title

	--get description
	local text = ""

	--draw description
	local desc = EasyLabel(descPanel, text, "ZSBodyTextFont", COLOR_GRAY)
	desc:SetSize(descPanel:GetWide() - 10 * scale, descPanel:GetTall() - 25 * scale)
	desc:SetContentAlignment(7) --topleft (look at numpad)
	desc:AlignLeft(5 * scale)
	desc:AlignTop(35 * scale)
	desc:SetWrap(true)
	desc:SetMultiline(true)

	card.descPanel = desc
end
--create the chart panel in the bottom left with the green bars
function GM:CreateCardChartPanel( card, scale )

	--create chart panel
	local chart = vgui.Create("DPanel", card.base)
	chart:SetWide(220 * scale)
	chart:SetTall(180 * scale)
	chart:AlignBottom(10 * scale)
	chart:AlignLeft(10 * scale)

	chart.Paint = function(self, w, h)
		local col = CARD_COLOR_2
		draw.RoundedBox( 6, 0, 0, w, h, col)
	end

	--darken top section
	local topBar = vgui.Create("DPanel", chart)
	topBar:SetWide(chart:GetWide())
	topBar:SetTall(chart:GetTall() - topBar:GetWide()/4)
	topBar:AlignTop()
	topBar:AlignLeft()
	topBar.Paint = function(self, w, h)
		local col = CARD_COLOR_1
		draw.RoundedBox( 6, 0, 0, w, h/2, col)
		draw.RoundedBox( 0, 0, h/2, w, h, col)
	end


	local width = topBar:GetWide() / 4

	--draw icons
	local Icons = {
		"materials/tropical/stat_dps.png",
		"materials/tropical/stat_dpr.png",
		"materials/tropical/stat_range.png",
		"materials/tropical/stat_utility.png"
	}
	for n = 0, 3 do
		local icon = vgui.Create("DImage",chart)
		icon:SetImage(Icons[n+1])
		icon:SetSize(width * scale, width * scale)
		icon:AlignBottom()
		icon:AlignLeft()
		local x, y = icon:GetPos()
		icon:SetPos(x + n * width * scale, y)
	end

	card.chartBars = {}
	card.chartHeight = topBar:GetTall()

	local thickness = 0.85 --as a fraction of the space to fill

	for n = 0, 3 do
		local bar = vgui.Create("DPanel", topBar)
		bar:SetWide(width * thickness * scale)
		bar:SetTall(0)
		bar:AlignBottom()
		bar:AlignLeft(width * (1 - thickness) / 2 * scale)
		local x, y = bar:GetPos()
		bar:SetPos(x + n * width * scale, y)

		bar.Paint = function(self, w, h)
			local col = Color(200,255,200,255)
			draw.RoundedBox( 0, 0, 0, w, h, col)
		end

		card.chartBars[n+1] = bar
	end

	local doDrawLines = true

	if(doDrawLines) then

		local h = topBar:GetTall() - 5 * scale

		--draw lines across at all the stat points
		for n = 0, 4 do
			local line = vgui.Create("DPanel", topBar)
			line:SetWide(topBar:GetWide())
			line:SetTall(2 * scale)
			line:AlignBottom()
			line:AlignLeft()
			local x, y = line:GetPos()
			line:SetPos(x, y - n/5 * h + 1 * scale)

			line.Paint = function(self, w, h)
				local col = CARD_COLOR_1
				draw.RoundedBox( 0, 0, 0, w, h, col)
			end
		end
	end
end
--create the stats panel with the in-depth stats of the card
function GM:CreateCardStatsPanel( card, scale )

	local statsBackground = vgui.Create("DPanel", card.base)
	statsBackground:SetWide(100 * scale)
	statsBackground:SetTall(180 * scale)
	statsBackground:AlignBottom(10 * scale)
	statsBackground:AlignRight(10 * scale)
	statsBackground.Paint = function(self, w, h)
		local col = CARD_COLOR_1
		draw.RoundedBox( 6, 0, 0, w, h, col)
	end


	local text = ""

	--draw stats
	local statsPanel = EasyLabel(statsBackground, text, "ZSBodyTextFont", COLOR_GRAY)
	statsPanel:SetSize(statsBackground:GetWide() - 10 * scale, statsBackground:GetTall() - 10 * scale)
	statsPanel:SetContentAlignment(7) --topleft (look at numpad)
	statsPanel:AlignLeft(5 * scale)
	statsPanel:AlignTop(5 * scale)
	statsPanel:SetWrap(true)
	statsPanel:SetMultiline(true)

	card.statsPanel = statsPanel
end
