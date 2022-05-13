--从这里开始是策划开始调用的内容--
local PLAYERLIST = {}
local ZONELIST = {}
local BORN_POSITION = {{-185.82, 102.82, -186.26}, {-151.69, 100.18, 188.08}, {-46.62, 100.15, -45.49}, {178.35, 100.15, -150.58},{127.37, 100.26, 126.81}}
local EXP_REWARD = {26040, 26041}
local RANK_REWARD = {26239, 26240, 26241, 26242, 26243}
local EXP_NUM = 1 --在线经验奖励计数
local RANK_ID = {0,0,0,0}  --第一名至第四名服务器ID
local SERVE_NUM = 1
local ZONE_RANK_LIST = {}
local ZONE_REWARD_LIST = {} --结算奖励用


--自建函数区--
function SendMsg(this)
    table.sort(ZONE_RANK_LIST, function(a, b) return (a.killnum > b.killnum) end)
	this:Log(DEBUG, "各服务器杀人数排行完毕")
	

	for k = 1, #ZONE_RANK_LIST do
        if k <= 4 then 
		    this:SetAttribute(false, -k, ZONE_RANK_LIST[k].id)
			RANK_ID[k] = ZONE_RANK_LIST[k].id
			this:Log(DEBUG, "名次", -k, "的服务器ID", ZONE_RANK_LIST[k].id, "发送完毕")
        end 	
	    this:SetAttribute(false, ZONE_RANK_LIST[k].id, ZONE_RANK_LIST[k].killnum)
		this:Log(DEBUG, "发送服务器ID", ZONE_RANK_LIST[k].id, "该服务器杀人数", ZONE_RANK_LIST[k].killnum)
	end
	this:Log(DEBUG, "服务器ID及信息传送完毕")
	
end

function SysSpeak(this, last_attacker)
	local ruid = this:GetRuid(last_attacker)
	
	if PLAYERLIST[ruid].killnum == 100 then
	    this:SystemSpeak(3232, 0, last_attacker)
		this:Log(DEBUG, "玩家", ruid, "已经超神")
	elseif PLAYERLIST[ruid].killnum == 50 then
		this:SystemSpeak(3231, 0, last_attacker)
		this:Log(DEBUG, "玩家", ruid, "接近神的杀戮")
	elseif PLAYERLIST[ruid].killnum == 20 then
	    this:SystemSpeak(3230, 0, last_attacker)
		this:Log(DEBUG, "玩家", ruid, "无人能挡")
	elseif PLAYERLIST[ruid].killnum == 10 then
	    this:SystemSpeak(3229, 0, last_attacker)
		this:Log(DEBUG, "玩家", ruid, "主宰比赛")
	elseif PLAYERLIST[ruid].killnum == 5 then
	    this:SystemSpeak(3228, 0, last_attacker)
		this:Log(DEBUG, "玩家", ruid, "大杀特杀")
	end 

end

function SendExpReward(this)
    this:AddGeneralReward(REWARD_TYPE_INSTANCE, EXP_REWARD[EXP_NUM], 0, 0, 0)
	EXP_NUM = EXP_NUM + 1
	this:SystemSpeak(3236)
	this:Log(DEBUG, "全球混战在线奖励发放完毕")
end

function SendRankReward(this)
    for k = 1, #ZONE_RANK_LIST do
	    if k <= 4 then
		    table.insert(ZONE_REWARD_LIST, ZONE_RANK_LIST[k].id)
			table.insert(ZONE_REWARD_LIST, RANK_REWARD[k])
			this:Log(INFO, "全球混战名次", k, "ID与奖励插入完毕", "ID", ZONE_RANK_LIST[k].id, "奖励", RANK_REWARD[k])
		else
		    table.insert(ZONE_REWARD_LIST, ZONE_RANK_LIST[k].id)
			table.insert(ZONE_REWARD_LIST, RANK_REWARD[5])
			this:Log(INFO, "全球混战名次", k, "ID与奖励插入完毕", "ID", ZONE_RANK_LIST[k].id, "奖励", RANK_REWARD[5])
		end
	end 
	this:Log(DEBUG, "给所有人都发完奖啦")
