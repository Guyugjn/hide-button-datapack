# ybih:button/probe_here —— 当前位置是不是刚放下的按钮（已登记过的不算）

execute if block ~ ~ ~ #minecraft:buttons unless entity @e[tag=ybih_button,distance=..0.5] run function ybih:button/register_here
