--- @since 26.8.15
--- @sync entry

local PANE = { parent = 1, current = 2, preview = 3 }

local function eq(other)
	local r = rt.mgr.ratio
	return other[1] == r[1] and other[2] == r[2] and other[3] == r[3]
end

local function get()
	local r = rt.mgr.ratio
	return { r[1], r[2], r[3] }
end

local function set(new) rt.mgr.ratio = { new[1], new[2], new[3] } end

-- Configured default (yazi.toml [mgr] ratio); fallback matches the preset.
local function default_ratio()
	local ok, r = pcall(function() return YAZI.mgr.ratio end)
	if ok and r and r[1] then return { r[1], r[2], r[3] } end
	return { 2, 3, 3 }
end

local function entry(st, job)
	job = type(job) == "string" and { args = { job } } or job

	if not eq(st.new or {}) then
		st.new, st.old = nil, nil
	end
	local N, O = st.new or get(), st.old or get()

	local act, to = string.match(job.args[1] or "", "(.-)-(.+)")
	local i = PANE[to]
	if act == "min" then
		if N[i] == 0 and O[i] == 0 then
			-- Both zero: an external ratio write (e.g. pane-persist) desynced st.
			-- Restore the configured default so the pane can come back.
			N = default_ratio()
		else
			N[i] = N[i] == O[i] and 0 or O[i]
		end
	elseif act == "max" then
		local max = N[i] == 9999 and O[i] or 9999
		N[1] = N[1] == 9999 and O[1] or N[1]
		N[2] = N[2] == 9999 and O[2] or N[2]
		N[3] = N[3] == 9999 and O[3] or N[3]
		N[i] = max
	end

	if act then
		st.new, st.old = N, O
	else
		N, st.new, st.old = O, nil, nil
	end

	set(N)
	ya.emit("app:resize", {})
end

return { entry = entry }
