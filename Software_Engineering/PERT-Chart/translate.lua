
local records = { }

-- Parse records
local f = io.open("raw-graph.csv", "r")
while true do
	local line = f:read("*line")
	if line == nil then
		break
	end
	
	local raw = { }
	for part in line:gmatch("%w+") do
		table.insert(raw, part)
	end
	
	local record = {
		id = raw[1],
		optimistic = tonumber(raw[2]),
		normal = tonumber(raw[3]),
		pessimistic = tonumber(raw[4]),
		dependency = { },
		successors = { },
		startMin = -55,
		startMax = -55,
		endMin = 1000000,
		endMax = 1000000,
		critical = false
	}
	for i=5,#raw do
		table.insert(record.dependency, raw[i])
	end
	
	-- record.time = record.normal
	record.time = (record.optimistic + 4 * record.normal + record.pessimistic) / 6
	
	records[record.id] = record
end
f:close()

-- Translate dependencies
for _, record in pairs(records) do
	for id, dep in pairs(record.dependency) do
		record.dependency[id] = records[dep] or error("Dependecy "..dep.." not found.")
	end
end

-- Attach successors
for _, record in pairs(records) do
	for id, dep in pairs(record.dependency) do
		table.insert(dep.successors, record)
	end
end

-- Calculate earliest start
function recurse_start(record, time)

	if record.startMin < time then
		record.startMin = time
	end
	record.endMin = record.startMin + record.time
	
	for i, suc in pairs(record.successors) do
		recurse_start(suc, record.endMin)
	end
end

for _, record in pairs(records) do
	if #record.dependency == 0 then
		recurse_start(record, 0)
	end
end

-- Calculate latest start
function recurse_end(record, time)

	if record.endMax > time then
		record.endMax = time
	end
	record.startMax = record.endMax - record.time
	
	for i, suc in pairs(record.dependency) do
		recurse_end(suc, record.startMax)
	end
end

local maxEnd = 0
for _, record in pairs(records) do
	local e = record.endMin
	if e > maxEnd then
		maxEnd = e
	end
end

for _, record in pairs(records) do
	if #record.successors == 0 then
		recurse_end(record, maxEnd)
	end
end

-- determine critical path
local criticalPath = { length=0, nodes={} }
for _, record in pairs(records) do
	if record.endMin == maxEnd then
		local path = { length=0, nodes={} }
		
		local n = record
		while n ~= nil do
			
			path.length = path.length + n.time
			table.insert(path.nodes, n)
			
			local next = { time=0 }
			for _,r in pairs(n.dependency) do
				if r.endMin == n.startMin then
					next = r
				end
			end
			if next.id ~= nil then
				n = next
			else
				n = nil
			end
		end
		
		if criticalPath.length < path.length then
			print(criticalPath.length, " -> ", path.length)
			criticalPath = path
		end
	end
end

for _, record in pairs(criticalPath.nodes) do
	record.critical = true
end
print("Critical length:", criticalPath.length)

-- Write pert chart records
f = io.open("pert.dot", "w")

local function writeRecord(record)
	f:write("\t", record.id, " [label=\"")
	f:write(record.id)
	--f:write("|{", record.startMin, "|", record.endMin , "}")
	--f:write("|", record.time)
	--f:write("|{", record.startMax, "|", record.endMax , "}")
	f:write("|{")
	f:write("{", record.startMin, "|", record.endMin, "}|")
	f:write(record.time, "|")
	f:write("{", record.startMax, "|", record.endMax, "}")
	f:write("}")
	f:write("\"")
	if record.critical then
		f:write(" fillcolor=red")
	end
	f:write("];\n")
end

f:write("digraph {\n")
f:write("\tnode [shape=record style=filled];\n")
writeRecord({
	id = "ID",
	startMin = "min-start",
	startMax = "max-start",
	endMin = "min-end",
	endMax = "max-end",
	time = "duration",
	critical = false
})
for _,record in pairs(records) do
	writeRecord(record)
end
for _,record in pairs(records) do
	for _,dep in pairs(record.dependency) do
		f:write("\t")
		f:write(dep.id)
		f:write(" -> ")
		f:write(record.id)
		f:write(";\n")
	end
end
f:write("}")
f:close()

os.execute("dot -Tpng -oresult.png pert.dot")

-- Write gantt chart records
f = io.open("../Aufgabe3/gantt.dot", "w")

f:write("digraph {\n")
f:write("\tnode [shape=box style=filled];\n")
sortedRecords = {}
for _,record in pairs(records) do
	table.insert(sortedRecords, record)
end
table.sort(sortedRecords, function (a,b) return b.startMin < a.startMin end)

for i,record in ipairs(sortedRecords) do
	f:write("\t", record.id, " [")
	f:write("pos=\"", 1.0 * record.startMin, ",", 0.7 * i, "\" ")
	f:write("width=", 1.0 * (record.endMin - record.startMin), " ")
	f:write("height=0.5 ")
	f:write("fixedsize=true ")
	f:write("pin=true ")
	f:write("]\n")
end
----[[
for _,record in pairs(records) do
	for _,dep in pairs(record.dependency) do
		f:write("\t")
		f:write(dep.id)
		f:write(" -> ")
		f:write(record.id)
		f:write(";\n")
	end
end
--]]
f:write("}")

f:close()