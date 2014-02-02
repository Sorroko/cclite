{
	["type"] = "drive",
	["load_disk"] = function(computer, data, diskId)
		data.disk_id = diskId
		computer.fileSystem:mount(find_available_mount, "/disks/disk" .. diskId)
		data.mount_path = find_available_mount
	end,
	["unload_disk"] = function(computer, data)
		data.disk_id = nil
		computer.fileSystem:unmount(data.mount_path)
		data.mount_path = nil
	end,
	["methods"] = {
		["isDiskPresent"] = function(computer, data)
			return data.disk_id ~= nil
		end,
		["getDiskLabel"] = function(computer, data)
			return "not_supported"
		end,
		["setDiskLabel"] = function(computer, data)
			return
		end,
		["hasData"] = function(computer, data) -- type is floppy and not music disk
			return true
		end,
		["getMountPath"] = function(computer, data)
			return data.mount_path
		end,
		["ejectDisk"] = function(computer, data)
			data.disk_id = nil
			computer.fileSystem:unmount(data.mount_path)
			data.mount_path = nil
			return
		end,
		["getDiskID"] = function(computer, data)
			return data.disk_id
		end,

		-- Not implementing music disks
		["hasAudio"] = function(computer, data) -- type is a music disk
			return false
		end,
		["getAudioTitle"] = function(computer, data)
			return nil
		end,
		["playAudio"] = function(computer, data)
			return nil
		end,
		["stopAudio"] = function(computer, data)
			return nil
		end
	}
}
