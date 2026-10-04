# ybih:load —— 建立记分板，清空对局数据但保留设置

scoreboard objectives add ybih.config dummy
scoreboard objectives add ybih.id dummy
scoreboard objectives add ybih.score dummy
scoreboard objectives add ybih.placed dummy
scoreboard objectives add ybih.turn dummy
scoreboard objectives add ybih.owner_id dummy
scoreboard objectives add ybih.death deathCount
scoreboard objectives add ybih.finds dummy
scoreboard objectives add ybih.t_first dummy
# ybih.trigger 必须是 trigger 准则，聊天栏的点击命令才能用 /trigger 提交
scoreboard objectives add ybih.trigger trigger
scoreboard objectives add ybih.used dummy
# 刚交互的按钮编号：进度触发时射线锁定是哪一个按钮，按下判定再靠它认领按下者
scoreboard objectives add ybih.used_bid dummy
# 按钮自身的编号：每登记一个发一个，用来把「玩家交互的按钮」与「被按下的按钮」对上
scoreboard objectives add ybih.bid dummy
scoreboard objectives add ybih.era dummy
# 按钮被保护机制恢复过几次：反复被破坏的位置靠它止损
scoreboard objectives add ybih.fixed dummy
# 本局里这个按钮是第几个藏下的：轮末围观按它排序，先藏的先看
scoreboard objectives add ybih.seq dummy
# 按钮自身还剩几份分：挂在按钮标记上，谁按谁取走一份，取完这个按钮才收掉。
# 分值挂在按钮上而不是全局池，场上每个按钮各算各的
scoreboard objectives add ybih.value dummy
# 按钮上的位图：记「谁从这个按钮上拿过分」，位号 = 玩家编号 - 1。
# 记分板没有按位与，判定写成取模，见 button/award_grant
scoreboard objectives add ybih.hit dummy
# 侧边栏看的是镜像榜：真实分数在 ybih.score，这里只放当前在线的人
scoreboard objectives add ybih.board dummy

# 围观高亮用：发光轮廓的颜色取自队伍，红=分被拿完、绿=还有分。
# 队伍只装标记与「正被展示的那个按钮的物主」，其余玩家一律不进队。
# team add 对已存在的队伍会失败，和 objectives add 同一个坑，
# 所以只在首次加载建一次。没有 if team 这种条件，用 team list 的成败去探
# （team list 指定的队伍不存在时是失败，store success 得 0）
scoreboard players set #team_tmp ybih.config 0
execute store success score #team_tmp ybih.config run team list ybih_found
execute if score #team_tmp ybih.config matches 0 run team add ybih_found
execute store success score #team_tmp ybih.config run team list ybih_notfound
execute if score #team_tmp ybih.config matches 0 run team add ybih_notfound
team modify ybih_found color red
team modify ybih_notfound color green

scoreboard objectives setdisplay sidebar ybih.board
scoreboard objectives modify ybih.board displayname {{TXT_S}}分数{{TXT_E}}

# 只有首次加载才写默认配置；之后 reload 保留在书里改过的设置
execute unless score #prep_time ybih.config matches 1.. run function ybih:config/apply

function ybih:config/defaults
function ybih:game/reload_cleanup
function ybih:game/bar_init

tellraw @a {{TXT_S}}[你的按钮我来藏] 数据包已加载，对局数据已清空{{TXT_M}}green{{TXT_E}}
tellraw @a {{TXT_S}}设置与集合点已保留；数据包更新后旧设置书不会跟着变，请重新用 /function ybih:admin/book 拿一本{{TXT_M}}gray{{TXT_E}}
