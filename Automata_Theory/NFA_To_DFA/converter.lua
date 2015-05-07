
local function join(delimiter, collection)
	local s = ""
	for i=1,#collection-1 do
		s = s .. collection[i] .. delimiter
	end
	s = s .. collection[#collection]
	return s
end

local nfa = dofile("nfa.lua")

local function infoNFA(nfa)
	io.write("NFA:\n")
	io.write("Alphabet:     ", join(", " ,nfa.sigma), "\n")
	io.write("States:       ", join(", " ,nfa.Z), "\n")
	io.write("Start-States: ", join(", " ,nfa.S), "\n")
	io.write("End-States:   ", join(", " ,nfa.E), "\n")
	io.flush()
end
local function infoDFA(dfa)
	io.write("DFA:\n")
	io.write("Alphabet:     ", join(", " ,dfa.sigma), "\n")
	io.write("States:       ", join(", " ,dfa.Z), "\n")
	io.write("Start-State:  ", dfa.S, "\n")
	io.write("End-States:   ", join(", " ,dfa.E), "\n")
	io.flush()
end
local function printDFA(dfa, file)
	local f = io.open(file, "w")
	assert(f, "File does not exist!")
	
	f:write("digraph {\n")
	f:write("\t", "__start [shape=point];", "\n")
	for _,q in pairs(dfa.Z) do
	
		local isEnd = false
		for i,v in pairs(dfa.E) do
			if q == v then
				isEnd = true
			end
		end
		if isEnd then
			f:write("\t", q, " [shape=doublecircle];", "\n")
		end
	
		for __,z in pairs(dfa.sigma) do
			local t = dfa.delta(q, z)
			if t ~= nil then
				f:write("\t", q, " -> ", t, " [label=\"", z, "\"];\n")
			end
		end
	end
	f:write("\t", "__start", " -> ", dfa.S, ";\n")
	f:write("}")
	
	f:close()
end

local function toDFA(nfa)
	local dfa = {
		sigma = nfa.sigma,
		Z = {},
		S = join("", nfa.S),
		E = {},
	}
	-- Initialize delta list
	local delta = { }
	for i,v in pairs(dfa.sigma) do
		delta[v] = { }
	end
	
	-- Create open and closed list
	local open = { dfa.S }
	local closed = {}
	
	while #open > 0 do
		-- pop element
		local current = open[#open]
		open[#open] = nil
		closed[current] = true
		table.insert(dfa.Z, current)
		
		-- Internal states
		local sources = {}
		for i=1,#current,2 do
			sources[#sources+1] = current:sub(i,i+1)
		end
		local function isEnd()
			for i,v in pairs(nfa.E) do
				for _,vv in pairs(sources) do
					if vv == v then
						return true
					end
				end
			end
			return false
		end
		if isEnd() then
			table.insert(dfa.E, current)
		end
		print("Processing", current, isEnd)
		
		local targetMap = {}
		for i,v in pairs(dfa.sigma) do
			targetMap[v] = { }
		end
		for _,src in ipairs(sources) do
			for __,z in pairs(dfa.sigma) do
				local targets = nfa.delta(src, z)
				for __,t in ipairs(targets) do
					targetMap[z][t] = true
				end
			end
		end
		for _,z in pairs(dfa.sigma) do
			local targets = targetMap[z]
			local list = { }
			for i,v in pairs(targets) do
				list[#list+1] = i
			end
			if #list > 0 then
				table.sort(list)
				local target = join("", list)
				print(z, "=>", target)
				delta[z][current] = target
				if closed[target] ~= true then
					open[#open+1] = target
				end
			else
				
			end
		end
		print(#open)	
	end

	function dfa.delta (q, z)
		return delta[z][q]
	end
	return dfa
end

infoNFA(nfa)

dfa = toDFA(nfa)

infoDFA(dfa)

printDFA(dfa, "dfa.dot")
