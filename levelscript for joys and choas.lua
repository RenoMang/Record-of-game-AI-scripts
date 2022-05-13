local  M = require("config/x28/x28_smashstar5/SmashStar5")
--从这里开始是策划开始调用的内容--
local BORNPOS = {{0,0,0}} --玩家进入地图的出生位置
local GUANG_QIANG_WAVEID = 1001
local WAIT_TIME = 10 --开场选牌等待时间
local PLAYER_NUM = 0 --副本内玩家数量
local LEVEL = 80
local PLAYERLIST = {}
local STARTED = false
local ACTIVE_SHOW_LIST = {} --动态调整展示目录
local ACTIVE_PLAYERID_LIST = {} --动态玩家ID
local CANCEL_BUFF_ID = 1064--取消变身状态的BUFFID
local PROF_LIST = {{1,0},{2,0},{3,0},{4,0}}
local BOX_REPU = 146 --宝箱控制声望
local RESULT_REPU = 147
--local GAME_NUM_REPU = 148
local FIRST_WIN_REWARD = 26714
local FIRST_GAME_REWARD = 26639
local JIYOU_LIST = {} --存储玩家选取的对象
local BOX_CONTROL_ID = {709702, 709703, 709704, 709705, 709706}
local LOCKED_BOX_WAVE_ID = 709707
local YELLOW_STAR_WAVE_ID = {30,31,32,33,34,35,36,37,38,39}
local BLUE_STAR_WAVE_ID = {40,41,42,43,44,45,46,47,48,49}
local PURPLE_STAR_WAVE_ID = {50,51,52,53,54,55,56,57,58,59}
local SYMBOL_STAR_WAVE_ID = {0,1,2,3,4,5,6,7,8,9}
local EXIST_WAVE_ID = {}
local ITEM_WAVE_ID = {21, 22, 23, 24, 25, 26, 27}
local STAR_SPEAK_ID = 3312
local BOX_SPEAK_ID = 3311
local ITEM_SPEAK_ID = 3313
local HAS_CHOOSED_PLAYER_NUM = 0 --记录开场已完成选牌的玩家人数
local STEAL_SCROLL_TID = 3
local BAOHU_SCROLL_TID = 4
local XINGGUANG_SCROLL_TID = 5
local GONGXIANG_SCROLL_TID = 6
local MIYU_SCROLL_TID = 7
local POOR_SKILL_ID = 1122
--自建函数区--
function SyncPlayerStar(this)
	for _, who in pairs(ACTIVE_PLAYERID_LIST) do
		local ruid = this:GetRuid(who)
		if ruid and PLAYERLIST[ruid] then 
			this:Log(DEBUG, "玩家现在的星星", PLAYERLIST[ruid].star_num, "玩家旧星星", PLAYERLIST[ruid].star_num_old)
			if PLAYERLIST[ruid].star_num > PLAYERLIST[ruid].star_num_old then
				PLAYERLIST[ruid].star_num_times = PLAYERLIST[ruid].star_num_times + 1
				this:SetPlayerAttribute(false, who, 2, PLAYERLIST[ruid].star_num_times)
				this:NotifyPlayerAttribute(who, who)
				this:Log(DEBUG, "发送玩家", who, "的星星动画ID", PLAYERLIST[ruid].star_num_times, "给玩家", who)
				
				local change = PLAYERLIST[ruid].star_num - PLAYERLIST[ruid].star_num_old
				this:SetPlayerAttribute(false, who, 4, change)
				this:NotifyPlayerAttribute(who, who)
			end 
			this:ModifyPlayerRankKeyInfo(PLAYERLIST[ruid].id, PLAYERLIST[ruid].star_num, true)
			this:SendRankList(10, 0)
			PLAYERLIST[ruid].star_num_old = PLAYERLIST[ruid].star_num
			this:Log(DEBUG, "玩家现在的星星", PLAYERLIST[ruid].star_num, "玩家旧星星", PLAYERLIST[ruid].star_num_old)
			
			if PLAYERLIST[ruid].star_num >= M.WIN_POINT then
				if PLAYERLIST[ruid].is_out == false then
					local time_now = this:GetTime()
					local best_result = this:QueryPlayerRepu( who, RESULT_REPU )
					PLAYERLIST[ruid].end_time = time_now
					PLAYERLIST[ruid].result = PLAYERLIST[ruid].end_time - PLAYERLIST[ruid].start_time
					this:Log(INFO, "玩家本次完成了星星目标，通关成绩为", PLAYERLIST[ruid].result, "最终搜集的星星数量为", PLAYERLIST[ruid].star_num)
					if best_result <= 0 then 
						this:AddGeneralReward(REWARD_TYPE_INSTANCE, FIRST_WIN_REWARD, 0, 0, who)
						this:Log(INFO, "玩家今天首次通关，发奖")
						this:ModifyReputation(who, RESULT_REPU, PLAYERLIST[ruid].result, true)
						this:Log(INFO, "玩家首次通关成绩为最佳成绩", PLAYERLIST[ruid].result)
					else
						if PLAYERLIST[ruid].result < best_result then
							this:Log(INFO, "玩家本次通关成绩为最佳成绩，修改其最佳战绩")
							this:ModifyReputation(who, RESULT_REPU, PLAYERLIST[ruid].result, true)
						end
					end
					this:SendResultSingle(PLAYERLIST[ruid].result,who)
					PLAYERLIST[ruid].is_out = true
					this:FrozenSelf(who, true)
					this:ModifyReputation(who, BOX_REPU, 0, true)
					local box = this:QueryPlayerRepu( who, BOX_REPU )
					this:Log(DEBUG, "清空玩家大宝箱的声望", box)
					this:AddBuff( who, CANCEL_BUFF_ID, LEVEL)
					this:ClearPlayerAttribute(who)
					this:KickOutPlayer(who, 60)
					this:Log(INFO, "玩家完成胜利条件，踢出副本", who)
				end
			end
		end
	end
end

--[[function LastTime(a, b)
    local time1 = b[1]*60*60 - a[1]*60*60
	local time2 = b[2]*60 - a[2]*60
	local time3 = b[3] - a[3]
	local last_time = time1+time2+time3
	return last_time
end]] 

function CheckProfession(this, who, prof_id)
    local ruid = this:GetRuid(who)
	local c = 0
	if ruid and PLAYERLIST[ruid] then
		local a = PLAYERLIST[ruid].showid
		local b = #(M.COMBIN_LIST[a])
		this:Log(DEBUG, "玩家", ruid, "可供选择的列表", unpack(M.COMBIN_LIST[a]), "玩家的选择", prof_id)
		for i = 1, b do 
			if prof_id == M.COMBIN_LIST[a][i] then 
				c = c +1
			end			
		end
		
		this:Log(DEBUG, "比对结果", c)
	end
	
	if  c > 0 then 
	   return true
	else
	   return false	
	end
end

function MinusProfNum(this, prof_id)
    for i = 1, #PROF_LIST do 
		    if prof_id == PROF_LIST[i][1] then		
			    PROF_LIST[i][2] = PROF_LIST[i][2] - 1
				this:SetAttribute(false, i, PROF_LIST[i][1], 10+i, PROF_LIST[i][2]) 
				this:Log(DEBUG, "向客户端发送此职业", PROF_LIST[i][1], "人数", PROF_LIST[i][2])
			end 
	end
end

