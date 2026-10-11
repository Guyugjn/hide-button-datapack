# ybih:config/defaults —— 运行时状态初始化（每次 /reload 都会重置）
# 注意：配置项（#prep_time 等）不在这里重置，reload 会保留

# 旧存档没有新设置项的值，补一份默认；已经设过的（含关闭态）不会被覆盖
execute unless score #mode ybih.config matches 1.. run scoreboard players set #mode ybih.config 1
execute unless score #confirm ybih.config matches 1.. run scoreboard players set #confirm ybih.config 1
# 活动边界默认开启、半径 80。这不是审美取舍：「藏到底的保底分」只有在搜寻空间有界时
# 才代表「藏得好」—— 世界无界时 60 秒的藏匿时限足够跑到几百格外，而搜寻期只有 600 秒，
# 那些按钮根本找不到，于是人人拿满保底分、全员并列，这一局还会先白耗完倒计时才结算
execute unless score #border_on ybih.config matches 0.. run scoreboard players set #border_on ybih.config 1
execute unless score #border_r ybih.config matches 0.. run scoreboard players set #border_r ybih.config 80
execute unless score #hint_range ybih.config matches 1.. run scoreboard players set #hint_range ybih.config 10
execute unless score #showcase_on ybih.config matches 0.. run scoreboard players set #showcase_on ybih.config 1
# 旧版本的 150 / 200 档已经取消，落到新档位的上限 100
execute if score #border_r ybih.config matches 150.. run scoreboard players set #border_r ybih.config 100

# 一次性迁移：上面那两条只补「从未设置过」的存档，而老存档里 border_on / border_r 早就写死了值，
# 补默认对它们无效 —— 于是这次平衡修复对最需要它的老存档静默失效。所以显式迁一次，且只迁一次。
# 半径只在「仍是旧默认 100」时才动，已经手工调成别的档位的不覆盖。
# **代价（有意接受）**：连「主动关掉边界」这个选择也会被一并覆盖，这是一次性侵入；
# 书里第 5 页点一下「边界关」就回去了，之后 #border_migrated 已置位，再也不会被改
execute unless score #border_migrated ybih.config matches 1.. run scoreboard players set #border_on ybih.config 1
execute unless score #border_migrated ybih.config matches 1.. if score #border_r ybih.config matches 100 run scoreboard players set #border_r ybih.config 80
execute unless score #border_migrated ybih.config matches 1.. run scoreboard players set #border_migrated ybih.config 1

