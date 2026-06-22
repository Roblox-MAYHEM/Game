local module = {}

type Indexer = (tbl: any, result: string) -> ((self: any, ...any) -> any)
type NewIndexer = (tbl: any, key: string, value: any) -> ()

function module.inherit(self: any, baseInstance: any, class: any, indexFunction: Indexer?, newIndex: NewIndexer?)
	indexFunction = indexFunction or function(_, func)
		return function(_, ...)
			func(baseInstance, ...)
		end
	end
		
	newIndex = newIndex or function(tbl, key, value)
		tbl[key] = value
		baseInstance[key] = value
	end
	
	return setmetatable(self, {
		__index = function(tbl, key)
			-- First check if key exists in Class
			local value = class[key]
			if value then
				return value
			end

			-- If not, fall back to the Base Class
			local result = nil
			local success, response = pcall(function()
				result = baseInstance[key]
			end)

			if success and typeof(result) == "function" then
				return indexFunction(tbl, result)
			end

			return result
		end,

		__newindex = function(tbl, key, value)
			-- If the key exists in class, set it there
			if class[key] ~= nil then
				class[key] = value
			else
				newIndex(tbl, key, value)
			end
		end
	}
	)::typeof(self) & typeof(class)
end

return module