function T_KickOutPlayer(this, who)
    local id = who 
	local ruid = this:GetRuid(who)
    return function(this, func_self)
		if ruid and PLAYERLIST[ruid] then 
			if PLAYERLIST[ruid].is_out == false then
				if PLAYERLIST[ruid].star_num >= M.WIN_POINT then 
					local time_now = this:GetTime()
					local best_result = this:QueryPlayerRepu( who, RESULT_REPU )
					PLAYERLIST[ruid].end_time = time_now
					PLAYERLIST[ruid].result = PLAYERLIST[ruid].end_time - PLAYERLIST[ruid].start_time
					this:Log(INFO, "玩家本次完成了星星目标，通关成绩为", PLAYERLIST[ruid].result, "最终搜集的星星数量为", PLAYERLIST[ruid].star_num)
					if best_result <= 0 then 
						this:AddGeneralReward(REWARD_TYPE_INSTANCE, FIRST_WIN_REWARD, 0, 0, who)
						this:Log(INFO, "玩家今天首次通关，发奖")
						this:ModifyReputation(who, RESULT_REPU, PLAYERLIST[ruid].result, true)
						this:Log(INFO, "玩家首次通关成绩为最佳成绩", PLAYERLIST[ruid].result)
					else
						if PLAYERLIST[ruid].result < best_result then
							this:Log(INFO, "玩家本次通关成绩为最佳成绩，修改其最佳战绩")
							this:ModifyReputation(who, RESULT_REPU, PLAYERLIST[ruid].result, true)
						end
					end
					this:SendResultSingle(PLAYERLIST[ruid].result,who)
				else
					this:SendResultSingle(0,id)
				end
			end
			PLAYERLIST[ruid].is_out = true
			--this:FrozenSelf(id, true)
			this:ModifyReputation(who, BOX_REPU, 0, true)
			local box = this:QueryPlayerRepu( who, BOX_REPU )
			this:Log(DEBUG, "清空玩家大宝箱的声望", box)
			this:AddBuff( who, CANCEL_BUFF_ID, LEVEL)
			this:ClearPlayerAttribute(who)
			this:KickOutPlayer(id, 60)
			this:Log(INFO, "玩家游戏时间到，踢出副本", id)
			return 
		end
		end
end

--[[function T_GetFightingCapacity(this, who)
	local ruid = this:GetRuid(who)
	local id = who
	return function(this, func_self)
		local info = this:GetTargetInfo(id)
	    PLAYERLIST[ruid].fighting_capacity = info.fighting_capacity
		this:Log(DEBUG, "玩家", ruid, "战斗力为", PLAYERLIST[ruid].fighting_capacity)
		return 
		end
end]]

function T_FrozenSelf(this, who, bool) 
	local set = bool
	local ruid = this:GetRuid(who)
	local time_now = this:GetTime()
	PLAYERLIST[ruid].start_time = time_now
	this:SetPlayerAttribute(false, who, 1, time_now + 1200)
	this:NotifyPlayerAttribute(who, who)
	--用于向指定的客户端发消息，1为玩家倒计时时间，2是玩家星星加了多少次，3为道具ID，用于提示使用了对应ID的道具，4为玩家本次获得的星星数量，用于提示成功获得多少星星货币，100为第一个技能ID，101为技能持续时间（0代表这个技能一直存在，-1代表这个技能不存在，无需倒计时，其余值代表技能持续时间），110为第二个技能以此类推。201，特殊的密语提示喊话，传递密语盗取的星星数量
	this:FrozenSelf(who, set)
	this:Log(DEBUG, "玩家", who, ruid, "已解冻，游戏正式开始", "开始时间", PLAYERLIST[ruid].start_time)
end

function ChangPlayer(this, who, prof_id)
    local buff = M.BUFF_LIST
    for i = 1, #buff do 
	    if prof_id == buff[i][1] then
		    this:AddBuff( who, buff[i][2], LEVEL)
			this:Log(DEBUG, "玩家变身，变身ID为", buff[i][2])
		end
	end 
end 
--star为拾取星星数量，mine为开宝箱获取星星数量，people为从其他人身上获取的星星数量，friend为从其他玩家身上共享获得的星星
--player_state是一个table，依次存储1是否有星光状态，2保护之手，3羽毛，4密语状态，5共享状态，6磁铁，7后续技能占位1，8后续技能占位2，9宝箱，10种族天赋状态（1矮人，2盗贼，3小仙女，4圣骑士）
--关于state[2]的说明，1代表保护，-1代表被施加了一个被保护的debuff
--关于state[5]的说明，此状态是一个table, 第一个参数表示是否有共享状态，1表示有，0表示没有，第二个参数表示与玩家发生共享关系的玩家id
function OnPlayerStarNumChange(this, who, star, mine, people, friend)
	local ruid = this:GetRuid(who)
	if ruid and PLAYERLIST[ruid] then 
		local state = PLAYERLIST[ruid].player_state
		local talent = M.TALENT_LIST
		local skill = M.BUFF_SKILL_LIST
		local a = star or 0
		local b = mine or 0
		local c = people or 0
		local d = friend or 0
		this:Log(DEBUG, "玩家", who, ruid, "状态", unpack(PLAYERLIST[ruid].player_state), "星星的变化为", a, b, c, d)

		--玩家拾取的星星
		if a > 0 then 
			if state[5][1] == 1 then 
				a = a * skill[5].effect1
				this:Log(DEBUG, "玩家受共享状态影响，拾取的星星变为", a)
				local friend_id = state[5][2]
				this:Log(DEBUG, "共享的朋友", friend_id, "获得", a)
				OnPlayerStarNumChange(this, friend_id, 0, 0, 0, a)
			end
			
			PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + a
			this:Log(DEBUG, "玩家拾取星星获得", a)
			
			if state[10] == 3 then
				PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + a*talent[3][2]
				this:Log(DEBUG, "玩家拾取星星获得天赋加成", a*talent[3][2])
			end
			
			if state[1] == 1 then 
				PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + a*skill[1].effect1
				PLAYERLIST[ruid].player_state[1] = 0
				this:Log(DEBUG, "玩家拾取星星获得星光加成", a*skill[1].effect1, "同时星光状态为", PLAYERLIST[ruid].player_state[1])
			end 
		end 
		--玩家拾取宝箱
		if b > 0 then 
			if state[5][1] == 1 then 
				b = b * skill[5].effect1
				this:Log(DEBUG, "玩家受共享状态影响，宝箱的星星变为", b)
				local friend_id = state[5][2]
				this:Log(DEBUG, "共享的朋友", friend_id, "获得", b)
				OnPlayerStarNumChange(this, friend_id, 0, 0, 0, b)
			end
			
			PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + b
			this:Log(DEBUG, "玩家拾取宝箱获得", b)
			
			if state[10] == 1 then
				PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + b*talent[1][2]
				this:Log(DEBUG, "玩家拾取宝箱获得天赋加成", b*talent[1][2])
			end
			
			if state[1] == 1 then 
				PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + b*skill[1].effect1
				PLAYERLIST[ruid].player_state[1] = 0
				this:Log(DEBUG, "玩家拾取宝箱获得星光加成", b*skill[1].effect1, "同时星光状态为", PLAYERLIST[ruid].player_state[1])
			end
		end 
		--玩家从其他玩家身上获取星星，正数代表获得，负数代表被窃取
		if c > 0 then
			if state[5][1] == 1 then 
				c = c * skill[5].effect1
				this:Log(DEBUG, "玩家受共享状态影响，窃取的星星变为", c)
				local friend_id = state[5][2]
				this:Log(DEBUG, "共享的朋友", friend_id, "获得", c)
				OnPlayerStarNumChange(this, friend_id, 0, 0, 0, c)
			end
			
			local c1 = c
			
			if state[2] == -1 then 
				c1 = c1 * skill[2].effect2
				PLAYERLIST[ruid].player_state[2] = 0
				this:Log(DEBUG, "玩家被保护之手克制，获取的星星修正为", c1, "同时保护之手状态为", PLAYERLIST[ruid].player_state[2])
			end 
			
			PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + c1
			this:Log(DEBUG, "玩家通过窃取获得", c1)
			
			if state[10] == 2 then
				PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + c1*talent[2][2]
				this:Log(DEBUG, "玩家窃取星星获得天赋加成", c1*talent[2][2])
			end
			
		elseif c < 0 then
			if state[5][1] == 1 then 
				c = c * skill[5].effect1
				this:Log(DEBUG, "玩家受共享状态影响，窃取的星星变为", c)
				local friend_id = state[5][2]
				this:Log(DEBUG, "共享的朋友", friend_id, "获得", c)
				OnPlayerStarNumChange(this, friend_id, 0, 0, 0, c)
			end
			
			local c1 = c
			
			if state[2] == 1 then 
				c1 = c1 * skill[2].effect1
				PLAYERLIST[ruid].player_state[2] = 0
				this:Log(DEBUG, "玩家被保护之手克制，获取的星星修正为", c1, "同时保护之手状态为", PLAYERLIST[ruid].player_state[2])
			end 
			
			PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + c1
			this:SetPlayerAttribute(false, who, 205, c1)
			this:NotifyPlayerAttribute(who, who)
			this:Log(DEBUG, "玩家被窃取，获得", c1)
			
			if state[10] == 4 then
				local i = math.random(talent[4][2], talent[4][3])
				PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + i
				this:Log(DEBUG, "玩家被窃取获得星星加成", i)
			end
		--玩家共享获得
		elseif d ~= 0 then
			PLAYERLIST[ruid].star_num = PLAYERLIST[ruid].star_num + d
			this:Log(DEBUG, "玩家从其他玩家处获得共享星星", d)
		end 
	end
