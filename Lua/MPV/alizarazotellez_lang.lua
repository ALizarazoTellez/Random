-- Copyright (C) 2025 - Anderson Lizarazo Tellez.

local mp = require("mp")
local utils = require("mp.utils")

local save_directory = "/home/anderson/mining-tmp"

local filepath = nil

local current_subtitle = ""
local last_sub_start = 0
local last_sub_end = 0
local sub_start = 0
local sub_end = 0

mp.add_key_binding("left", function()
	mp.command("sub-seek -2")
	mp.set_property("pause", "no")
end)

mp.add_key_binding("right", function()
	mp.set_property("pause", "no")
end)

mp.add_key_binding("up", function()
	mp.command("sub-seek -1")
	mp.set_property("pause", "no")
end)

mp.add_key_binding("down", function()
	local status = mp.get_property("sub-visibility")

	if status == "yes" then
		mp.set_property("sub-visibility", "no")
	else
		mp.set_property("sub-visibility", "yes")
	end
end)

mp.add_key_binding("enter", function()
	local sub = current_subtitle
	local start = sub_start
	local finish = sub_end

	if mp.get_property("pause") == "yes" then
		sub = last_subtitle
		start = last_sub_start
		finish = last_sub_end
	end

	local subdir = utils.join_path(
		save_directory,
		filename .. "_" .. tostring(math.floor(start)) .. "_" .. tostring(math.floor(finish))
	)

	local file = io.open(subdir .. ".txt", "w")
	file:write(sub)
	file:close()

	extract_audio(filepath, subdir, start, finish)
end)

mp.observe_property("sub-text", "string", function(name, data)
	last_subtitle = current_subtitle
	current_subtitle = data

	last_sub_start = sub_start
	last_sub_end = sub_end

	sub_start = mp.get_property("sub-start") or sub_start
	sub_end = mp.get_property("sub-end") or sub_end

	sub_start = tonumber(sub_start)
	sub_end = tonumber(sub_end)

	if sub_start > last_sub_start then
		mp.set_property("sub-visibility", "no")
		mp.set_property("pause", "yes")
	end
end)

mp.register_event("file-loaded", function()
	local current_name = nil

	filepath = mp.get_property("path")
	_, current_name = utils.split_path(filepath)

	while current_name ~= nil do
		filename = current_name
		current_name = string.match(filename, "(.+)%.[^.]+$")
	end

	filename = string.gsub(filename, "%s", "_")
	filename = string.gsub(filename, "-", "_")
end)

function extract_audio(input, output, start, finish)
	mp.command(
		"run ffmpeg -i '"
			.. input
			.. "' -vn -acodec copy -map a -q:a 0 -ss "
			.. tostring(start)
			.. " -to "
			.. tostring(finish)
			.. " '"
			.. output
			.. ".m4a'"
	)
end
