# ybih:config/defaults —— 运行时状态初始化（每次 /reload 都会重置）
# 注意：配置项（#prep_time 等）不在这里重置，reload 会保留

# 旧存档没有新设置项的值，补一份默认；已经设过的（含关闭态）不会被覆盖
execute unless score #mode ybih.config matches 1.. run scoreboard players set #mode ybih.config 1
execute unless score #confirm ybih.config matches 1.. run scoreboard players set #confirm ybih.config 1
execute unless score #border_on ybih.config matches 0.. run scoreboard players set #border_on ybih.config 0
execute unless score #border_r ybih.config matches 0.. run scoreboard players set #border_r ybih.config 100
execute unless score #hint_range ybih.config matches 1.. run scoreboard players set #hint_range ybih.config 10
execute unless score #showcase_on ybih.config matches 0.. run scoreboard players set #showcase_on ybih.config 1
# 旧版本的 150 / 200 档已经取消，落到新档位的上限 100
execute if score #border_r ybih.config matches 150.. run scoreboard players set #border_r ybih.config 100

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
scoreboard players set #hint_hit ybih.config 0
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
# 超时结算时目标不在线：扣分与 ybih.turn 置位都做不了，把编号挂在这里当欠账，等他重连自己来还。
# 必须是独立于 #hide_id 的假玩家，否则下一位藏匿者一上任就把欠账抹掉
scoreboard players set #hide_owed ybih.config 0
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
# 求最小值时的哨兵：比任何真实编号都大
scoreboard players set #c_max ybih.config 2147483647