end

function ChangPlayerShareState(this, from, to)
	local ruid_from = this:GetRuid(from)
	local ruid_to = this:GetRuid(to)
	return function(this, func_self)
		if PLAYERLIST[ruid_from] and PLAYERLIST[ruid_to] then 
			this:Log(DEBUG, "玩家", from, ruid_from, "状态", unpack(PLAYERLIST[ruid_from].player_state), "星星", PLAYERLIST[ruid_from].star_num)
			this:Log(DEBUG, "玩家", to, ruid_to, "状态", unpack(PLAYERLIST[ruid_to].player_state), "星星", PLAYERLIST[ruid_to].star_num)
			if PLAYERLIST[ruid_from].player_state[5][1] ~= 0 then 
				PLAYERLIST[ruid_from].player_state[5][1] = 0
				PLAYERLIST[ruid_from].player_state[5][2] = 0
				this:Log(DEBUG, "修改玩家为", ruid_from, "状态5为", unpack(PLAYERLIST[ruid_from].player_state[5]))
			end 
			
			if PLAYERLIST[ruid_to].player_state[5][1] ~= 0 then 
				PLAYERLIST[ruid_to].player_state[5][1] = 0
				PLAYERLIST[ruid_to].player_state[5][2] = 0
				this:Log(DEBUG, "修改玩家为", ruid_to, "状态5为", unpack(PLAYERLIST[ruid_to].player_state[5]))
			end
			return
		end
	end
end

function ChangPlayerState(this, who, index)
	local ruid = this:GetRuid(who)
	return function(this, func_self)
		if ruid and PLAYERLIST[ruid] then 
			PLAYERLIST[ruid].player_state[index] = 0
			this:Log(DEBUG, "修改玩家为", ruid, "状态为", index, PLAYERLIST[ruid].player_state[index])
			OnPlayerIdChange(this)
			return
		end
	end 
end 

function OnPlayerIdChange(this)
	local ai_msg = {}
	local star_list = {}
	for i = 1, #EXIST_WAVE_ID do 
		star_list[i] = this:GetNPCList(nil, EXIST_WAVE_ID[i])
	end

	--与AI脚本之间通信，1，2，3，4代表玩家ID，11，12，13代表玩家磁铁状态
	for i = 1,5 do 
		if ACTIVE_PLAYERID_LIST[i] then 
			local id = ACTIVE_PLAYERID_LIST[i]
			local ruid = this:GetRuid(id)
			if ruid and PLAYERLIST[ruid] then
				ai_msg[4*i-3] = i
				ai_msg[4*i-2] = id
				ai_msg[4*i-1] = 10 + i
				ai_msg[4*i] = PLAYERLIST[ruid].player_state[6]
				this:Log(DEBUG, "写入传给AI的table为", table.unpack(ai_msg))
			end
		end
	end
	
	for i = 1, #star_list do 
		for _, npc in pairs(star_list[i]) do
			local npc_info = npc:GetSelfInfo()
			this:SendAIMsg(npc_info.id, ai_msg)
			this:Log(DEBUG, "向NPC", npc_info.id, "发送玩家id集合", table.unpack(ai_msg))
		end
	end
end
 
--[[function GenerateTool(this)
	this:DropMatter(22455, 3, 1, 1, 1)
	this:Log(DEBUG, "掉落物品", 22455, "位置为", 1, 1, 1)
end]]

function SyncPlayerState(this)--同步玩家状态和他基友的状态
	--[[for _, who in pairs(ACTIVE_PLAYERID_LIST) do 
		local my = GetPlayerState(this, who)
		this:SetPlayerAttribute(false, who, table.unpack(my))
		this:NotifyPlayerAttribute(who, who)
		this:Log(DEBUG, "发送玩家", who, "的状态", table.unpack(my), "给玩家", who)
		for _, jiyou in pairs(JIYOU_LIST) do
			if jiyou[1] == who then 
				if jiyou[2] ~= 0 then 
					this:Log(DEBUG, "玩家有基友")
					local he = GetPlayerState(this, jiyou[2])
					this:SetPlayerAttribute(false, jiyou[2], table.unpack(he))
					this:NotifyPlayerAttribute(jiyou[2], who)
					this:Log(DEBUG, "发送玩家", jiyou[2], "的状态", table.unpack(he), "给玩家", who)
				end
			end 
		end 
	end]]
	for _, who in pairs(ACTIVE_PLAYERID_LIST) do
		local ruid = this:GetRuid(who)
		local state_now = GetPlayerState(this, who)
		if PLAYERLIST[ruid].OldPlayerState then 
			for k, v in pairs(state_now) do
				if PLAYERLIST[ruid].OldPlayerState[k] then 
					if v ~= PLAYERLIST[ruid].OldPlayerState[k] then 
						this:SetPlayerAttribute(false, who, k, v)
						this:NotifyPlayerAttribute(who, who)
						this:Log(DEBUG, "发送玩家", who, "的值", k, v , "给who")
					end
				else
					PLAYERLIST[ruid].OldPlayerState[k] = v
					this:SetPlayerAttribute(false, who, k, v)
					this:NotifyPlayerAttribute(who, who)
					this:Log(DEBUG, "发送玩家", who, "的值", k, v , "给who")
				end
			end
		end
		PLAYERLIST[ruid].OldPlayerState = state_now
	end
	for _, who in pairs(ACTIVE_PLAYERID_LIST) do
		for _, jiyou in pairs(JIYOU_LIST) do
			if jiyou[1] == who then 
				if jiyou[2] ~= 0 then 
					this:Log(DEBUG, "玩家有基友", jiyou[2])
					this:NotifyPlayerAttribute(jiyou[2], who, true)
				end
			end 
		end 
	end
