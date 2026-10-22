# ybih:game/bar_update —— 每秒刷新 Boss 栏：进度条、标题、颜色
# 由 game/second_tick 在阶段判定之后调用，保证切换阶段时标题立刻跟上

# 重设可见玩家，中途重进的人也能马上看到
execute if entity @a[tag=ybih_player] run bossbar set ybih:timer players @a[tag=ybih_player]
execute unless entity @a[tag=ybih_player] run bossbar set ybih:timer players

# 当前阶段的剩余秒数与总秒数
scoreboard players set #cd ybih.config 0
scoreboard players set #cd_total ybih.config 1
execute if score #state ybih.config matches 1 run scoreboard players operation #cd ybih.config = #timer ybih.config
execute if score #state ybih.config matches 1 run scoreboard players operation #cd_total ybih.config = #prep_time ybih.config
execute if score #state ybih.config matches 2 run scoreboard players operation #cd ybih.config = #hide_timer ybih.config
execute if score #state ybih.config matches 2 run scoreboard players operation #cd_total ybih.config = #hide_time ybih.config
execute if score #state ybih.config matches 3 run scoreboard players operation #cd ybih.config = #timer ybih.config
execute if score #state ybih.config matches 3 run scoreboard players operation #cd_total ybih.config = #search_time ybih.config

# 剩余秒数拆成「分」与两位秒，标题里拼成 m:ss
# 分数组件按原值显示，前导零只能靠拆位补
scoreboard players operation #cd_min ybih.config = #cd ybih.config
scoreboard players operation #cd_min ybih.config /= #c60 ybih.config
scoreboard players operation #cd_sec ybih.config = #cd ybih.config
scoreboard players operation #cd_sec ybih.config %= #c60 ybih.config
scoreboard players operation #cd_s10 ybih.config = #cd_sec ybih.config
scoreboard players operation #cd_s10 ybih.config /= #c10 ybih.config
scoreboard players operation #cd_s1 ybih.config = #cd_sec ybih.config
scoreboard players operation #cd_s1 ybih.config %= #c10 ybih.config

# 剩余比例（0–100）交给逐档分派写进进度条
scoreboard players operation #pct ybih.config = #cd ybih.config
scoreboard players operation #pct ybih.config *= #c100 ybih.config
scoreboard players operation #pct ybih.config /= #cd_total ybih.config
function ybih:game/bar_value

# 标题：第几轮 · 阶段 · 剩余
# 三行都不指定 color，让 Boss 栏自身的颜色属性统管整条标题
execute if score #state ybih.config matches 1 run bossbar set ybih:timer name [{{TXT_S}}第 {{TXT_E}},{{SCORE_ROUND}},{{TXT_S}} / {{TXT_E}},{{SCORE_ROUNDSTOTAL}},{{TXT_S}} 轮 · 准备中 · {{TXT_E}},{{SCORE_CD_MIN}},{{TXT_S}}:{{TXT_E}},{{SCORE_CD_S10}},{{SCORE_CD_S1}}]
execute if score #state ybih.config matches 2 run bossbar set ybih:timer name [{{TXT_S}}第 {{TXT_E}},{{SCORE_ROUND}},{{TXT_S}} / {{TXT_E}},{{SCORE_ROUNDSTOTAL}},{{TXT_S}} 轮 · 藏匿中 · {{TXT_E}},{{SCORE_CD_MIN}},{{TXT_S}}:{{TXT_E}},{{SCORE_CD_S10}},{{SCORE_CD_S1}}]
# 搜寻态按「是否已进最后三分之一」分两句。这一段同时也是给玩家的信号：
# 提示从这里开始变密并补报方位，写在 Boss 栏上比发一行聊天更安静，
# 也不会把聊天栏里刚播过的按下播报顶走
execute if score #state ybih.config matches 3 if score #timer ybih.config > #late_from ybih.config run bossbar set ybih:timer name [{{TXT_S}}第 {{TXT_E}},{{SCORE_ROUND}},{{TXT_S}} / {{TXT_E}},{{SCORE_ROUNDSTOTAL}},{{TXT_S}} 轮 · 搜寻中 · 剩 {{TXT_E}},{{SCORE_POINTS}},{{TXT_S}} 分 · {{TXT_E}},{{SCORE_CD_MIN}},{{TXT_S}}:{{TXT_E}},{{SCORE_CD_S10}},{{SCORE_CD_S1}}]
execute if score #state ybih.config matches 3 if score #timer ybih.config <= #late_from ybih.config run bossbar set ybih:timer name [{{TXT_S}}第 {{TXT_E}},{{SCORE_ROUND}},{{TXT_S}} / {{TXT_E}},{{SCORE_ROUNDSTOTAL}},{{TXT_S}} 轮 · 搜寻中 · 最后冲刺 · 剩 {{TXT_E}},{{SCORE_POINTS}},{{TXT_S}} 分 · {{TXT_E}},{{SCORE_CD_MIN}},{{TXT_S}}:{{TXT_E}},{{SCORE_CD_S10}},{{SCORE_CD_S1}}]

# 颜色随剩余时间收紧：过半绿、两成以上黄、不足两成红
execute if score #pct ybih.config matches 51.. run bossbar set ybih:timer color green
execute if score #pct ybih.config matches 20..50 run bossbar set ybih:timer color yellow
execute if score #pct ybih.config matches ..19 run bossbar set ybih:timer color red
