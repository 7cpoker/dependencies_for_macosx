local protobuf = require "protobuf"
--local netpack = assert(require "netpackx")
--local bytemap = require "bytemap"

local pbc = {}

local message_package = {}

function pbc_regfiles(files)
	for _,v in ipairs(files) do
		local addr = io.open(v, "rb")
		if addr==nil then
			print("open file "..addr.." failed!")
			break
		end
		local buffer = addr:read("*a")
		addr:close()
		protobuf.register(buffer)
		local path,name,suffix = string.match(v, "(.*/)(%w+).(%w+)")

		local proto = protobuf.decode("google.protobuf.FileDescriptorSet", buffer).file[1]

		--print(proto.name)
		--print(proto.package)

		message = proto.message_type
		for _,v in ipairs(message) do
			message_package[v.name] = proto.package
			--[[
			for _,v in ipairs(v.field) do
				print("\t".. v.name .. " ["..v.number.."] " .. v.label)
			end
			--]]
		end
	end
end

addressbook = {
	name = "Alice",
	id = 12345,
	phone = {
		{ number = "1301234567" },
		{ number = "87654321", type = "WORK" },
	}
}

function pbc.register(filename)
	pbc_regfiles(filename)
end

--------------------------------------------------------------------------------
-- 对命令码为cmd, 数据表为data的消息进行封包, 返回stringbuf
--------------------------------------------------------------------------------
function pbc.encode(cmd, data)
	assert(type(cmd)=="string")
	assert(type(data)=="table")
	if message_package[cmd]==nil then
		return
	end

	local msg_name = message_package[cmd].."."..cmd
	print("pbc_encode", msg_name)
	local packet = { cmd=cmd, buffer=protobuf.encode(msg_name, data) }
	return protobuf.encode("tutorial.Packet", packet)
end

--------------------------------------------------------------------------------
-- 对一个stringbuf进行解包, 返回命令码和数据表
--------------------------------------------------------------------------------
function pbc.decode(stringbuf)
	local packet = protobuf.decode("tutorial.Packet", stringbuf)
	if message_package[packet.cmd]==nil then
		return
	end

	local msg_name = message_package[packet.cmd].."."..packet.cmd
	return packet.cmd, protobuf.decode(msg_name, packet.buffer)
end

--[[
function pbc.pack(cmd, data)
	return netpack.pack(bytemap.encode(pbc.encode(cmd, data), 6))
end

function pbc.unpack(msg, sz)
	local data = netpack.tostring(msg, sz)
	return pbc.decode(bytemap.decode(data,6))
end

pbc.netpack = netpack
--]]

-- test cases:
--pbc_regfiles{"addressbook.pb", }
pbc_regfiles{"../../build/addressbook.pb", }
local stringbuf = pbc.encode("Person", addressbook)
local cmd, t = pbc.decode(stringbuf)
assert(cmd=="Person")
print(t.name, t.id)
for _, v in ipairs(t.phone) do
	print(v.number, v.type)
end

return pbc