end 
--用于向指定的客户端发消息，1为玩家倒计时时间，2是玩家星星加了多少次，3为道具ID，用于提示使用了对应ID的道具，4为玩家本次获得的星星数量，用于提示成功获得多少星星货币，100为第一个技能ID，101为技能持续时间（0代表这个技能一直存在，-1代表这个技能不存在，无需倒计时，其余值代表技能持续时间），110为第二个技能以此类推。201，密语喊话1用，玩家newid，202,密语喊话1用，传递密语盗取的星星数量,203, 密语喊话2用，玩家newid，204窃取喊话用，发起窃取玩家newid，205，被窃取的数量
function GetPlayerState(this, who)
	local my = {}
	local ruid = this:GetRuid(who)
	local time_now = this:GetTime()
	local skill = M.BUFF_SKILL_LIST
	if ruid and PLAYERLIST[ruid] then 
		this:Log(DEBUG, "取得玩家当前状态", who, ruid, table.unpack(PLAYERLIST[ruid].player_state), "时间", time_now)
		for i = 1,7 do 
			if i <= 4 or i == 6 then 
				my[10*i + 90] = skill[i].index
				if PLAYERLIST[ruid].player_state[i] == 0 then 
					my[10*i + 91] = -1
					PLAYERLIST[ruid].time_list[i] = 0
				else
					if skill[i].last_time == 0 then 
						my[10*i + 91] = 0
					else
						if PLAYERLIST[ruid].time_list[i] == 0 then 
							my[10*i + 91] = time_now + skill[i].last_time
							PLAYERLIST[ruid].time_list[i] = time_now + skill[i].last_time
						else
							my[10*i + 91] = PLAYERLIST[ruid].time_list[i]
						end
					end
				end
			elseif i == 5 then
				my[10*i + 90] = skill[i].index
				if PLAYERLIST[ruid].player_state[i][1] == 0 then 
					my[10*i + 91] = -1
					PLAYERLIST[ruid].time_list[i] = 0
				else
					if skill[i].last_time == 0 then 
						my[10*i + 91] = 0
					else
						if PLAYERLIST[ruid].time_list[i] == 0 then 
							my[10*i + 91] = time_now + skill[i].last_time
							PLAYERLIST[ruid].time_list[i] = time_now + skill[i].last_time
						else
							my[10*i + 91] = PLAYERLIST[ruid].time_list[i]	
						end
					end
				end
			elseif i == 7 then 
				my[200] = skill[i].index
				if PLAYERLIST[ruid].player_state[9] == 0 then 
					my[201] = -1
					PLAYERLIST[ruid].time_list[i] = 0
				else
					if skill[i].last_time == 0 then 
						my[201] = 0
					else
						if PLAYERLIST[ruid].time_list[i] == 0 then 
							my[201] = time_now + skill[i].last_time
							PLAYERLIST[ruid].time_list[i] = time_now + skill[i].last_time
						else
							my[201] = PLAYERLIST[ruid].time_list[i]	
						end
					end
				end
			end
		end
		this:Log(DEBUG, "处理后玩家的状态表为", who, ruid, table.unpack(my))
		this:Log(DEBUG, "处理后玩家的时间戳为", who, ruid, table.unpack(PLAYERLIST[ruid].time_list))
	end 
	
	--[[if ruid and PLAYERLIST[ruid] then 
		this:Log(DEBUG, "取得玩家当前状态", who, ruid, table.unpack(PLAYERLIST[ruid].player_state), "时间", time_now)
		for i = 1,7 do 
			if i <= 4 or i == 6 then 
				my[4*i-3] = 10*i + 90
				my[4*i-2] = skill[i].index
				my[4*i-1] = 10*i + 91
				if PLAYERLIST[ruid].player_state[i] == 0 then 
					my[4*i] = -1
					PLAYERLIST[ruid].time_list[i] = 0
				else
					if skill[i].last_time == 0 then 
						my[4*i] = 0
					else
						if PLAYERLIST[ruid].time_list[i] == 0 then 
							my[4*i] = time_now + skill[i].last_time
							PLAYERLIST[ruid].time_list[i] = time_now + skill[i].last_time
						else
							my[4*i] = PLAYERLIST[ruid].time_list[i]
						end
					end
				end
			elseif i == 5 then
				my[4*i-3] = 10*i + 90
				my[4*i-2] = skill[i].index
				my[4*i-1] = 10*i + 91
				if PLAYERLIST[ruid].player_state[i][1] == 0 then 
					my[4*i] = -1
					PLAYERLIST[ruid].time_list[i] = 0
				else
					if skill[i].last_time == 0 then 
						my[4*i] = 0
					else
						if PLAYERLIST[ruid].time_list[i] == 0 then 
							my[4*i] = time_now + skill[i].last_time
							PLAYERLIST[ruid].time_list[i] = time_now + skill[i].last_time
						else
							my[4*i] = PLAYERLIST[ruid].time_list[i]	
						end
					end
				end
			elseif i == 7 then 
				my[4*i-3] = 200
				my[4*i-2] = skill[i].index
				my[4*i-1] = 201
				if PLAYERLIST[ruid].player_state[9] == 0 then 
					my[4*i] = -1
					PLAYERLIST[ruid].time_list[i] = 0
				else
					if skill[i].last_time == 0 then 
						my[4*i] = 0
					else
						if PLAYERLIST[ruid].time_list[i] == 0 then 
							my[4*i] = time_now + skill[i].last_time
							PLAYERLIST[ruid].time_list[i] = time_now + skill[i].last_time
						else
							my[4*i] = PLAYERLIST[ruid].time_list[i]	
						end
					end
				end
			end
		end
		this:Log(DEBUG, "处理后玩家的状态表为", who, ruid, table.unpack(my))
		this:Log(DEBUG, "处理后玩家的时间戳为", who, ruid, table.unpack(PLAYERLIST[ruid].time_list))
	end]]
	return my
end

function T_GenSubObjWave(this)
	local i = math.random(2, 3)
	if i == 1 then 
		this:Log(DEBUG, "此次不刷道具")--废弃不用
	elseif i == 2 then 
		GenItemWave(this, ITEM_WAVE_ID, 2)
	elseif i == 3 then 
		GenItemWave(this, ITEM_WAVE_ID, 3)
	end
end 
--此处的num_list只能是公共变量
function Swap(num_list, m, n)
	local a = num_list[n]
	num_list[n] = num_list[m]
	num_list[m] = a
end

function RandomSelect(num_list, n)
	local num = {}
	local l = #num_list
	for i = 1, n do 
		local j = math.random(i, l)
		Swap(num_list, i , j)
		num[i] = num_list[i]
	end
	return num
end

function GenBox(this)
	local box_list = RandomSelect(BOX_CONTROL_ID, 3)
	this:Log(DEBUG, "此次生成的宝箱控制器ID为", table.unpack(box_list))
	for i =1,3 do
		this:Log(DEBUG, "激活宝箱控制器", box_list[i])
		this:DeactiveController(box_list[i])
		this:ActiveController(box_list[i])
		--this:SystemSpeak(BOX_SPEAK_ID)
	end
end

