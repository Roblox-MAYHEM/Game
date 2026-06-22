-- RoundStateWrite.lua (WriteLib)
-- Runs on BOTH server and client during Replica:Write()

local RoundStateWrite = {}

local function isDict(t)
	return type(t) == "table"
end

local function bumpRevision(replica)
	local rev = replica.Data.revision or 0
	replica:Set({ "revision" }, rev + 1)
end

-- Apply a partial update to the root state, bump revision once.
function RoundStateWrite.Apply(replica, partial)
	if type(partial) ~= "table" then return end

	-- Bump revision (optional but nice for debugging/UI)
	bumpRevision(replica)

	for k, v in pairs(partial) do
		if k == "scores" and isDict(v) then
			-- mutate scores in-place so references remain valid
			replica:SetValues({ "scores" }, v)

		elseif k == "leaderboard" and isDict(v) then
			replica:SetValues({ "leaderboard" }, v)

		elseif k == "gamemode" then
			-- overwrite gamemode object (small table)
			replica:Set({ "gamemode" }, v)

		else
			replica:Set({ k }, v)
		end
	end
end

function RoundStateWrite.SetScore(replica, teamId: string, pts: number)
	if type(teamId) ~= "string" or type(pts) ~= "number" then return end
	local scores = replica.Data.scores
	if type(scores) ~= "table" then return end

	teamId = string.upper(teamId)
	if scores[teamId] == pts then return end

	replica:Set({ "scores", teamId }, pts)

	-- Optional: bump revision when score changes too
	bumpRevision(replica)
end

local function SortTeam(replica, teamId)
	local team = replica.Data.leaderboard[teamId]
	if not team then return end

	table.sort(team, function(a, b)
		local aKills = a.kills or 0
		local bKills = b.kills or 0
		if aKills ~= bKills then
			return aKills > bKills
		end

		local aDeaths = a.deaths or 0
		local bDeaths = b.deaths or 0
		if aDeaths ~= bDeaths then
			return aDeaths < bDeaths
		end

		return tostring(a.pId or "") < tostring(b.pId or "")
	end)
end

function RoundStateWrite.IncrementLeaderboardEntry(replica, pId : number, teamId : string, k : string)
	local lb = replica.Data.leaderboard
	if type(lb) ~= "table" then return end
	
	pId = tostring(pId)
	teamId = string.upper(teamId)

	if type(lb[teamId]) ~= "table" then return end
	
	for idx, entry in ipairs(lb[teamId]) do
		if entry.pId == pId then
			replica:Set({ "leaderboard", teamId, idx, k }, (lb[teamId][idx][k] and lb[teamId][idx][k] or 0) + 1)
			SortTeam(replica, teamId)
			
			bumpRevision(replica)
			return
		end
	end
end

function RoundStateWrite.InsertLeaderboardEntry(replica, pId : number, teamId : string)
	local lb = replica.Data.leaderboard
	if type(lb) ~= "table" then return end

	pId = tostring(pId)
	teamId = string.upper(teamId)

	if type(lb[teamId]) ~= "table" then return end

	for _, entry in ipairs(lb[teamId]) do
		if entry.pId == pId then
			return
		end
	end
	
	replica:TableInsert({ "leaderboard", teamId }, { pId = pId, kills = 0, deaths = 0, assists = 0 } )
	SortTeam(replica, teamId)
	bumpRevision(replica)
end

function RoundStateWrite.RemoveLeaderboardEntry(replica, pId : number, teamId : string)
	local lb = replica.Data.leaderboard
	if type(lb) ~= "table" then return end

	pId = tostring(pId)
	teamId = string.upper(teamId)

	if type(lb[teamId]) ~= "table" then return end

	for idx, entry in ipairs(lb[teamId]) do
		if entry.pId == pId then
			replica:TableRemove({ "leaderboard", teamId }, idx )
			SortTeam(replica, teamId)

			bumpRevision(replica)
			return
		end
	end
end

return RoundStateWrite
