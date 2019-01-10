local protobuf = require "protobuf"

local proto = {}
function pbf_regfiles(files)
	for _,v in ipairs(files) do
		local addr = io.open(v, "rb")
		local buffer = addr:read"*a"
		addr:close()
		protobuf.register(buffer)
		local path,name,suffix = string.match(v, "(.*/)(%w+).(%w+)")
		proto = protobuf.decode("google.protobuf.FileDescriptorSet", buffer).file[1]
	end
end

pbf_regfiles{"../../build/addressbook.pb", }

print(proto.name)
print(proto.package)

message = proto.message_type

for _,v in ipairs(message) do
	print(v.name)
	for _,v in ipairs(v.field) do
		print("\t".. v.name .. " ["..v.number.."] " .. v.label)
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

--code = protobuf.encode("tutorial.Person", addressbook)

--------------------------------------------------------------------------------
-- 对命令码为cmd, 数据表为data的消息进行封包, 返回stringbuf
--------------------------------------------------------------------------------
function pbf_encode(cmd, data)
	assert(type(cmd)=="string")
	assert(type(data)=="table")
	local msg_name = proto.package.."."..cmd
	print("pbf_encode", msg_name)
	local packet = { cmd=cmd, buffer=protobuf.encode(msg_name, data) }
	return protobuf.encode("tutorial.Packet", packet)
end

--------------------------------------------------------------------------------
-- 对一个stringbuf进行解包, 返回命令码和数据表
--------------------------------------------------------------------------------
function pbf_decode(stringbuf)	
	local packet = protobuf.decode("tutorial.Packet", stringbuf)
	local msg_name = proto.package.."."..packet.cmd
	return packet.cmd, protobuf.decode(msg_name, packet.buffer)
end


local stringbuf = pbf_encode("Person", addressbook)
local cmd, t = pbf_decode(stringbuf)
assert(cmd=="Person")
print(t.name, t.id)