function CreateStar(this, waveid)
	this:StartWave(waveid, false, LEVEL)
	this:Log(DEBUG, "生成星星波次", waveid)
	table.insert(EXIST_WAVE_ID, waveid)
end

function StartStarWave(this)
	local is_sky_star_refresh = false
	local location = RandomSelect(SYMBOL_STAR_WAVE_ID, 3)
	
	for _, v in pairs(EXIST_WAVE_ID) do 
		if v then 
			LV_KillWave(this, v)
			this:Log(DEBUG, "清除波次", v)
		end
	end
	
	EXIST_WAVE_ID = {}
	
	for k = 1,3 do
		if not is_sky_star_refresh then
			local i = math.random(1,2)
			if i == 1 then 
				CreateStar(this, 30+location[k])
			else
				local j = math.random(1,2)
				if j == 1 then 
					CreateStar(this, 40+location[k])
				else
					CreateStar(this, 50+location[k])
				end
				is_sky_star_refresh = true
			end
		else
			CreateStar(this, 30+location[k])
		end
	end

	
	this:SetAttribute(false, 20 , 3)
	this:SystemSpeak(STAR_SPEAK_ID)
	OnPlayerIdChange(this)
end

function pdf2cdf(pdf)
	local cdf = pdf
	local j = #pdf
	for i = 1, j do 
		if i > 1 then 
			cdf[i] = cdf[i] + cdf[i-1]
		end
	end
	cdf[j] = 1
	return cdf
end

function DiscreteSampling(cdf)
	local y = math.random()
	for i = 1, #cdf do
		local j = i
		if y < cdf[j] then 
			return j
		end
	end
	return 0
end

function GenItemWave(this, wave_list, num)
	local pdf = {}
	local skill = M.ALL_SKILL_LIST
	if wave_list == ITEM_WAVE_ID then 
		pdf = {skill[8].prob, skill[10].prob, skill[7].prob, skill[5].prob, skill[4].prob, skill[9].prob, skill[6].prob}
		local cdf = pdf2cdf(pdf)
		this:Log(DEBUG, "转换的累积概率分布为", table.unpack(cdf))
		for i = 1, num do 
			local wave_id_index = DiscreteSampling(cdf)
			this:Log(DEBUG, "生成子物体的波次指引为", wave_id_index)
			this:GenSubObjWave(ITEM_WAVE_ID[wave_id_index], 0)
			this:SetAttribute(false, 20 , 2)
			this:SystemSpeak(ITEM_SPEAK_ID)
			this:Log(DEBUG, "生成指定波次子物体", ITEM_WAVE_ID[wave_id_index])
		end
	end
end

function CheckStart(this)
	if not STARTED then
		HAS_CHOOSED_PLAYER_NUM = HAS_CHOOSED_PLAYER_NUM + 1
		this:Log(DEBUG, "已经选择职业的玩家人数", HAS_CHOOSED_PLAYER_NUM)
		local i = #ACTIVE_PLAYERID_LIST
		if HAS_CHOOSED_PLAYER_NUM >= i then 
			STARTED = true
			for _, who in pairs(ACTIVE_PLAYERID_LIST) do 
				local ruid = this:GetRuid(who)
				T_FrozenSelf(this, who, false)
			end
			this:SetAttribute(false, 30 , 1)
		end
	end
end

