-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
-- Watertrailer fix script
--
-- Purpose: This script adds a new category to the ESC menu help section, if it doesn't exist yet.
--    If it doesn't exist, it adds the category, a main category, and a mod specific category.
--    If it does exist, it adds a mod specific category to the existing category, and updates the
--    main category if the version in this mod is higher than the other one.
-- 
-- Authors: Timmiej93
--
-- Copyright (c) Timmiej93, 2017
-- For more information on copyright for this mod, please check the readme file on Github
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --

HelpMenuAdder = {};
local modDir = g_currentModDirectory;
addModEventListener(HelpMenuAdder)

function HelpMenuAdder:loadMap()
	if g_currentMission.HelpMenuAdder == nil then
		g_currentMission.HelpMenuAdder = {};
		g_currentMission.HelpMenuAdder.categorySelectorElementTitles = {};
	end

	self:loadXML(modDir .. "scripts/helpMenu.xml");
end

function HelpMenuAdder:insertIntoGlobal(key)
	local string;
	if g_i18n:hasText(key) then
		string = g_i18n:getText(key);
	else
		string = key;
	end
    g_i18n.globalI18N:setText(key, string)
end

function HelpMenuAdder:loadXML(pathFile)
	local hma = g_currentMission.HelpMenuAdder;

	local xmlFile = loadXMLFile("helpMenu", pathFile)

	-- Check if another mod already added the main section. If it did and the version is higher than this one, skip.
	local version = getXMLFloat(xmlFile, "helpMenu#version");
	local higherVersion = true;
	if hma.version ~= nil and hma.version >= version then
		higherVersion = false;
	end

	local categoryIndex = 0;
	while true do
		local categoryKey = string.format("helpMenu.helpMenuCategory(%d)", categoryIndex);
		if not hasXMLProperty(xmlFile, categoryKey) then 
			break;
		end

		local category = {};
		category.title = getXMLString(xmlFile, categoryKey.."#title");
		category.author = getXMLString(xmlFile, categoryKey.."#author");
		category.helpLines = {};

		if not self:categoryExists() then
			self:insertIntoGlobal(category.title);
			table.insert(hma.categorySelectorElementTitles, {version = version, title = category.title})
			g_inGameMenu.helpLineCategorySelectorElement:addText(g_i18n:getText(category.title));
		else
			self:replaceCategoryElementSelectorTitle(category.title, version)
		end

		local lineIndex  = 0;
		while true do
			local lineKey = string.format("%s.helpLine(%d)", categoryKey, lineIndex );
			if not hasXMLProperty(xmlFile, lineKey) then
				break;
			end

			-- Check if this is the main T93 item that every mod contains
			if hasXMLProperty(xmlFile, lineKey.."#mainSection") and getXMLBool(xmlFile, lineKey.."#mainSection") then
				if higherVersion then
					local helpLine = self:handleMainSection(xmlFile, lineKey, version)
					if helpLine ~= nil then
						table.insert(category.helpLines, 1, helpLine)
					end
				end
			else
				local helpLine = self:handleHelpLine(xmlFile, lineKey)

				table.insert(category.helpLines, helpLine);
			end
			lineIndex = lineIndex + 1;
		end

		local categoryExists, t93Category = self:categoryExists();
		if not categoryExists then
			table.insert(g_inGameMenu.helpLineCategories, category)
		else
			for _,insertHelpLine in pairs(category.helpLines) do
				table.insert(t93Category.helpLines, insertHelpLine)
			end
		end
		categoryIndex = categoryIndex + 1;
	end

	hma.version = version;
	delete(xmlFile)
end

function HelpMenuAdder:handleMainSection(xmlFile, lineKey, version)
	local hma = g_currentMission.HelpMenuAdder;

	-- First time
	if hma.mainSectionVersion == nil then
		hma.mainSectionVersion = version
		return self:handleHelpLine(xmlFile, lineKey, true);
	else
		if version > hma.mainSectionVersion then
			hma.mainSectionVersion = version

			local helpLine = self:handleHelpLine(xmlFile, lineKey, true);

			local _, category = self:categoryExists()
			if category.helpLines[1].mainSection then
				table.remove(category, 1)
				table.insert(category, 1, helpLine)
			end
		end
	end
end

function HelpMenuAdder:handleHelpLine(xmlFile, lineKey, mainSection)
	local helpLine = {};
	helpLine.title = getXMLString(xmlFile, lineKey.."#title");
	helpLine.items = {};

	self:insertIntoGlobal(helpLine.title);

	local itemIndex  = 0;
	while true do
		local itemKey = string.format("%s.item(%d)", lineKey, itemIndex);
		if not hasXMLProperty(xmlFile, itemKey) then
			break;
		end

		local type = getXMLString(xmlFile, itemKey.."#type");
		local value = getXMLString(xmlFile, itemKey.."#value");

		if type == "text" then
			self:insertIntoGlobal(value);
		end

		if value ~= nil and (type == "text" or type == "image") then
			local item = {
				type = type,
				value = value,
				mainSection = mainSection
			}

			table.insert(helpLine.items, item);
		end

		itemIndex  = itemIndex  + 1;
	end

	return helpLine;
end

function HelpMenuAdder:categoryExists()
	for _,helpLineCategory in pairs(g_inGameMenu.helpLineCategories) do
		if helpLineCategory.author ~= nil and helpLineCategory.author == "Timmiej93" then
			return true, helpLineCategory;
		end
	end
	return false;
end

function HelpMenuAdder:replaceCategoryElementSelectorTitle(newTitle, version)
	for i,helpLineCategory in pairs(g_inGameMenu.helpLineCategories) do
		local elementTitle = helpLineCategory.title
		for _,oldTitle in pairs(g_currentMission.HelpMenuAdder.categorySelectorElementTitles) do
			if elementTitle == oldTitle.title and version > oldTitle.version then
				g_inGameMenu.helpLineCategorySelectorElement.texts[i] = g_i18n:getText(newTitle)
				self:insertIntoGlobal(newTitle);
			end
		end
	end
end

function HelpMenuAdder:keyEvent(unicode, sym, modifier, isDown) end
function HelpMenuAdder:mouseEvent(posX, posY, isDown, isUp, button) end
function HelpMenuAdder:draw() end
function HelpMenuAdder:update(dt) end