require "mydebug"
local protobuf = require "protobuf"

local proto = {}
function pbf_regfiles(files)
	for _,v in ipairs(files) do
		local addr = io.open(v, "rb")
		local buffer = addr:read"*a"
		print(type(buffer))
		addr:close()
		pcall(function() protobuf.register(buffer) end)
		print(protobuf.lasterror())
		local path,name,suffix = string.match(v, "(.*/)(%w+).(%w+)")
		proto[name] = protobuf.decode("google.protobuf.FileDescriptorSet", buffer).file[1]
		print("register "..name.." success!")
	end
end

do
	pbf_regfiles{"./hall.pb"}
--[[
	for _name, p in pairs(proto) do
		print(p.name, p.package)
		message = p.message_type
		for _,v in ipairs(message) do
			print(v.name)
			for _,v in ipairs(v.field) do
				print("\t".. v.name .. " ["..v.number.."] " .. v.label)
			end
		end
	end
--]]
	addressbook = {
		name = "Alice",
		id = 12345,
		phone = {
			{ number = "1301234567" },
			{ number = "87654321", type = "WORK" },
		}
	}
end

--code = protobuf.encode("tutorial.Person", addressbook)

--------------------------------------------------------------------------------
-- 对命令码为cmd, 数据表为data的消息进行封包, 返回stringbuf
--------------------------------------------------------------------------------
function pbf_encode(cmd, data)
	local p = proto.addressbook
	assert(type(cmd)=="string")
	assert(type(data)=="table")
	local msg_name = p.package.."."..cmd
	print("pbf_encode", msg_name)
	local packet = { cmd=cmd, buffer=protobuf.encode(msg_name, data) }
	return protobuf.encode("tutorial.Packet", packet)
end

--------------------------------------------------------------------------------
-- 对一个stringbuf进行解包, 返回命令码和数据表
--------------------------------------------------------------------------------
function pbf_decode(stringbuf)
	local p = proto.addressbook
	local packet = protobuf.decode("tutorial.Packet", stringbuf)
	local msg_name = p.package.."."..packet.cmd
	return packet.cmd, protobuf.decode(msg_name, packet.buffer)
end

--[[
local stringbuf = pbf_encode("Person", addressbook)
local cmd, t = pbf_decode(stringbuf)
assert(cmd=="Person")
print(t.name, t.id)
for _, v in ipairs(t.phone) do
	print(v.number, v.type)
end

--]]
--

do
	local function print_hexstr(str)
		local dump = ""
		for _i=1, str:len() do
			dump = string.format("%s%02d ", dump, str:byte(_i))
		end
		print(dump)
	end

	local m = {}
	m.uid = 1
	m.msg = {}
	m.msg.text = "hello"
	m.msg.time = os.time()
	local buf1 = protobuf.encode("hall.S2C_RoomPubTalk", m)

	local m2 = protobuf.decode("hall.S2C_RoomPubTalk", buf1)

	print_r(m2)

	print(m2.uid)
	print(m2.msg)
	for k, v in pairs(m2.msg) do
		print(k, v)
	end

	f = io.open("./bufbin", "w")
	f:write(buf1)
	f:close()
end