end

--[[function SendRankReward(this)
    for  do
	    if player.zone_id == RANK_ID[1] then 
		    this:AddGeneralReward(REWARD_TYPE_INSTANCE, RANK_REWARD[1], 0, 0, player.id)
			this:Log(DEBUG, "给第一名服务器", RANK_ID[1], "的玩家", player.id, "发奖")
		elseif player.zone_id == RANK_ID[2] then 
		    this:AddGeneralReward(REWARD_TYPE_INSTANCE, RANK_REWARD[2], 0, 0, player.id)
			this:Log(DEBUG, "给第二名服务器", RANK_ID[2], "的玩家", player.id, "发奖")
		elseif player.zone_id == RANK_ID[3] then 
		    this:AddGeneralReward(REWARD_TYPE_INSTANCE, RANK_REWARD[3], 0, 0, player.id)
			this:Log(DEBUG, "给第三名服务器", RANK_ID[3], "的玩家", player.id, "发奖")
		elseif player.zone_id == RANK_ID[4] then 
		    this:AddGeneralReward(REWARD_TYPE_INSTANCE, RANK_REWARD[4], 0, 0, player.id)
			this:Log(DEBUG, "给第四名服务器", RANK_ID[3], "的玩家", player.id, "发奖")
		else
		    this:AddGeneralReward(REWARD_TYPE_INSTANCE, RANK_REWARD[5], 0, 0, player.id)
			this:Log(DEBUG, "给第四名以后的服务器的玩家", player.id, "发奖")
		end
	end
	this:Log(DEBUG, "给所有人都发完奖啦")
end]]

--通用函数区--
function OnLevelInit(this)
    this:InitLog(DEBUG, "全球混战")
    this:SetAttribute(false, -1, 0, -2, 0, -3, 0) --初始化与客户端约定的键值
	this:Log(DEBUG, "全球混战开启，客户端键值初始化完毕")
end

function OnPlayerEnter(this, who, replace)
    local ruid = this:GetRuid(who)
    local info = this:GetTargetInfo(who)
	local zone_id = info.zone_id
	
    if PLAYERLIST[ruid] then
	    PLAYERLIST[ruid].id = who
        this:Log(INFO, "hz-玩家重新进入副本，ID为", who)
    else
        PLAYERLIST[ruid] = {}
        PLAYERLIST[ruid].id = who
		PLAYERLIST[ruid].killnum = 0
		PLAYERLIST[ruid].fighting_capacity = info.fighting_capacity
		PLAYERLIST[ruid].zone_id = info.zone_id
		PLAYERLIST[ruid].BornPos = {}
        this:Log(DEBUG, "玩家", ruid, "进入副本", "杀人数", PLAYERLIST[ruid].killnum, "战斗力", PLAYERLIST[ruid].fighting_capacity, "服务器ID", PLAYERLIST[ruid].zone_id)
    end
	
	if ZONELIST[zone_id] then 
	    this:JumpTo( who, unpack(ZONELIST[zone_id].BornPos))
		this:PersonalSpeak(3235,who)
		this:Log(DEBUG, "传送到服务器出生点", unpack(ZONELIST[zone_id].BornPos))
	else
	    local i = math.random(1,5)
		ZONELIST[zone_id] = {}
		ZONELIST[zone_id].id = zone_id
		ZONELIST[zone_id].killnum = 0
		ZONELIST[zone_id].BornPos = BORN_POSITION[i]
		this:SetAttribute(false, ZONELIST[zone_id].id, ZONELIST[zone_id].killnum)
		this:Log(DEBUG, "新的服务器加入全球混战，服务器ID", ZONELIST[zone_id].id, "杀敌数", ZONELIST[zone_id].killnum)
		this:JumpTo( who, unpack(ZONELIST[zone_id].BornPos))
		table.insert(ZONE_RANK_LIST, ZONELIST[zone_id])
		this:Log(DEBUG, "设置新服务器出生点", unpack(ZONELIST[zone_id].BornPos))
	end 
	
	this:AddBuff(who, 1053, 1 )
    this:AddBuff(who, 1052, 1 )
    this:WatchAction(who,false,true)   
