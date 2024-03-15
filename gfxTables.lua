------------------
-- ## gfxTables, Print tables like a master.
-- Have you ever been jealous of how *pretty* SQL consoles prints?
-- Here gfxTables to help!
-- it has a simple interface where you can create beautiful
-- console crafts with it.
-- @module gfxTables
-- @copyright 2024
-- @license MIT
-- @author Alejandro Alzate
--luacheck: globals self
local gfxTables = {}
gfxTables.__index = gfxTables
gfxTables._VERSION		= "0.0.0"
gfxTables._DESCRIPTION	= "Have you ever been jealous of how pretty SQL consoles prints?\nHere gfxTables to help!"
gfxTables._URL			= "github.com/alejandro-alzate/gfxTables-lua"
gfxTables._LICENSE		= [[
	MIT License

	Copyright (c) 2024 alejandro-alzate

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
	]]

function gfxTables:__tostring()
	return self:getText()
end

local ActiveTables = {}

function gfxTables:__len()
	return #self.structure.header
end

gfxTables.__name = "gfxTables Object"

function gfxTables.newTable(inputStyle, inputShowEnumerator, inputSeparateEntries, inputDefault)
	local style = inputStyle or "advanced"
	local showEnumerator = inputShowEnumerator and true or false
	local separateEntries = inputSeparateEntries and true or false
	local default = inputDefault or ""
	local newInstance = setmetatable({}, gfxTables)
	newInstance.rightPadding = 1
	newInstance.leftPadding = 1
	newInstance.style = style
	newInstance.showEnumerator = showEnumerator
	newInstance.separateEntries = separateEntries
	newInstance.structure = {}
	newInstance.structure.defaultEntryValue = default
	newInstance.structure.defaultAlign = "left"
	newInstance.structure.headerAlign = {}
	newInstance.structure.entriesAlign = {}
	newInstance.structure.header = {}
	newInstance.structure.entries = {}
	newInstance.structure.cache = {}
	newInstance.structure.cache.longestLine = {}

	table.insert(ActiveTables, newInstance)
	return newInstance
end

function gfxTables.setShowEnumerator(enable)
	if enable then self.showEnumerator = true else self.showEnumerator = false end
end
function gfxTables.getShowEnumerator() return self.showEnumerator end

function gfxTables.setSeparateEntries(enable)
	if enable then self.separateEntries = true else self.setSeparateEntries = false end
end
function gfxTables.getSeparateEntries() return self.separateEntries end

function gfxTables.setDefaultEntryValue(inputValue)
	self.defaultEntryValue = inputValue
end

function gfxTables.getSeparateEntries() return self.defaultEntryValue end

function gfxTables:setRightPadding(inputAmount)
	local amount = inputAmount or 1
	assert(
		type(amount) == "number",
		[[@param amount number Space count, 1 means a space in the right and the left
		Received type: ]] .. type(amount)
		)
	self.rightPadding = amount
end

function gfxTables:setLeftPadding(inputAmount)
	local amount = inputAmount or 1
	assert(
		type(amount) == "number",
		[[@param amount number Space count, 1 means a space in the right and the left
		Received type: ]] .. type(amount)
		)
	self.leftPadding = amount
end

function gfxTables:setPadding(inputAmount)
	local amount = inputAmount or 1
	assert(
		type(amount) == "number",
		[[@param amount number Space count, 1 means a space in the right and the left
		Received type: ]] .. type(amount)
		)
	self:setRightPadding(amount)
	self:setLeftPadding(amount)
end

