local skynet = require "skynet"


skynet.start(function()
	print("Main Server start")
	local console = skynet.newservice("testredis")
	
	print("Main Server exit")
	skynet.exit()
end)
