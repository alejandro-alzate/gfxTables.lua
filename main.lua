local gfxTables = require("gfxTables")
newGfxTable = gfxTables.newTable("advanced", true, true)

newGfxTable:insertColumns("First Name", "Last Name", "Email", "Phone number")
newGfxTable:insertEntry({"John", "Doe", "john@example.com", "+1 123-45-67"})
print(newGfxTable:getText())