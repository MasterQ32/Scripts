local deltaA = {
	q1 = { },
	q2 = { "q2", "q3" },
	q3 = { "q4" },
	q4 = { },
	q5 = { "q5" },
}
local deltaB = {
	q1 = { "q2" },
	q2 = { "q1" },
	q3 = { },
	q4 = { "q1", "q5" },
	q5 = { "q5" },
}
local delta = { a=deltaA, b=deltaB }
return {
	S = { "q1", "q2" },
	E = { "q5" },
	Z = { "q1", "q2", "q3", "q4", "q5" },
	delta = function (q, z) 
		return delta[z][q]
	end,
	sigma = { "a", "b" }
}