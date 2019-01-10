local skynet = require "skynet"
local netpack = assert(require "netpackx")
local bytemap = require "bytemap"

-- 二进制协议解析

local proto = {}
local bp = {}

-- 每次获取数组两个元素
local function _ipairs(tbl, idx)
	return function(t, i)
		local v1,v2 = t[i+1],t[i+2]
		if v1 and v2 then
			return i+2,v1,v2
		end
	end, tbl, idx or 0
end

local pack_field, pack_table

function pack_table(tbl, body)
	local result = ""
	for _,p in ipairs(tbl) do
		for k,v in pairs(p) do
			if k=="" then
				result = result..pack_field(_, v, body)
			else
			--print("pack field:", k)
				result = result..pack_field(k, v, body)
			end
		end
	end
	return result
end

function pack_field(field, typeid, body)
	if typeid == 1 then
		return string.pack("I1", body[field])
	elseif typeid == 2 then
		return string.pack("i1", body[field])
	elseif typeid == 3 then
		return string.pack("<i4", body[field])
	elseif typeid == 4 then
		return string.pack("<I4", body[field])
	elseif typeid == 5 then
		return string.pack("<s4", body[field])
	else
		-- repeated field
		local cnt = #body[field]
		local result = string.pack("I1", #body[field])
		for i=1,cnt do
			result = result..pack_table(typeid, body[field][i])
		end
		--print("pack cnt:", #body[field], "field", field)
		return result
	end
end

function bp.encode(name, body)
	--print("pack cmd", name)
	local out = ""
	out = out..string.pack("<I2", proto[name].opcode)
	out = out..string.pack("I1I1I1", 1, 1, 1)
	return out..pack_table(proto[name], body)
end

local unpack_field

local function unpack_table(tbl, data, pos)
	local out = {}
	local val
	for _,p in ipairs(tbl) do
		for k,v in pairs(p) do
			--print(">>>>>>>>>>>>>>>>>>")
			--print(string.format("unpack key '%s' at pos %d", k, pos))
			val, pos = unpack_field(k,v,data,pos)
			out[k] = val
			--print("<<<<<<<<<<<<<<<<<<")
		end
	end
	return out, pos
end

function unpack_field(field, typeid, data, pos)
	if typeid == 1 then
		assert(#data >= pos, field)
		return string.unpack("I1", data, pos)
	elseif typeid == 2 then
		assert(#data >= pos, field)
		return string.unpack("i1", data, pos)
	elseif typeid == 3 then
		assert(#data >= pos+3, field)
		return string.unpack("<i4", data, pos)
	elseif typeid == 4 then
		assert(#data >= pos+3, field)
		return string.unpack("<I4", data, pos)
	elseif typeid == 5 then
		local ok, err, _pos = pcall(string.unpack, "<s4", data, pos)
		if not ok then
			local len = string.unpack("<I4", data, pos)
			error(string.format("unpack string failed: %s, at pos %d, require %d, remains %d", err, pos, len, #data-pos+1))
		end
		return err, _pos
	else
		-- repeated field  cnt:uint8
		local out = {}
		local cnt
		cnt, pos = string.unpack("<I1", data, pos)
		--print("unpack cnt:", cnt)
		for i=1,cnt do
			out[#out+1], pos = unpack_table(typeid, data, pos)
		end
		for k,v in ipairs(out) do
			--print("****", k, v)
		end
		return out, pos
	end
end

function bp.decode(data)
	--print("bp.decode data type is ", type(data))
	local len = #data
	assert(len>=5)
	local cmd, pos = string.unpack("<I2", data)
	pos = pos+3
	--print("decode cmd is", cmd)
	local p = assert(proto[cmd], string.format("error opcode %d", cmd))
	local out, len = unpack_table(p, data, pos)
	return proto[cmd].cmd, out, len-1
end

local function _parse(tbl, idx)
	local p = {}
	for _,field,typeid in _ipairs(tbl, idx) do
		if type(typeid)=="number" then
			table.insert(p, {[field]=typeid})
		elseif type(typeid)=="table" then
			local t = _parse(typeid)
			table.insert(p, {[field]=t})
		else
			error(string.format("invalid type '%s' in parse typename", type(typeid)))
		end
	end
	return p
end

--[[
	proto = {
		c2s_login = {
			{ field1 = type1 },
			{ field2 = type2 },
			...
			{ fieldN = typeN }
			opcode = 1,
			cmd = "c2s_login",
		},
		[1] = proto.c2s_login
	}
]]

local function parse(filename)
	assert(type(filename)=="string")
	local src = require(filename)
	for cmd,body in pairs(src) do
		assert(type(cmd)=="string" and type(body)=="table" and #body>0)
		if proto[cmd] == nil then
			local opcode = body[1]
			if proto[opcode] ~= nil then
				error(string.format("parse proto file '%s.lua' failed: cmd '%s' and '%s' has the same opcode %d", filename, cmd, proto[opcode].cmd, opcode))
			end
			local t = _parse(body, 1)
			t.opcode = opcode
			t.cmd = cmd
			proto[cmd] = t
			proto[opcode] = t
		end
	end
end

function bp.register(filename)
	return parse(filename)
end

function bp.hexdump(str, i, j)
	local i = i or 1
	local j = j or #str
	for k=i, j, 16 do
		local s = str:sub(k, k+15)
		io.write(string.format("%08x  ", k-1))
		s:gsub('.', function(c)
			io.write(string.format("%02x ", string.byte(c)))
		end)
		io.write(string.rep(" ", 3*(16-#s)))
		io.write(" ", s:gsub("%c", '.'), "\n")
	end
end

function bp.pack(cmd, data)
	return netpack.pack(bytemap.encode(bp.encode(cmd, data), 6))
end

function bp.unpack(msg, sz)
	local data = netpack.tostring(msg, sz)
	return bp.decode(bytemap.decode(data,6))
end

bp.netpack = netpack

return bp
