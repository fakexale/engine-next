local Table = {}

function Table.DeepCopy(target: { [unknown]: unknown }): { [unknown]: unknown }
	local dummy = table.clone(target)

	for p, val in dummy do
		if typeof(val) ~= "table" then
			continue
		end

		dummy[p] = Table.DeepCopy(val :: { [unknown]: unknown })
	end

	return dummy
end

--[[
	In dictionary1 we trust, in case of duplicate indexes:
		dictionary1's value will always prevail.
]]
function Table.MergeDictionaries(
	dictionary1: { [unknown]: unknown },
	dictionary2: { [unknown]: unknown }
): { [unknown]: unknown }
	local dummy = table.clone(dictionary1)

	for k, val in dictionary2 do
		if dummy[k] == dictionary2[k] then
			continue
		end

		dummy[k] = val
	end

	return dummy
end

function Table.MergeArrays(array1: { unknown }, array2: { unknown }): { unknown }
	local result = table.clone(array1)

	table.move(array2, 1, #array2, #result + 1, result)

	return result
end

function Table.Reconcile(target: { [unknown]: unknown }, template: { [unknown]: any }): { [unknown]: unknown }
	local dummy = table.clone(target)

	for k, val in template do
		if dummy[k] == nil then
			if typeof(val) == "table" then
				dummy[k] = Table.DeepCopy(val)
			else
				dummy[k] = val
			end
		elseif typeof(template[k]) == "table" then
			if typeof(val) == "table" then
				dummy[k] = Table.Reconcile(val, template[k])
			else
				dummy[k] = Table.DeepCopy(template[k])
			end
		end
	end

	return dummy
end

function Table.Keys(target: { [unknown]: unknown }): { unknown }
	local keys = {}

	for k in target do
		table.insert(keys, k)
	end

	return keys
end

function Table.Values(target: { [unknown]: unknown }): { unknown }
	local values = {}

	for _, val in target do
		table.insert(values, val)
	end

	return values
end

function Table.IsFlat(target: { [unknown]: unknown }): boolean
	for _, val in target do
		if typeof(val) == "table" then
			return false
		end
	end

	return true
end

function Table.IsDictionary(target: { [unknown]: unknown }): boolean
	local indexes = 0

	for _ in target do
		indexes += 1
	end
	return indexes ~= #target
end

function Table.IsArray(target: { [unknown]: unknown }): boolean
	local indexes = 0

	for _ in target do
		indexes += 1
	end

	return indexes == #target
end

function Table.Filter(
	target: { [unknown]: unknown },
	filterCallback: (value: unknown) -> boolean
): { [unknown]: unknown }
	local dummy = {}

	for _, val in target do
		if not filterCallback(val) then
			continue
		end

		table.insert(dummy, val)
	end

	return dummy
end

function Table.Some(target: { [unknown]: unknown }, filterCallback: (value: unknown) -> boolean): boolean
	for _, val in target do
		if filterCallback(val) == true then
			return true
		end
	end

	return false
end

function Table.Every(target: { [unknown]: unknown }, filterCallback: (value: unknown) -> boolean): boolean
	for _, val in target do
		if filterCallback(val) then
			continue
		end

		return false
	end

	return true
end

return Table