--通用函数区--
function OnLevelInit(this)
    this:InitLog(DEBUG, "5人欢乐大乱斗")
	----初始化进入副本的玩家键值，i代表职业ID，10+i代表该职业人数，20代表左侧信息栏信息，30代表“最开始”进入游戏时游戏开始与否
    this:SetAttribute(false, 1, 0, 11, 0, 2, 0, 12, 0, 3, 0, 13, 0, 4, 0, 14, 0, 5, 0, 15, 0, 30, 0) 
	local i = math.random(#(M.SHOW_LIST))
	ACTIVE_SHOW_LIST = M.SHOW_LIST[i]
	local j = #ACTIVE_SHOW_LIST
	this:Log(INFO, "i为", i, "j为", j, "动态显示列表为", table.unpack(ACTIVE_SHOW_LIST))
	this:Log(DEBUG, "5人欢乐大乱斗开启，客户端键值初始化完毕")
	
	this:MicroSecondTimer( true )
end

function OnLevelStart(this)
	this:Log(DEBUG, "开始HAPPY吧")
	this:LevelStart(1, Stage_1_progress)	
end

function OnPlayerEnter(this, who, replace)
	if not replace then 
		this:ClearPlayerAttribute(who)
		local ruid = this:GetRuid(who)
		PLAYER_NUM = PLAYER_NUM + 1
		this:Log(DEBUG, "副本内当前玩家人数", PLAYER_NUM)
		
		--[[if PLAYERLIST[ruid] then
			this:Log(INFO, "玩家重新进入副本")
			PLAYERLIST[ruid].id = who
			table.insert(ACTIVE_PLAYERID_LIST, PLAYERLIST[ruid].id)
			this:Log(DEBUG, "当前副本内玩家的ID集合为", table.unpack(ACTIVE_PLAYERID_LIST))
			this:SetCampMemberID(1, who)--临时测试用修改玩家阵营
			this:Log(DEBUG, "设置玩家阵营", who, 1)
			OnPlayerIdChange(this)
			this:ModifyPlayerRankOtherInfo(who, -1, 1, true)--断线重新，发送-1表示
			ChangPlayer(this, who, PLAYERLIST[ruid].prof_id)
			this:SendRankList(10, 0)
			SyncPlayerStar(this)
		else]]
		local info = this:GetTargetInfo(who)
		local i = math.random(#ACTIVE_SHOW_LIST)
		local time_now = this:GetTime()
		PLAYERLIST[ruid] = {}
		PLAYERLIST[ruid].ruid = ruid
		PLAYERLIST[ruid].id = who
		PLAYERLIST[ruid].timeid = who * 10
		this:Log(DEBUG, "玩家的定时器ID为", PLAYERLIST[ruid].timeid)
		PLAYERLIST[ruid].role_id = 0
		PLAYERLIST[ruid].star_num = 0
		PLAYERLIST[ruid].star_num_old = 0
		PLAYERLIST[ruid].star_num_times = 0
		PLAYERLIST[ruid].start_time = 0
		PLAYERLIST[ruid].end_time = 0
		PLAYERLIST[ruid].showid = ACTIVE_SHOW_LIST[i]
		PLAYERLIST[ruid].prof_id = 0
		PLAYERLIST[ruid].player_state = {0, 0, 0, 0, {0, 0}, 0, 0, 0, 0, 0}
		PLAYERLIST[ruid].is_out = false
		PLAYERLIST[ruid].time_list = {} --存放时间戳
		PLAYERLIST[ruid].result = 0 --存放玩家通关时间
		PLAYERLIST[ruid].been_stolen_time = 0 --存放玩家被窃取之手打中的次数
		PLAYERLIST[ruid].OldPlayerState = {} --存放玩家旧的状态列表，与新的状态做比较
		--player_state是一个table，依次存储1是否有星光状态，2保护之手，3羽毛，4密语状态，5共享状态，6磁铁，7后续技能占位1，8后续技能占位2，9宝箱，10种族天赋状态（1矮人，2盗贼，3小仙女，4圣骑士）
		this:SetCampMemberID(1, who)--临时测试用修改玩家阵营
		this:ModifyPlayerRankKeyInfo(who, PLAYERLIST[ruid].star_num, true)
		this:ModifyPlayerRankOtherInfo(who, ACTIVE_SHOW_LIST[i], 1, true)
		this:SendRankList(10, 0)
		this:Log(DEBUG, "向玩家发送ID为", ACTIVE_SHOW_LIST[i], "的职业组合")
		table.insert(ACTIVE_PLAYERID_LIST, PLAYERLIST[ruid].id)
		this:Log(DEBUG, "当前副本内玩家的ID集合为", table.unpack(ACTIVE_PLAYERID_LIST))
		OnPlayerIdChange(this)
		table.remove(ACTIVE_SHOW_LIST, i)
		--this:SetTimer(who+2, 1, 1, T_GetFightingCapacity(this, who))
		this:SetTimer(PLAYERLIST[ruid].timeid, 1200000, 1, T_KickOutPlayer(this, who), true)
		this:JumpTo( who, unpack(BORNPOS[1]))
		this:Log(DEBUG, "开始冻结玩家")
		this:FrozenSelf(who, true, WAIT_TIME)
		this:Log(DEBUG, "玩家", who, "已经被冻结")
		this:NotifyPlayerAttribute(who, who)
		this:Log(DEBUG, "玩家", ruid, "进入副本", "星星数", PLAYERLIST[ruid].star_num, "传送到", unpack(BORNPOS[1]), "开始时间为", PLAYERLIST[ruid].start_time, "玩家的定时器ID为", PLAYERLIST[ruid].timeid)
		--end
		
		this:WatchAction(who,false,false,1) --监听玩家施放技能
	end
end

function OnPlayerLeave(this, who)
    local ruid = this:GetRuid(who)
	--local game_num = this:QueryPlayerRepu( who, GAME_NUM_REPU )
	
	if ruid and PLAYERLIST[ruid] then 
		PLAYER_NUM = PLAYER_NUM - 1
		this:Log(DEBUG, "副本内当前玩家人数", PLAYER_NUM, "是否被系统踢出", PLAYERLIST[ruid].is_out)
		
		for i = 1, #ACTIVE_PLAYERID_LIST do 
			if ACTIVE_PLAYERID_LIST[i] == who then
				this:Log(DEBUG, "在玩家ID集合表位置", i, "删除玩家ID", ACTIVE_PLAYERID_LIST[i])
				table.remove(ACTIVE_PLAYERID_LIST, i)
				OnPlayerIdChange(this)
				break
			end
		end
		
		for i = 1, #JIYOU_LIST do 
			if JIYOU_LIST[i][1] == who then
				this:Log(DEBUG, "在基友表位置", i, "删除玩家和他的基友", table.unpack(JIYOU_LIST[i]))
				table.remove(JIYOU_LIST, i)
				break
			end
		end
		
		table.insert(ACTIVE_SHOW_LIST, PLAYERLIST[ruid].showid)
		this:Log(DEBUG, "动态显示列表为", table.unpack(ACTIVE_SHOW_LIST))
		MinusProfNum(this, PLAYERLIST[ruid].prof_id)
		
		this:ModifyPlayerRankKeyInfo(who, 0, true)
		this:ModifyPlayerRankOtherInfo(who, 0, 1, true)
		this:ModifyPlayerRankOtherInfo(who, 0, 2, true)
		
		this:Log(INFO, "删除对应玩家的信息", ruid)
		PLAYERLIST[ruid] = nil
	end
end

function OnPlayerSpecialOper(this, who, operType, param, param2)
	--param是一个table，依次1，为玩家选择的职业ID，2，选取的玩家对象（0代表没有选取玩家，其余值代表该玩家的newid）
	local p = param
	local p2 = param2
	local has_jiyou = false
	this:Log(DEBUG, "玩家特殊操作类型", operType, "值", table.unpack(p), param2)
    if operType == 7 then
		local ruid = this:GetRuid(who)
		if ruid and PLAYERLIST[ruid] then 
			if p[1] == 1 then 
				if PLAYERLIST[ruid].player_state[10] ~= p[2] then --判断玩家的职业ID是否发生了变化
					local check_result = CheckProfession(this, who, p[2])
					if check_result == true then 
						for i = 1, #PROF_LIST do 
							if p[2] == PROF_LIST[i][1] then
								PLAYERLIST[ruid].prof_id = PROF_LIST[i][1]
								ChangPlayer(this, who, PLAYERLIST[ruid].prof_id)
								PLAYERLIST[ruid].player_state[10] = p[2]
								PROF_LIST[i][2] = PROF_LIST[i][2] + 1
								this:SetAttribute(false, i, PROF_LIST[i][1], 10+i, PROF_LIST[i][2])--i代表职业ID，10+i代表该职业人数
								this:ModifyPlayerRankOtherInfo(who, PLAYERLIST[ruid].prof_id, 2, true)
								this:SendRankList(10, 0)
								if STARTED then 
									T_FrozenSelf(this, who, false)
								else
									CheckStart(this)
								end
								this:Log(DEBUG, "向客户端发送此职业", PROF_LIST[i][1], "人数", PROF_LIST[i][2], "以及玩家", who, "选择的职业", PLAYERLIST[ruid].prof_id)
								break
							else
								this:Log(DEBUG, "玩家没有选择", PROF_LIST[i][1])
							end
						end
					else
						this:Log(ERR, "玩家选择的职业不在所能选择的序列内")
					end
				end
			end
		end
		
		
		if PLAYERLIST[p2] then 
			for _, jiyou in pairs(JIYOU_LIST) do 
				if jiyou[1] == who then 
					has_jiyou = true
					if PLAYERLIST[p2].id ~= who then
						jiyou[2] = PLAYERLIST[p2].id
						this:Log(DEBUG, "玩家", who, "的基友为", jiyou[2], "基情状态", has_jiyou)
					else
						jiyou[2] = 0
					end
				end
			end
			
			if has_jiyou == false then 
				if PLAYERLIST[p2].id ~= who then 
					local ji = {}
					ji[1] = who
					ji[2] = PLAYERLIST[p2].id
					table.insert(JIYOU_LIST, ji)
					this:Log(DEBUG, "添加基情列表", table.unpack(ji))
				end
			end
		end
	end 
end 

function OnCountDownOver(this, countdown_type)
    --[[if countdown_type == COUNT_DOWN_ROAM_BATTLE_START_SMASHSTAR then 
	    STARTED = true
	end]]
	
	for _, player in pairs(PLAYERLIST) do
        if player.prof_id == 0 then 
		    local a = player.showid
	        local b = #(M.COMBIN_LIST[a])
			local c = math.random(b)
			player.prof_id = M.COMBIN_LIST[a][c]
		    local check_result = CheckProfession(this, player.id, player.prof_id)
			if check_result == true then 
				for i = 1, #PROF_LIST do 
					if player.prof_id == PROF_LIST[i][1] then	
					    ChangPlayer(this, player.id, player.prof_id)
						player.player_state[10] = player.prof_id
						PROF_LIST[i][2] = PROF_LIST[i][2] + 1
						this:SetAttribute(false, i, PROF_LIST[i][1], 10+i, PROF_LIST[i][2])
						this:ModifyPlayerRankOtherInfo(player.id, player.prof_id, 2, true)
						this:SendRankList(10, 0)
						CheckStart(this)
						this:Log(DEBUG, "向客户端发送此职业", PROF_LIST[i][1], "人数", PROF_LIST[i][2], "以及玩家", player.id, "选择的职业", player.prof_id)
						break
					end
				end
			else
		        this:Log(ERR, "玩家选择的职业不在所能选择的序列内")
			end 	
		end
	end
	CheckStart(this)
	this:Log(DEBUG, "倒计时结束，副本开启")
end

function OnCreatureHitBySkill( this, attacker, target, skill_id )
	this:Log(DEBUG, "攻击者", attacker, "向目标", target, "施放技能", skill_id)
	local from = attacker
	local to = target
	local id = skill_id
	local skill = M.ALL_SKILL_LIST
	local ruid_from = this:GetRuid(from)
	local ruid_to = this:GetRuid(to)
	if PLAYERLIST[ruid_to] then 
		this:Log(DEBUG, "玩家", to, ruid_to, "状态", unpack(PLAYERLIST[ruid_to].player_state), "星星", PLAYERLIST[ruid_to].star_num)
		if id == skill[1].index then 
			this:Log(DEBUG, "玩家触发技能", skill[1].name, "ID", skill[1].index)
			OnPlayerStarNumChange(this, to, skill[1].effect1, 0, 0)
		elseif id == skill[2].index then 
			this:Log(DEBUG, "玩家触发技能", skill[2].name, "ID", skill[2].index)
			OnPlayerStarNumChange(this, to, skill[2].effect1, 0, 0)
		elseif id == skill[3].index then 
			this:Log(DEBUG, "玩家触发技能", skill[3].name, "ID", skill[3].index)
			OnPlayerStarNumChange(this, to, skill[3].effect1, 0, 0)
		elseif id == skill[4].index then 
			this:Log(DEBUG, "玩家触发技能", skill[4].name, "ID", skill[4].index)
			PLAYERLIST[ruid_to].player_state[1] = 1
			this:Log(DEBUG, "修改玩家为", ruid_to, "状态1为", PLAYERLIST[ruid_to].player_state[1])
		elseif id == skill[5].index then 
			this:Log(DEBUG, "玩家触发技能", skill[5].name, "ID", skill[5].index)
			if PLAYERLIST[ruid_to].player_state[4] == 0 then 
				PLAYERLIST[ruid_to].player_state[2] = 1
				this:Log(DEBUG, "修改玩家为", ruid_to, "状态2为", PLAYERLIST[ruid_to].player_state[2])
			end 
		elseif id == skill[6].index then 
			this:Log(DEBUG, "玩家触发技能", skill[6].name, "ID", skill[6].index)
			if PLAYERLIST[ruid_to].player_state[2] == 0 then 
				PLAYERLIST[ruid_to].player_state[4] = 1
				this:Log(DEBUG, "修改玩家为", ruid_to, "状态4为", PLAYERLIST[ruid_to].player_state[4])
			end
		elseif id == skill[7].index then 
			this:Log(DEBUG, "玩家触发技能", skill[7].name, "ID", skill[7].index)
			
			this:SetPlayerAttribute(false, to, 204, from)
			this:NotifyPlayerAttribute(who, who)
			
			local from_get = PLAYERLIST[ruid_to].star_num * skill[7].get
			local to_lose = PLAYERLIST[ruid_to].star_num * skill[7].lose
			PLAYERLIST[ruid_to].been_stolen_time = PLAYERLIST[ruid_to].been_stolen_time + 1
			
			if PLAYERLIST[ruid_to].been_stolen_time >= 5 then
				this:AddBuff( to, POOR_SKILL_ID, 1)
			end
			
			if PLAYERLIST[ruid_to].player_state[2] == 1 then
				PLAYERLIST[ruid_from].player_state[2] = -1
				this:Log(DEBUG, "修改玩家为", ruid_from, "状态2为", PLAYERLIST[ruid_from].player_state[2])
				OnPlayerStarNumChange(this, from, 0, 0, from_get)
				OnPlayerStarNumChange(this, to, 0, 0, to_lose)
			elseif PLAYERLIST[ruid_to].player_state[4] == 1 then
				OnPlayerStarNumChange(this, from, 0, 0, from_get)
				OnPlayerStarNumChange(this, to, 0, 0, to_lose)
				local i = math.random()
				if i > 0 and i <= skill[6].list1[1] then 
					local change = PLAYERLIST[ruid_from].star_num * skill[6].list1[2]
					PLAYERLIST[ruid_from].star_num = PLAYERLIST[ruid_from].star_num - change
					PLAYERLIST[ruid_to].star_num = PLAYERLIST[ruid_to].star_num + change
					this:Log(DEBUG, "玩家", ruid_to, "触发概率为", skill[6].list1[1], "的list1密语", "玩家", ruid_from, "星星为", PLAYERLIST[ruid_from].star_num, "玩家", ruid_to, "星星为", PLAYERLIST[ruid_to].star_num)
					
					this:SetPlayerAttribute(false, to, 201, from, 202, change)
					this:NotifyPlayerAttribute(to, to)
					
					PLAYERLIST[ruid_to].player_state[4] = 0
				elseif i > skill[6].list1[1] and i <= (skill[6].list1[1] + skill[6].list2[1]) then
					local change = skill[6].list2[2]
					PLAYERLIST[ruid_from].star_num = PLAYERLIST[ruid_from].star_num + change
					PLAYERLIST[ruid_to].star_num = PLAYERLIST[ruid_to].star_num + change
					this:Log(DEBUG, "玩家", ruid_to, "触发概率为", skill[6].list2[1], "的list2密语", "玩家", ruid_from, "星星为", PLAYERLIST[ruid_from].star_num, "玩家", ruid_to, "星星为", PLAYERLIST[ruid_to].star_num)
					
					this:SetPlayerAttribute(false, to, 203, from)
					this:NotifyPlayerAttribute(to, to)
					
					PLAYERLIST[ruid_to].player_state[4] = 0
				elseif i > (skill[6].list1[1] + skill[6].list2[1]) and i <= (skill[6].list1[1] + skill[6].list2[1] + skill[6].list3[1]) then
					local change = skill[6].list3[2]
					PLAYERLIST[ruid_to].star_num = PLAYERLIST[ruid_to].star_num + change
					this:Log(DEBUG, "玩家", ruid_to, "触发概率为", skill[6].list3[1], "的list3密语", "玩家", ruid_from, "星星为", PLAYERLIST[ruid_from].star_num, "玩家", ruid_to, "星星为", PLAYERLIST[ruid_to].star_num)
					
					this:PersonalSpeak(3439, to)
					
					PLAYERLIST[ruid_to].player_state[4] = 0
				end
			else
				OnPlayerStarNumChange(this, from, 0, 0, from_get)
				OnPlayerStarNumChange(this, to, 0, 0, to_lose)
			end
		elseif id == skill[8].index then
			PLAYERLIST[ruid_to].player_state[3] = 1
			this:SetTimer(PLAYERLIST[ruid_to].timeid + 4, skill[8].last_time*1000, 1, ChangPlayerState(this, to, 3), true)
			this:Log(DEBUG, "修改玩家为", ruid_to, "状态3为", PLAYERLIST[ruid_to].player_state[3])
			this:Log(DEBUG, "玩家触发技能", skill[8].name, "ID", skill[8].index)
			this:Log(DEBUG, "玩家", to, "加BUFF", skill[8].buff_id)
		elseif id == skill[9].index then
			this:Log(DEBUG, "玩家触发技能", skill[9].name, "ID", skill[9].index)
			PLAYERLIST[ruid_from].player_state[5] = {}
			PLAYERLIST[ruid_from].player_state[5][1] = 1
			PLAYERLIST[ruid_from].player_state[5][2] = to
			PLAYERLIST[ruid_to].player_state[5] = {}
			PLAYERLIST[ruid_to].player_state[5][1] = 1
			PLAYERLIST[ruid_to].player_state[5][2] = from
			this:Log(DEBUG, "修改玩家为", ruid_from, "状态5为", unpack(PLAYERLIST[ruid_from].player_state[5]))
			this:Log(DEBUG, "修改玩家为", ruid_to, "状态5为", unpack(PLAYERLIST[ruid_to].player_state[5]))
			this:SetTimer(PLAYERLIST[ruid_to].timeid + 2, skill[9].last_time*1000, 1, ChangPlayerShareState(this, from, to), true)
		elseif id == skill[10].index then
			this:Log(DEBUG, "玩家触发技能", skill[10].name, "ID", skill[10].index)
			for i = 1, #ACTIVE_PLAYERID_LIST do 
				if ACTIVE_PLAYERID_LIST[i] == to then
					PLAYERLIST[ruid_to].player_state[6] = 1
					this:Log(DEBUG, "修改玩家为", ruid_to, "状态6为", PLAYERLIST[ruid_to].player_state[6])
					OnPlayerIdChange(this)
					this:SetTimer(PLAYERLIST[ruid_to].timeid + 3, skill[10].last_time*1000, 1, ChangPlayerState(this, to, 6), true)
				end
			end
		end
	end
end

function OnMineGathered( this,mine_tid,byWho,mine_id,x,y,z )
	this:Log(DEBUG, "矿", mine_tid, "被玩家", byWho, "采集")
	local mine = M.MINE_ID
	local who = byWho
	local ruid = this:GetRuid(who)
	if ruid and PLAYERLIST[ruid] then 
		if mine_tid == mine[1][1] then 
			OnPlayerStarNumChange(this, who, 0, mine[1][2], 0, 0)
			local i = math.random(5)
			if i == 1 then 
				this:ModifyReputation(who, BOX_REPU, 1, true)
				PLAYERLIST[ruid].player_state[9] = 1
				this:Log(DEBUG, "修改玩家为", ruid, "状态9为", PLAYERLIST[ruid].player_state[9])
				local j = this:QueryPlayerRepu( who, BOX_REPU )
				this:Log(DEBUG, "玩家", who, "声望ID", BOX_REPU, "修改为", j)
				this:SetAttribute(false, 20 , 4)
			end
		elseif mine_tid == mine[2][1] then
			OnPlayerStarNumChange(this, who, 0, mine[2][2], 0, 0)
			PLAYERLIST[ruid].player_state[9] = 0
			this:Log(DEBUG, "修改玩家为", ruid, "状态9为", PLAYERLIST[ruid].player_state[9])
			local k = this:QueryPlayerRepu( who, BOX_REPU )
			this:Log(DEBUG, "玩家", who, "声望ID", BOX_REPU, "修改为", k)
			this:SetAttribute(false, 20 , 1)
		end 
	end
end

function OnPlayerTryUseScroll(this, scrollTID, user, target)
	this:Log(DEBUG, "玩家 ", user, "尝试向", "target", "使用技能卷轴", scrollTID)
	local ruid_to = this:GetRuid(target)
	local speak = M.USE_ITEM_SPEAK_ID
	if scrollTID == STEAL_SCROLL_TID then --判断窃取之手的限制 
		if PLAYERLIST[ruid_to].been_stolen_time <= M.ALL_SKILL_LIST[7].limit-1 then
			this:Log(DEBUG, "玩家尝试使用窃取之手，被窃取的玩家已经被窃取的次数为", PLAYERLIST[ruid_to].been_stolen_time)
			this:PlayerUseScroll(scrollTID, user, target)
			this:SetPlayerAttribute(false, user, 3, scrollTID)
			this:NotifyPlayerAttribute(user, user)
		else
			this:PersonalSpeak(speak[scrollTID], user)
		end
	elseif scrollTID == BAOHU_SCROLL_TID then 
		if PLAYERLIST[ruid_to].player_state[2] == 0 then
			this:Log(DEBUG, "玩家尝试使用保护之手，玩家此时保护之手的状态为", PLAYERLIST[ruid_to].player_state[2])
			this:PlayerUseScroll(scrollTID, user, target)
			this:SetPlayerAttribute(false, user, 3, scrollTID)
			this:NotifyPlayerAttribute(user, user)
		else
			this:PersonalSpeak(speak[scrollTID], user)
		end
	elseif scrollTID == MIYU_SCROLL_TID then 
		if PLAYERLIST[ruid_to].player_state[4] == 0 then
			this:Log(DEBUG, "玩家尝试使用密语，玩家此时密语的状态为", PLAYERLIST[ruid_to].player_state[4])
			this:PlayerUseScroll(scrollTID, user, target)
			this:SetPlayerAttribute(false, user, 3, scrollTID)
			this:NotifyPlayerAttribute(user, user)
		else
			this:PersonalSpeak(speak[scrollTID], user)
		end
	elseif scrollTID == XINGGUANG_SCROLL_TID then 
		if PLAYERLIST[ruid_to].player_state[1] == 0 then
			this:Log(DEBUG, "玩家尝试使用星光，玩家此时星光的状态为", PLAYERLIST[ruid_to].player_state[1])
			this:PlayerUseScroll(scrollTID, user, target)
			this:SetPlayerAttribute(false, user, 3, scrollTID)
			this:NotifyPlayerAttribute(user, user)
		else
			this:PersonalSpeak(speak[scrollTID], user)
		end
	elseif scrollTID == GONGXIANG_SCROLL_TID then 
		if PLAYERLIST[ruid_to].player_state[5][1] == 0 then
			this:Log(DEBUG, "玩家尝试使用共享，玩家此时共享的状态为", PLAYERLIST[ruid_to].player_state[5])
			this:PlayerUseScroll(scrollTID, user, target)
			this:SetPlayerAttribute(false, user, 3, scrollTID)
			this:NotifyPlayerAttribute(user, user)
		else
			this:PersonalSpeak(speak[scrollTID], user)
		end
	else
		this:PlayerUseScroll(scrollTID, user, target)
		this:SetPlayerAttribute(false, user, 3, scrollTID)
		this:NotifyPlayerAttribute(user, user)
	end
end 

function Stage_1_progress(this)
	this:SetCountDown(COUNT_DOWN_ROAM_BATTLE_START_SMASHSTAR, 30)  --添加新的倒计时类型
	
	while not STARTED do 
		this:Sleep(2)
	end 
	
	if STARTED then 
		this:AddDynamicMoveMap(0)
		this:StartWave(GUANG_QIANG_WAVEID, false, LEVEL)
		this:ActiveController(LOCKED_BOX_WAVE_ID)
		for i = 1, #BOX_CONTROL_ID do 
			this:ActiveController(BOX_CONTROL_ID[i])
		end
		GenItemWave(this, ITEM_WAVE_ID, 5)
		this:SetTimer(1, 500, 0, SyncPlayerStar)
		this:SetTimer(2, 500, 0, SyncPlayerState)
		this:SetTimer(3, 20000, 0, GenBox)
		this:SetTimer(4, 90000, 0, StartStarWave)
		this:SetTimer(5, 15000, 0, T_GenSubObjWave)
		OnPlayerIdChange(this)
		--this:SetTimer(2, 5, 0, GenerateTool)
		

		
		--[[if STARTED then 
			this:SystemSpeak(START_SPEAK)
		end]]--配置开场喊话
	end
	
	while true do 
		this:Sleep(999) 
	end 
	
end