# ybih:game/showcase_vote —— 为当前展示按钮投票（执行者是参赛者）
execute if score @s ybih.vote = #show_bid ybih.config run tellraw @s {{TXT_S}}你已经投过当前按钮的跳过票{{TXT_M}}gray{{TXT_E}}
execute unless score @s ybih.vote = #show_bid ybih.config run tellraw @s {{TXT_S}}已投票跳过当前按钮，在线参赛者全票后生效{{TXT_M}}green{{TXT_E}}
scoreboard players operation @s ybih.vote = #show_bid ybih.config