scoreboard players set #state ybih.config 0
scoreboard players set #timer ybih.config 0
scoreboard players set #next_id ybih.config 1
# 本局藏下的按钮数，也就是轮末围观用来排序的编号；按局递增，局初与重置归零
scoreboard players set #seq ybih.config 0
scoreboard players set #protect_timer ybih.config 5
# 保护机制的判据之一：唯一写点是 config/apply，这里补一条同风格的守卫。
# 缺了它会读到 0，保护遍历就变成每 tick 触发一次
execute unless score #protect_period ybih.config matches 1.. run scoreboard players set #protect_period ybih.config 5
scoreboard players set #hint_timer ybih.config 60
scoreboard players set #actionbar_timer ybih.config 0
scoreboard players set #best ybih.config 0
scoreboard players set #more ybih.config 0
scoreboard players set #ray_step ybih.config 0
scoreboard players set #ray_owner ybih.config 0
# 提示扫描时暂存「这位玩家自己的编号」：hint_probe 靠它排除自己的按钮
scoreboard players set #hint_self ybih.config 0
scoreboard players set #press_owner ybih.config 0
# 本局编号必须跨 reload 保持递增：一旦从头开始，上一局遗留在未加载区块里的按钮标记
# 会和当前局撞号，重新被当成本局按钮
execute unless score #era ybih.config matches 1.. run scoreboard players set #era ybih.config 0
# 按钮编号与 #era 同待遇，必须跨 reload 保持递增：重置会让往局残留的标记
# 与本届新按钮撞号，按下判定就会认错按钮
execute unless score #bid ybih.config matches 1.. run scoreboard players set #bid ybih.config 0
scoreboard players set #use_min ybih.config 0
# 按下判定时暂存「被按下的这个按钮」的编号，与玩家的 ybih.used_bid 比对
scoreboard players set #press_bid ybih.config 0
# 位图去重的三个暂存：这位玩家的掩码、取模用的模数、按钮位图取模后的结果
scoreboard players set #hit_bit ybih.config 0
scoreboard players set #hit_pow ybih.config 0
scoreboard players set #hit_now ybih.config 0
# 本次按下不计分的理由：1 超出位图上限 / 2 已经拿过 / 3 分值已空 / 4 按钮不在了
scoreboard players set #deny ybih.config 0
# 位图写入的成败：写不进去就不计分，并撤掉闸门让玩家重试
scoreboard players set #hit_ok ybih.config 0
# 本轮搜寻者人数：轮流模式开场时算一次，只用于播报
scoreboard players set #seekers_total ybih.config 0
# 按钮递减后的余额：与 #gained（这次拿到的分）分开记，不要互相覆盖
scoreboard players set #btn_left ybih.config 0
# 本次取走后还剩几份：按下播报要它，由 award_score 在递减之前算好
scoreboard players set #btn_remain ybih.config 0
# 按下播报用：#press_live 物主在不在线（决定走带名字还是不带名字那版）
scoreboard players set #press_live ybih.config 0
# 射线锁定按钮时暂存读到的编号
scoreboard players set #use_bid ybih.config 0
scoreboard players set #button_count ybih.config 0
scoreboard players set #hide_timer ybih.config 60
scoreboard players set #round ybih.config 0
scoreboard players set #cycle ybih.config 1
scoreboard players set #need_tool ybih.config 0
scoreboard players set #tick ybih.config 0
scoreboard players set #gained ybih.config 0
scoreboard players set #ranked ybih.config 0
scoreboard players set #player_count ybih.config 0
scoreboard players set #rounds_total ybih.config 1
scoreboard players set #best_score ybih.config -2147483648
scoreboard players set #best_finds ybih.config -1
scoreboard players set #best_tfirst ybih.config 999999
scoreboard players set #best_id ybih.config 0
# 本回合藏匿者的编号：turn_next 在他还在线时记下，超时结算靠它找得到掉线的人
scoreboard players set #hide_id ybih.config 0
# 超时结算时目标不在线：扣分与 ybih.turn 置位都做不了，把那一笔记在这个位图当欠账，等他重连自己来还。
# 位号 = 编号 - 1，与 ybih.hit 同一套取模判定。用位图而不是单个编号：
# 连续两次「超时且掉线」时，后一笔不会把前一笔顶掉。
# #owed_src / #owed_bit / #owed_pow / #owed_now 是算这一笔时的暂存
scoreboard players set #owed ybih.config 0
scoreboard players set #owed_src ybih.config 0
scoreboard players set #owed_bit ybih.config 0
scoreboard players set #owed_pow ybih.config 0
scoreboard players set #owed_now ybih.config 0
# 结算时探一下目标在不在线，0 表示没探到（该记账），1 表示已经当场处理过
scoreboard players set #hide_found ybih.config 0
scoreboard players set #bw_now ybih.config 0

# 侧边栏每秒对一次在线名单：计时器、兜底重建周期、以及判断「有人进出」的两个快照
scoreboard players set #board_timer ybih.config 20
scoreboard players set #board_gc ybih.config 10
scoreboard players set #online_prev ybih.config 0
scoreboard players set #online_sum ybih.config 0
scoreboard players set #online_sum_prev ybih.config 0

