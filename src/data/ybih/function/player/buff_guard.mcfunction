# ybih:player/buff_guard —— 每秒把对局保险顶回去
# 死亡会清空全部状态效果，喝牛奶、被外部 /effect clear 也一样，而这些都不会摘掉
# ybih_buffed 标签。所以「该不该有」只看标签，效果本身每秒无条件重发一次
#
# 夜视与高亮走另一套路子，各自有凭据，不变量都是「有凭据 = 现在该有这份效果」：
# 成立就每秒顶上，不成立就连效果带凭据一起收掉。它们发的都是一次性的长时长，
# 靠这里续期，所以凭据一旦回收，效果最迟一秒后熄灭
#
# 观战夜视：凭据 ybih_spect_nv，不变量「有凭据 = 此刻在旁观」
# 围观夜视：凭据 ybih_show_nv，不变量「有凭据 = 此刻在围观阶段」
# 围观高亮：凭据 ybih_show_owner，不变量「有凭据 = 此刻在围观阶段，且自己就是当前物主」
# 藏匿观战夜视：凭据 ybih_current，不变量「有凭据 = 此刻是本轮的藏匿者」。
# 这一条跨两个阶段（藏匿时他在冒险模式里，搜寻时才转成旁观），
# 判据要看阶段加编号，与上面三条都不同，单独写在文件末尾
#
# 这四条不是多余的保险：收尾点（showcase_end / cleanup_end / reload_cleanup /
# reset）用的全是 @a，只够得到当时在线的人。断开连接的人会把标签连同剩余时长
# 一起存进存档 —— 效果时长在离线期间不递减，重连后他仍旧带着那份效果。
# 夜视只是亮着，发光却是穿墙可见的轮廓：掉线的物主带着它回到对局，
# 全程都会被人隔着墙看见。
#
# 高亮还多一层：game/showcase_bar 只要看到「还有谁带着 ybih_show_owner」，
# 就会把那个人的名字写进 Boss 栏标题。所以过期的凭据不只是残留，
# 还会让整轮围观显示错的人是谁

scoreboard players set #buff_timer ybih.config 20
execute as @a[tag=ybih_buffed] run function ybih:player/apply_buff

execute as @a[tag=ybih_spect_nv,gamemode=spectator] run effect give @s minecraft:night_vision 60 0 true
execute as @a[tag=ybih_spect_nv,gamemode=!spectator] run effect clear @s minecraft:night_vision
execute as @a[tag=ybih_spect_nv,gamemode=!spectator] run tag @s remove ybih_spect_nv

execute as @a[tag=ybih_show_nv] unless score #state ybih.config matches 4 run effect clear @s minecraft:night_vision
execute as @a[tag=ybih_show_nv] unless score #state ybih.config matches 4 run tag @s remove ybih_show_nv

# 围观高亮的两条判据合起来就是它的不变量：留下 = 在围观阶段，且自己就是当前物主。
# 第一条管「围观已经结束，人却掉线错过了收尾」；第二条管「围观还在走，
# 但按钮已经换到别人手上」—— 他重连回来时身上还挂着上一屏的凭据，
# 而 @a 收尾既够不到离线时的他，下一次 showcase_glow 又最久要等一整屏才来
execute as @a[tag=ybih_show_owner] unless score #state ybih.config matches 4 run function ybih:game/showcase_glow_clear
execute as @a[tag=ybih_show_owner] if score #state ybih.config matches 4 unless score @s ybih.id = #show_owner ybih.config run function ybih:game/showcase_glow_clear

# 藏匿凭据 ybih_current 的观战夜视。它的不变量是「有凭据 = 此刻是本轮的藏匿者」，
# 但这条凭据横跨两个阶段，光看 #state 认不出真假，要连 #hide_id 一起看：
# #hide_id 是 turn_next 在他还在线时记下的编号，超时结算也靠它找人。
# 拿编号比对，才能认出「离线期间被换了人、凭据却还挂在身上」的那位 ——
# 只看阶段会把他当成本轮的藏匿者，接着给他续上一份不该有的观战夜视。
#
# 藏匿阶段（#state 2）什么都不做：这时他在冒险模式里藏按钮，本来就没有夜视可续，
# 也绝不能清掉凭据 —— 清了 button/on_place 就选不中他，这一轮的藏匿直接卡死。
# 搜寻阶段（#state 3）只有轮流模式的那位转成了旁观并该有夜视，按编号每秒顶上；
# 经典模式的搜寻期由 enter_searching_classic 摘掉凭据，走下面第二条收掉。
# 其余阶段（围观 #state 4 与对局外 #state 0）一律连效果带凭据收掉
execute as @a[tag=ybih_current] unless score #state ybih.config matches 2..3 run function ybih:game/current_clear
execute as @a[tag=ybih_current] if score #state ybih.config matches 3 unless score #mode ybih.config matches 2 run function ybih:game/current_clear
execute as @a[tag=ybih_current] if score #state ybih.config matches 3 if score #mode ybih.config matches 2 unless score @s ybih.id = #hide_id ybih.config run function ybih:game/current_clear
execute as @a[tag=ybih_current] if score #state ybih.config matches 3 if score #mode ybih.config matches 2 if score @s ybih.id = #hide_id ybih.config run effect give @s minecraft:night_vision 60 0 true
