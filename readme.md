# *gfxTables.lua*
Have you ever been jealous of how pretty SQL consoles prints?
Here gfxTables to help you!

## To do:
- lua table to gfxTable and vice versa

## Features
- Simple API
- Easy to work with

## Getting started
1. 📡 Get a copy of srt.lua from the [Official Repository](https://github.com/alejandro-alzate/gfxTables.lua?tab=License-1-ov-file) or [From Luarocks](https://www.youtube.com/watch?v=dQw4w9WgXcQ&pp=ygUJcmljayByb2xs)
2. 💾 Copy `gfxTables.lua` where you like to use it, or just on the root directory of the project
3. ⚙ Add it to your project like this:<br>
	```lua
	local gfxTables = require("path/to/gfx/Tables")
	```

4. 📃 Create a new table object:
	```lua
	local coolTable = gfxTables.newTable()
	```

5. 🎮 Play with it's api to see how it works
	```lua
	coolTable:setShowEnumerator(true)
	--Now in the left side will be a number indexing items
	--Starting from 1 jus like god intended
	coolTable:setDefaultEntryValue("empty")
	--When a cell has not been defined it will print "empty"
	coolTable:setPadding(2)
	--2 spaces between walls and text
	coolTable:insertColumns("First Name", "Last Name", "Email")
	--Now the table contains 3 columns use :inserttColumn() for finer
	--control on individual columns
	coolTable:insertEntry({"Alejandro", "Alzate", "alejandro-alzate@github.com"})

	--Not joking just print it directly
	print(coolTable)
	```
6. 💎 Look at that beauty and profit!
	```lua
		local gfxTables = require("gfxTables")
		local coolTable = gfxTables.newTable()
		coolTable:setShowEnumerator(true)
		coolTable:setSeparateEntries(true)
		coolTable:setDefaultEntryValue("empty")
		coolTable:setPadding(2)
		coolTable:insertColumns("First Name", "Last Name", "Email")
		coolTable:insertEntry({"Alejandro", "Alzate", "alejandro-alzate@github.com"})
		print(coolTable)
	```

	By running our script `main.lua` with those lines
	`$ lua main.lua`

	we get:
	```
	┏━━━━━┳━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
	┃  #  ┃  First Name  ┃  Last Name  ┃  Email                        ┃
	┡━━━━━╇━━━━━━━━━━━━━━╇━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
	|  1  |  Alejandro   |  Alzate     |  alejandro-alzate@github.com  |
	└─────┴──────────────┴─────────────┴───────────────────────────────┘
	```