function gfxTables:insertColumn(inputName, inputIndex, inputAlign, inputDefault)
	local entries = self.structure.entries
	local header = self.structure.header

	local name = inputName
	local index = inputIndex or #header + 1
	local align = inputAlign or self.structure.defaultAlign
	local default = inputDefault or self.structure.defaultEntryValue

	--Expand user input if it's lazy
	align = align == "l" and "left" or align
	align = align == "r" and "right" or align

	do --[[A Reality Check.]]
		--name
		assert(
			type(name) == "string",

			[[@param name string *The name of said column
			Received type: ]] .. type(name)
			)

		--index
		assert(
			type(index) == "number",

			[[@param index number Where do you want this column,
			when left blank it will default to last column + 1
			Received type: ]] .. type(index)
			)

		assert(
			type(align) == "string" and
			((align == "left") or (align == "right")),
			[[@param align string Use "left" or "right" for aligning this column,
			the entries will inherit this property.
			Received type: ]] .. type(align) ..
			"\nReceived value: " .. tostring(align)


			)

		--default
		assert(
			type(default) == "string",

			[[@param default string For existing entries what to use to fill in the blanks,
			default of default is ""
			Received type: ]] .. type(default)
			)
	end

	--Header poke
	table.insert(header, index, name)

	--Entries poke
	for _, v in ipairs(entries) do
		table.insert(v, index, default)
	end

	--Structure poke
	--self.structure.header = header
	--self.structure.entries = entries
	self.structure.headerAlign[index] = align
	self.structure.entriesAlign[index] = align

	self:calculateLongestLines()
end

function gfxTables:insertColumns(...)
	local columns = {...}

	for _, v in ipairs(columns) do
		self:insertColumn(v)
	end
end

function gfxTables:insertEntry(inputEntry, inputIndex)
	local entries = self.structure.entries
	local newEntry = inputEntry
	local index = inputIndex or #entries + 1

	assert(
		type(newEntry) == "table",
		[[@param entry table *A table containing the values to deposit.
		Received type: ]] .. type(newEntry)
		)
	assert(
		type(index) == "number",
		[[@param entry table *A table containing the values to deposit.
		Received type: ]] .. type(index)
		)

	table.insert(entries, index, newEntry)
	self:calculateLongestLines()
end

function gfxTables:removeColumnByIndex(inputIndex)
	local header = self.structure.header
	local entries = self.structure.entries
	local index = inputIndex or #header

	table.remove(header, index)

	for i, v in ipairs(entries) do
		print(i,v)
		if v[index] ~= nil then
			table.remove(v, index)
		end
	end
	self:calculateLongestLines()
end

function gfxTables:removeColumnByName(inputName, inputFirstHitCount, inputEnableRegex)
	local header = self.structure.header
	local entries = self.structure.entries
	local name = inputName
	local firstHitCount = inputFirstHitCount or 1
	local enableRegex = inputEnableRegex and true or false
	local indexCachedHit
	do --[[Reality Check]]
		--name
		assert(
			type(name) == "string",
			[[@param name string *How the column is called this is case sensitive
			Received type: ]]..type(name)
			)
		--firstHitCount
		assert(
			type(firstHitCount) == "number",
			[[@param firstHitCount number
			Defaults to 1, when there's column called the same this will
			ignore n occurrences of name, meaning n being 2 it will remove
			the second hit of name.
			Received type: ]] .. type(firstHitCount)
			)
		--enableRegex
		assert(
			type(enableRegex) == "boolean",
			[[@param enableRegex boolean
			Sets whether the parameter name should be treated as a :match()
			Expression.
			Received type: ]] .. type(enableRegex)
			)
	end
	for i, v in ipairs(header) do
		if enableRegex then
			if tostring(v):match(name) then
				if firstHitCount <= 1 then
					table.remove(header, i)
					indexCachedHit = i
					break
				else
					firstHitCount = inputFirstHitCount - 1
				end
			elseif name == v then
				if firstHitCount <= 1 then
					table.remove(header, i)
					indexCachedHit = i
					break
				else
					firstHitCount = inputFirstHitCount - 1
				end
			end
		end
	end
	if not indexCachedHit then return end
	for _, v in ipairs(entries) do
		table.remove(v, indexCachedHit)
	end
	self:calculateLongestLines()
end