end

function OnPlayerLeave(this, who)
    this:AddBuff(who, 1053, 1 )
end

function OnLevelStart(this)
	this:LevelStart(1, Stage_1_progress)
	this:Log(DEBUG, "全球混战开启")
end

function Stage_1_progress(this)
	--[[this:StartWaveUseAverageLevel(1, false)
	for i = 1, 5 do
		this:ActiveEventRegion(i)
	end
	this:Log(DEBUG, "5个复活点开启")]]
	
	this:SetTimer(1, 5, 0, SendMsg)
	this:SetTimer(2, 600, 2, SendExpReward)
	
	while true do
		this:Sleep(5)
	end
	this:LevelClear()
end

--[[function OnLeaveRegion(this, count, region_id, who)
	this:Log(DEBUG, "LEAVE     REGION", count, region_id)
	this:AddBuff(who, 1053, 1 )
	--this:PersonalSpeak(3235,who)
end--]]

function OnCreatureDying(this, who, last_attacker, tid)
    local ruid1 = this:GetRuid(last_attacker)
	local ruid2 = this:GetRuid(who)
	local info = this:GetTargetInfo(who)
	local distance = {}
	
	for i = 1,5 do 
	    distance[i] = {}
	    distance[i][1] = i
		distance[i][2] = (info.x - BORN_POSITION[i][1])^2 + (info.z - BORN_POSITION[i][3])^2
	end
	
	table.sort(distance, function(a, b) return a[2] < b[2] end)
	
	local j = distance[1][1]
	local area_born_position = {}
	area_born_position[1] = math.random((BORN_POSITION[j][1]-40), (BORN_POSITION[j][1]+40))
	area_born_position[2] = BORN_POSITION[j][2]
	area_born_position[3] = math.random((BORN_POSITION[j][3]-40), (BORN_POSITION[j][3]+40))
	
	PLAYERLIST[ruid2].BornPos = area_born_position
	this:Log(DEBUG, "设置玩家最近的复活点", unpack(PLAYERLIST[ruid2].BornPos))
	
	local zone_id = PLAYERLIST[ruid1].zone_id 
	PLAYERLIST[ruid1].killnum = PLAYERLIST[ruid1].killnum + 1
	ZONELIST[zone_id].killnum = ZONELIST[zone_id].killnum + 1
	this:Log(DEBUG, "服务器", zone_id, "杀人数", ZONELIST[zone_id].killnum)
	
	SysSpeak(this, last_attacker)
end 

function OnPlayerRevive(this, who, reviveType)
    this:Log(DEBUG, "玩家复活，复活方式为", reviveType)
    local ruid = this:GetRuid(who)
	if reviveType ~= 2 then
		this:JumpTo( who, unpack(PLAYERLIST[ruid].BornPos))
		this:AddBuff(who, 1052, 1 )
		this:PersonalSpeak(3234,who)
		this:Log(DEBUG, "玩家复活，传送到复活点", unpack(PLAYERLIST[ruid].BornPos))
	end
end 

function OnInstanceTimeout(this)
	this:TransfMsg(0, 0, GLOBAL_MELEE_WINNER, RANK_ID[1])
	this:Log(DEBUG, "全球混战排位赛第一名发送完毕")
	this:SystemSpeak(3233)
	SendMsg(this)
    SendRankReward(this)
    this:TransfMsg(0, 0, GLOBAL_MELEE_REWARD, unpack(ZONE_REWARD_LIST))	
	for _, player in pairs(PLAYERLIST) do
	    this:FrozenSelf(player.id, true)
		this:Log(DEBUG, "玩家", player.id, "被冻结")
	end
	this:SendResult(0)
	this:Shutdown(60)
end