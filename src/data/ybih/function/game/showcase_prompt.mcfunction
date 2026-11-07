# ybih:game/showcase_prompt —— 给当前局在线参赛者补发投票入口
scoreboard players set #v_prompt ybih.config 0
execute unless score @s ybih.v_seen = #show_bid ybih.config run scoreboard players set #v_prompt ybih.config 1
execute unless score @s ybih.v_tick = #v_prev ybih.config run scoreboard players set #v_prompt ybih.config 1
execute if score #v_prompt ybih.config matches 1 run tellraw @s [{{TXT_S}}任意投票入口均投给当前展示，在线参赛者全票跳过：{{TXT_E}},{{BTN_SHOW_SKIP}}]
scoreboard players operation @s ybih.v_seen = #show_bid ybih.config
scoreboard players operation @s ybih.v_tick = #v_clock ybih.config