# 围观展示：当前看到第几个、本轮到第几个、停留计时、剩余秒数、标题刷新倒计时，
# 以及正在看的这个按钮的分是不是已经被拿完
scoreboard players set #show_found ybih.config 0
scoreboard players set #show_idx ybih.config 0
scoreboard players set #show_timer ybih.config 0
scoreboard players set #show_total ybih.config 0
scoreboard players set #show_len ybih.config 200
scoreboard players set #show_sec ybih.config 0
scoreboard players set #show_refresh ybih.config 0
# 传送后的定格计时：到 0 之前由 showcase_pin 每 tick 把人按回站位
scoreboard players set #freeze ybih.config 0
# 挑下一个待展示按钮时的排序暂存：当前最小的藏匿编号
scoreboard players set #show_best ybih.config 0
# 当前展示按钮的物主编号：showcase_glow 写，showcase_bar 与 player/buff_guard 读。
# 围观开始前没有任何物主，落 0 与「ybih.id 从 1 起分配」配套，谁都匹配不上
scoreboard players set #show_owner ybih.config 0

# 收回保不住的按钮时，用它暂存物主编号
scoreboard players set #fix_owner ybih.config 0

# 保底分结算（见 game/bonus_settle / bonus_run / bonus_pay）：
#   #bonus_done  本轮的结算做过没有，gate 用；每轮开局由 start_begin / next_round 归零
#   #bonus_amt   这一轮每位「藏到底」的人能拿几分 = #player_count / 2
#   #bonus_count 本轮**实际发出去**了几份（物主离线就发不出去）
#   #bonus_total 本轮有几个按钮一次都没被找到（含物主离线、发不出去的那些）
#   #bonus_owner 当前这个按钮的物主编号、#bonus_got 他这次算不算发成功
scoreboard players set #bonus_done ybih.config 0
scoreboard players set #bonus_amt ybih.config 0
scoreboard players set #bonus_count ybih.config 0
scoreboard players set #bonus_total ybih.config 0
scoreboard players set #bonus_owner ybih.config 0
scoreboard players set #bonus_got ybih.config 0

# 搜寻提示的档位（见 game/hint_scan / hint_one）：
#   #hint_band 最近的别人的按钮落在哪一档半径里，0 = 配置半径内一个都没有
#   #band_r    当前正在试的那一档，由 hint_scan 逐档写入
scoreboard players set #hint_band ybih.config 0
scoreboard players set #band_r ybih.config 0
# 残局八向方位（见 game/hint_dir / hint_dir_cmp）：
#   #late_from 进入残局的剩余秒数门槛 = #search_time / 3，进搜寻时算一次
#   #hd_px/#hd_pz 玩家坐标、#hd_bx/#hd_bz 按钮坐标；#hd_dx/#hd_dz 差值，
#   #   #hd_ax/#hd_az 各自取绝对值后，用「一个轴是否大于另一个轴的两倍」分出
#   #   主轴（东西 / 南北）与对角；#hd_2z 与 #hd_a2x 是那两个两倍值
#   #   #hd_sx/#hd_sz 正负号（1 = 正方向），#hd_axis 1 东西 / 2 南北 / 3 对角
#   **坐标一律不乘 100**：现有 border_edge_check 那套 ×100 定标在坐标接近
#   ±3×10⁷ 时会撞 int32 回绕，而方位判定只要符号与量级，整数部分足够
scoreboard players set #late_from ybih.config 0
scoreboard players set #hd_px ybih.config 0
scoreboard players set #hd_pz ybih.config 0
scoreboard players set #hd_bx ybih.config 0
scoreboard players set #hd_bz ybih.config 0
scoreboard players set #hd_dx ybih.config 0
scoreboard players set #hd_dz ybih.config 0
scoreboard players set #hd_ax ybih.config 0
scoreboard players set #hd_az ybih.config 0
scoreboard players set #hd_2z ybih.config 0
scoreboard players set #hd_a2x ybih.config 0
scoreboard players set #hd_sx ybih.config 0
scoreboard players set #hd_sz ybih.config 0
scoreboard players set #hd_axis ybih.config 0
#   #hd_pid 是发起这次提示的玩家编号：方位文案在按钮标记身上发，靠它把玩家选回来
scoreboard players set #hd_pid ybih.config 0

