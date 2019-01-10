local uint8 = 1
local int8 = 2
local int32 = 3
local uint32 = 4
local string = 5

local p = {}

local Person = {
	"name", string,
	"age", uint8,
}

--[[
	proto = {
		{field = type},
		opcode = 1,
	}
]]

--p.CMSG_LOGIN = {
--	1,
--	"uid", uint32,
--	"key", string,
--	"test", {
--		"name", string,
--		"age", uint8,
--	}
--}

p.CMSG_LOGIN = {
	1,
	"uid", uint32,
	"key", string,
}

p.SMSG_LOGIN_SUCCESS = {
	2
}
p.SMSG_LOGIN_FAILED = {
	3,
	"errcode", uint32
}

p.CMSG_ENTER_ROOM = {
	4,
	"roomid", uint32,
	"userinfo", string,
}

p.SMSG_ENTER_ROOM_SUCCESS = {
	5,
	"roomid", uint32,
	"basebet", uint32,
	"minmoney", uint32,
	"playtime", uint32,
	"gametype", uint32,
}

p.SMSG_ENTER_ROOM_FAILED = {
	6,
	"errcode", uint32
}

p.SMSG_SOMEONE_ENTER_ROOM = {
	7,
	"uid", uint32,
	"userinfo", string, 
}

p.CMSG_SIT = {
	8,
	"seatid", uint8
}

p.SMSG_SOMEONE_SIT = {
	9,
	"uid", uint32,
	"seatid", uint8,
	"score", int32,
	"userinfo", string,
}

p.SMSG_SIT_FAILED = {
	10,
	"errorcode", uint32
}

p.CMSG_TRY_STAND = {
	13,
}

p.CMSG_STAND = {
	14,
}

p.SMSG_SOMEONE_STAND = {
	15,
}

p.SMSG_STAND_FAILED = {
	16,
	"errcode", uint32
}

p.CMSG_HEARTBEAT = {
	29,
}

p.SMSG_HEARTBEAT = {
	30,
}

p.SMSG_MYUIDS = {
	31,
--	"uids", {"uid", uint32},
	"uids", { uint32 },
}

return p
