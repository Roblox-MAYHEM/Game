local Loader = {}

local function getEntry(instance)
	if instance:IsA("ModuleScript") then return instance end
	if instance:IsA("Folder") then
		return instance:FindFirstChild("Handler")
	end
end

function Loader.Load(root: Folder, shared: {}?)
	local modules = {}
	shared = shared or {}

	for _, child in root:GetChildren() do
		local entry = getEntry(child)
		if not entry then continue end

		local ok, result = xpcall(function()
			return require(entry)
		end, function(err)
			return debug.traceback(err, 2)
		end)

		if not ok then
			warn(`[Loader] Failed to require {child.Name}: {result}`)
			continue
		end

		result._name = child.Name
		table.insert(modules, result)
		
		shared[result._name] = result
	end

	table.sort(modules, function(a, b)
		return (a.Priority or math.huge) < (b.Priority or math.huge)
	end)

	local groups, seen = {}, {}
	for _, m in modules do
		local p = m.Priority or math.huge
		if not seen[p] then
			seen[p] = true
			table.insert(groups, { priority = p, items = {} })
		end
		table.insert(groups[#groups].items, m)
	end

	for _, group in groups do
		local remaining = 0

		local cleanupTrove = shared.Trove or shared.trove

		for _, m in group.items do
			if not m.Init then continue end
			remaining += 1
			task.spawn(function()
				local ok, err = xpcall(m.Init, debug.traceback, m, shared)
				if not ok then warn(`[Loader] {m._name}:Init() failed:\n{err}`) end
				if cleanupTrove and m.Destroy then cleanupTrove:Add(m) end
				remaining -= 1
			end)
		end

		while remaining > 0 do task.wait() end
	end

	for _, m in modules do
		if m.Start then
			task.spawn(function()
				local ok, err = xpcall(function()
					m:Start(shared)
				end, function(e)
					return debug.traceback(e, 2)
				end)

				if not ok then
					warn(`[Loader] {m._name}:Start() failed:\n{err}`)
				end
			end)
		end
	end
end

return Loader
