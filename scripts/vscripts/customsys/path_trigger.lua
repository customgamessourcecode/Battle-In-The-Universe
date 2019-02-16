function onPassNode(keys)
	local unit = keys.activator
	local node = keys.caller
	Path.moveNext(unit)
end