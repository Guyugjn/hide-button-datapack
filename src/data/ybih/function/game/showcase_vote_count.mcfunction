# ybih:game/showcase_vote_count —— 按当前在线参赛者重新统计当前按钮的票
scoreboard players set #show_voters ybih.config 0
scoreboard players set #show_votes ybih.config 0
execute as @a[tag=ybih_player] if score @s ybih.era = #era ybih.config run scoreboard players add #show_voters ybih.config 1
execute as @a[tag=ybih_player] if score @s ybih.era = #era ybih.config if score @s ybih.vote = #show_bid ybih.config run scoreboard players add #show_votes ybih.config 1
execute if score #show_voters ybih.config matches 1.. if score #show_votes ybih.config = #show_voters ybih.config run tellraw @a {{TXT_S}}在线参赛者全票通过，跳过当前按钮{{TXT_M}}gold{{TXT_E}}
execute if score #show_voters ybih.config matches 1.. if score #show_votes ybih.config = #show_voters ybih.config run scoreboard players set #show_timer ybih.config 0
