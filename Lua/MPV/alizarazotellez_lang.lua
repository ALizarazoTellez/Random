-- Copyright (C) 2025 - Anderson Lizarazo Tellez.

local mp = require("mp")
local utils = require("mp.utils")

local options = {
	enabled = false,

	mining_directory = "",
}

require("mp.options").read_options(options)

local function track_current_subtitle(subtitle_data)
	subtitle_data.text = mp.get_property("sub-text")
	subtitle_data.start = mp.get_property_number("sub-start") or -1
	subtitle_data.finish = mp.get_property_number("sub-end") or -1
end

-- FIXME(ALizarazoTellez): I do not want to use global variables.
local _should_pause_skip_next = false
local function should_pause(current_subtitle, pos)
	if pos == nil then
		return
	end

	if _should_pause_skip_next then
		_should_pause_skip_next = false
		return
	end

	local difference = current_subtitle.finish - pos
	if difference >= 0 and difference <= 0.1 then
		mp.set_property_bool("pause", true)
		_should_pause_skip_next = true
	end
end

--- Variation of the DJB2 hash function (to prevent overflows).
local function hash(text)
	local current_hash = 5381

	local counter = 0
	for char in text:gmatch(".") do
		current_hash = current_hash * 33 + string.byte(char)

		-- These are random constants.
		if counter % 4 == 2 then
			current_hash = math.floor(current_hash / 100000)
		end
		counter = counter + 1
	end

	return string.format("%x", current_hash)
end

local function save_subtitle(directory, name, current_subtitle)
	local file = io.open(utils.join_path(directory, name .. ".txt"), "w")
	file:write(current_subtitle.text)
	file:close()
end

local function save_audio(filepath, directory, name, current_subtitle)
	mp.commandv(
		"run",
		"ffmpeg",
		"-i",
		filepath,
		"-vn",
		"-acodec",
		"copy",
		"-map",
		"a",
		"-q:a",
		"0",
		"-ss",
		current_subtitle.start,
		"-to",
		current_subtitle.finish,
		utils.join_path(directory, name .. ".m4a")
	)
end

local function main()
	if not options.enabled then
		print("Plugin is not enabled.")
		return
	end

	if options.mining_directory == "" then
		print("The directory for mining is not configured!")
		print("Aborting...")
		return
	end

	local current_subtitle = {
		text = "",
		start = -1,
		finish = -1,
		number = -1,
	}

	local filepath = ""

	-- Events.

	mp.register_event("file-loaded", function()
		filepath = mp.get_property("path")
	end)

	-- Property watchers.

	mp.observe_property("sub-text", "native", function()
		track_current_subtitle(current_subtitle)
		current_subtitle.number = current_subtitle.number + 1
	end)

	mp.observe_property("time-pos", "number", function(_, pos)
		should_pause(current_subtitle, pos)
	end)

	-- Keybindings.

	mp.add_key_binding("left", function()
		-- FIXME(ALizarazoTellez): Depending on the subtitle format, this may not work.
		mp.command_native({ name = "sub-seek", skip = -1 })
		mp.set_property_bool("pause", false)
	end)

	mp.add_key_binding("down", function()
		local status = mp.get_property_bool("sub-visibility")

		if status then
			mp.set_property_bool("sub-visibility", false)
		else
			mp.set_property_bool("sub-visibility", true)
		end
	end)

	mp.add_key_binding("up", function()
		mp.command_native({ name = "sub-seek", skip = 0 })
		mp.set_property_bool("pause", false)
	end)

	mp.add_key_binding("right", function()
		mp.set_property_bool("pause", false)
	end)

	mp.add_key_binding("enter", function()
		local name = hash(filepath) .. "-" .. tostring(current_subtitle.number)
		save_subtitle(options.mining_directory, name, current_subtitle)
		save_audio(filepath, options.mining_directory, name, current_subtitle)
	end)

	print("Plugin configured!")
end

main()