function gfxTables:calculateLongestLines()
	local header = self.structure.header
	local entries = self.structure.entries
	local biggestLine = {}
	--Get the biggest line
	--Header
	for i, v in ipairs(header) do
		local str = tostring(v)
		local lastLenValue = biggestLine[i] or 0
		biggestLine[i] = math.max(lastLenValue, string.len(str))
	end

	--Entries
	for _, entryValue in ipairs(entries) do
		for i, v in ipairs(entryValue) do
			local str = tostring(v)
			local lastLenValue = biggestLine[i] or 0
			biggestLine[i] = math.max(lastLenValue, string.len(str))
		end
	end

	self.structure.longestLine = biggestLine
end

function gfxTables:getText(inputStart, inputFinish)
	local style						= self.style
	local leftPadding				= self.leftPadding
	local rightPadding				= self.rightPadding
	local showEnumerator			= self.showEnumerator
	local separateEntries			= self.separateEntries
	local header					= self.structure.header
	local entries					= self.structure.entries
	local align						= self.structure.headerAlign
	local longestLine				= self.structure.longestLine
	local defaultEntryValue			= self.structure.defaultEntryValue
	local enumerationLength			= tostring(#entries):len() + leftPadding + rightPadding
	local start						= inputStart or 1
	local finish					= inputFinish or #header
	local stringResult = ""
	local wallsLookUp = {
			header = {
				upperRightCorner = "+",
				upperIntersection = "+",
				upperCeiling = "-",
				upperLeftCorner = "+",
				middleLeftWall = "|",
				middleIntersection = "|",
				middleRightWall = "|",
				lowerLeftCorner = "+",
				lowerIntersection = "+",
				lowerRightCorner = "+",
			},
			entries = {
				upperRightCorner = "+",
				upperIntersection = "+",
				upperCeiling = "-",
				upperLeftCorner = "+",
				middleLeftWall = "|",
				middleIntersection = "|",
				middleRightWall = "|",
				lowerLeftCorner = "+",
				lowerIntersection = "+",
				lowerRightCorner = "+",
			}
		}

	assert(
		type(start) == "number",
		[[@param i number Start from entry #i
		Received type: ]] .. type(start)
		)
	assert(
		type(finish) == "number",
		[[@param j number End to entry #j
		Received type: ]] .. type(finish)
		)

	if #header == 0 then return end

	if style == "advanced" then
		wallsLookUp = {
			header = {
				upperRightCorner = "┓",
				upperCeiling = "━",
				upperIntersection = "┳",
				upperLeftCorner = "┏",
				middleLeftWall = "┃",
				middleIntersection = "┃",
				middleRightWall = "┃",
				lowerLeftCorner = "┡",
				lowerFloor = "━",
				lowerIntersection = "╇",
				lowerRightCorner = "┩",
				noEntryLowerLeftCorner = "┗",
				noEntryLowerFloor = "━",
				noEntryLowerIntersection = "┻",
				noEntryLowerRightCorner = "┛",
				lastLowerLeftCorner = "┡",
				lastLowerFloor = "━",
				lastLowerIntersection = "╇",
				lastLowerRightCorner = "┩",
			},
			entries = {
				upperRightCorner = "┤",
				upperCeiling = "─",
				upperIntersection = "┼",
				upperLeftCorner = "├",
				middleLeftWall = "|",
				middleIntersection = "|",
				middleRightWall = "|",
				lowerLeftCorner = "└",
				lowerFloor = "─",
				lowerIntersection = "┴",
				lowerRightCorner = "┘",
			}
		}
	end

	-- -> +------+-----------+
	-- -> ┏━━━━━━┳━━━━━━━━━━━┓
	stringResult = stringResult .. wallsLookUp.header.upperLeftCorner
	if showEnumerator then
		for _ = 1, enumerationLength do
			stringResult = stringResult .. wallsLookUp.header.upperCeiling
		end
		stringResult = stringResult .. wallsLookUp.header.upperIntersection
	end
	for i, _ in ipairs(header) do
		local length = longestLine[i] + rightPadding + leftPadding
		for _ = 1, length do
			stringResult = stringResult .. wallsLookUp.header.upperCeiling
		end
		if i == #header then
			stringResult = stringResult .. wallsLookUp.header.upperRightCorner
		else
			stringResult = stringResult .. wallsLookUp.header.upperIntersection
		end
	end

	-- -> | Name | Last name |
	-- -> ┃ Name ┃ Last name ┃
	stringResult = stringResult .. "\n" .. wallsLookUp.header.middleLeftWall
	if showEnumerator then
		local lp = ""
		local rp = ""
		local spc = ""
		for _ = 1, leftPadding do
			lp = lp .. " "
		end
		for _ = 1, rightPadding do
			rp = rp .. " "
		end
		for _ = 1, enumerationLength - lp:len() - rp:len() - 1 do
			spc = spc .. " "
		end
		stringResult = stringResult .. lp .. "#" .. spc .. rp .. wallsLookUp.header.middleIntersection
	end
	for i, headerValue in ipairs(header) do
		local al = align[i] or "left"
		local ll = longestLine[i] or 1
		local lp = ""
		local rp = ""
		local spc = ""
		local str = tostring(headerValue)
		for _ = 1, leftPadding do
			lp = lp .. " "
		end
		for _ = 1, rightPadding do
			rp = rp .. " "
		end
		for _ = 1, ll - str:len() do
			spc = spc .. " "
		end
		if al == "left" then
			str = lp .. str .. spc .. rp
		elseif al == "right" then
			str = lp .. spc .. str .. rp
		elseif al == "center" then
			str = lp .. spc:sub(1, spc:len() / 2) .. str .. spc:sub(spc:len() / 2, spc:len())
		end
		if i == #header then
			stringResult = stringResult .. str .. wallsLookUp.header.middleRightWall
		else
			stringResult = stringResult .. str .. wallsLookUp.header.middleIntersection
		end
	end

	-- -> +------+-----------+
	-- -> ┡━━━━━━╇━━━━━━━━━━━┩
	-- or when there's no entries:
	-- -> +------+-----------+
	-- -> ┗━━━━━━┻━━━━━━━━━━━┛
	stringResult = stringResult .. "\n"
	.. ((#entries == 0) and wallsLookUp.header.noEntryLowerLeftCorner or wallsLookUp.header.lowerLeftCorner)

	if showEnumerator then
		for _ = 1, enumerationLength do
			stringResult = stringResult .. wallsLookUp.header.lowerFloor
		end
		stringResult = stringResult .. wallsLookUp.header.lowerIntersection
	end
	for i, _ in ipairs(header) do
		local length = longestLine[i] + rightPadding + leftPadding
		if #entries == 0 then
			for _ = 1, length do
				stringResult = stringResult .. wallsLookUp.header.noEntryLowerFloor
			end
			if i == #header then
				stringResult = stringResult .. wallsLookUp.header.noEntryLowerRightCorner
			else
				stringResult = stringResult .. wallsLookUp.header.noEntryLowerIntersection
			end
		else
			for _ = 1, length do
				stringResult = stringResult .. wallsLookUp.header.lowerFloor
			end
			if i == #header then
				stringResult = stringResult .. wallsLookUp.header.lowerRightCorner
			else
				stringResult = stringResult .. wallsLookUp.header.lowerIntersection
			end
		end
	end

	--Don't even bother to iterate if there's nothing on what to do an iteration
	if #entries == 0 then return stringResult end

	-- -> | John | Doe       |
	-- -> ┃ John ┃ Doe       ┃
	stringResult = stringResult .. "\n"
	for i, entryTable in ipairs(entries) do
	stringResult = stringResult .. wallsLookUp.entries.middleLeftWall
		if showEnumerator then
			local lp = ""
			local rp = ""
			local spc = ""
			local str = tostring(i)
			for _ = 1, leftPadding do
				lp = lp .. " "
			end
			for _ = 1, rightPadding do
				rp = rp .. " "
			end
			for _ = 1, enumerationLength - lp:len() - rp:len() - str:len() do
				spc = spc .. " "
			end
		stringResult = stringResult .. lp .. str.. spc .. rp .. wallsLookUp.entries.middleIntersection
		end
		if i >= start then
			for k, entryValue in ipairs(entryTable) do
				--IF YOU DON'T FILL EVERYTHING THIS GETS EXPENSIVE FAST!
				while #entryTable < #header do
					table.insert(entryTable, defaultEntryValue)
					self:calculateLongestLines()
					longestLine = self.structure.longestLine
				end

				local al = align[k] or "left"
				local ll = longestLine[k] or 1
				local lp = ""
				local rp = ""
				local spc = ""
				local str = tostring(entryValue)
				for _ = 1, leftPadding do
					lp = lp .. " "
				end
				for _ = 1, rightPadding do
					rp = rp .. " "
				end
				for _ = 1, ll - str:len() do
					spc = spc .. " "
				end
				if al == "left" then
					str = lp .. str .. spc .. rp
				elseif al == "right" then
					str = lp .. spc .. str .. rp
				elseif al == "center" then
					str = lp .. spc:sub(1, spc:len() / 2) .. str .. spc:sub(spc:len() / 2, spc:len())
				end
				if k == #entryTable then
					stringResult = stringResult .. str .. wallsLookUp.entries.middleRightWall
				else
					stringResult = stringResult .. str .. wallsLookUp.entries.middleIntersection
				end
			end
			if separateEntries then
				stringResult = stringResult .. "\n"
				if i == #entries then
					stringResult = stringResult .. wallsLookUp.entries.lowerLeftCorner
					if showEnumerator then
						for _ = 1, enumerationLength do
							stringResult = stringResult .. wallsLookUp.entries.lowerFloor
						end
						stringResult = stringResult .. wallsLookUp.entries.lowerIntersection
					end
					for k, _ in ipairs(header) do
						local length = longestLine[k] + rightPadding + leftPadding
						for _ = 1, length do
							stringResult = stringResult .. wallsLookUp.entries.lowerFloor
						end
						if k == #header then
							stringResult = stringResult .. wallsLookUp.entries.lowerRightCorner
						else
							if k == #header then
								stringResult = stringResult .. wallsLookUp.entries.lowerRightCorner
							else
								stringResult = stringResult .. wallsLookUp.entries.lowerIntersection
							end
						end
					end
				else
					stringResult = stringResult .. wallsLookUp.entries.upperLeftCorner
					if showEnumerator then
						for _ = 1, enumerationLength do
							stringResult = stringResult .. wallsLookUp.entries.lowerFloor
						end
						stringResult = stringResult .. wallsLookUp.entries.lowerIntersection
					end
					for k, _ in ipairs(header) do
						local length = longestLine[k] + rightPadding + leftPadding
						for _ = 1, length do
							stringResult = stringResult .. wallsLookUp.entries.upperCeiling
						end
						if i == #entries then
							stringResult = stringResult .. wallsLookUp.entries.upperRightCorner
						else
							if k == #header then
								stringResult = stringResult .. wallsLookUp.entries.upperRightCorner
							else
								stringResult = stringResult .. wallsLookUp.entries.upperIntersection
							end
						end
					end
				end
			else
				if i == #entries then
					stringResult = stringResult .. "\n"
					stringResult = stringResult .. wallsLookUp.entries.lowerLeftCorner
					for k, _ in ipairs(header) do
						local length = longestLine[k] + rightPadding + leftPadding
						for _ = 1, length do
							stringResult = stringResult .. wallsLookUp.entries.lowerFloor
						end
						if k == #header then
							stringResult = stringResult .. wallsLookUp.entries.lowerRightCorner
						else
							if k == #header then
								stringResult = stringResult .. wallsLookUp.entries.lowerRightCorner
							else
								stringResult = stringResult .. wallsLookUp.entries.lowerIntersection
							end
						end
					end
				end

			end
			stringResult = stringResult .. "\n"
			if i >= finish then break end
		end
	end

	return stringResult
end

function gfxTables:destroy()
	--Find your self
	for i, v in ipairs(ActiveTables) do
		if v == self then
			table.remove(ActiveTables, i)
			break
		end
	end
	--Uwu officiawwy nuked thiws object fwom thiws weawity
	--luacheck: push ignore
	--This bothers luacheck
	self = nil
	--luacheck: pop
end

return gfxTables