# 搜寻期的局势统计（见 game/points_count）：
#   #points_left  场上还没被取走的分总和
#   #unfound_count 一次都没被按过的按钮数（保底窗口还开着的那些）
#   #unfound_prev 上一秒的值，用来抓「刚刚全被找到」这个转折
scoreboard players set #points_left ybih.config 0
scoreboard players set #unfound_count ybih.config 0
scoreboard players set #unfound_prev ybih.config -1

# 首次被找到的探针（见 button/award_grant 与 award_score）：
# 1 = 这次按下是这个按钮的第一次，物主的保底分作废，要单独通知他
# #hit_all 是读位图全值的暂存，判「全零」用它而不是 #hit_now（见 award_grant 的注释）
scoreboard players set #first_find ybih.config 0
scoreboard players set #hit_all ybih.config 0

# 探测队伍是否已存在时的暂存分
scoreboard players set #team_tmp ybih.config 0

# 放置校验：位置泡在水里或挨着水、岩浆
scoreboard players set #wet ybih.config 0

# 贴边界放置的判定用：记两位小数的坐标、差值、限值与取绝对值用的 -1
scoreboard players set #bx ybih.config 0
scoreboard players set #bz ybih.config 0
scoreboard players set #cx ybih.config 0
scoreboard players set #cz ybih.config 0
scoreboard players set #dx ybih.config 0
scoreboard players set #dz ybih.config 0
scoreboard players set #lim ybih.config 0
scoreboard players set #out_border ybih.config 0
scoreboard players set #neg ybih.config -1

# Boss 栏倒计时用：当前阶段的剩余/总秒数、拆位后的分与秒、剩余百分比
scoreboard players set #cd ybih.config 0
scoreboard players set #cd_total ybih.config 1
scoreboard players set #cd_min ybih.config 0
scoreboard players set #cd_sec ybih.config 0
scoreboard players set #cd_s10 ybih.config 0
scoreboard players set #cd_s1 ybih.config 0
scoreboard players set #pct ybih.config 100
# 对局保险的重发周期
scoreboard players set #buff_timer ybih.config 20

# 换算常量
scoreboard players set #c10 ybih.config 10
scoreboard players set #c20 ybih.config 20
scoreboard players set #c60 ybih.config 60
scoreboard players set #c100 ybih.config 100
scoreboard players set #c2 ybih.config 2
# 求三分之一（残局门槛 #late_from）用
scoreboard players set #c3 ybih.config 3
# 求最小值时的哨兵：比任何真实编号都大
scoreboard players set #c_max ybih.config 2147483647
# 等待室：粒子节拍（2 秒一次）
scoreboard players set #room_timer ybih.config 0
# 九宫格棋的暂存只在一次操作内用，每次都由 room/ttt_reset 或各函数开头归零。
# 这里只放一个「人是否在房里」——button/trigger_run 每次都要读它
scoreboard players set #t_in ybih.ttt 0
# 名单位占用表：1 = 这个号有人坐了。由 room/ttt_seat 补记、room/ttt_release 放掉、
# room/ttt_reset 整体清空。这里给初值，免得首次加载时这些条目还不存在
# （判空位用的是 unless ... matches 1..，条目缺失与「0」等价，但初值写明白更好读）
scoreboard players set #rs1 ybih.ttt 0
scoreboard players set #rs2 ybih.ttt 0
scoreboard players set #rs3 ybih.ttt 0
scoreboard players set #rs4 ybih.ttt 0
scoreboard players set #rs5 ybih.ttt 0
scoreboard players set #rs6 ybih.ttt 0
scoreboard players set #rs7 ybih.ttt 0
scoreboard players set #rs8 ybih.ttt 0
scoreboard players set #rs9 ybih.ttt 0
scoreboard players set #rs10 ybih.ttt 0
scoreboard players set #rs11 ybih.ttt 0
scoreboard players set #rs12 ybih.ttt 0
# 等待信息栏的暂存：自己的编号，以及数出来的队列位次
scoreboard players set #my_id ybih.config 0
scoreboard players set #my_rank ybih.config 1
