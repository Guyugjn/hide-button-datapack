# ybih:config/border_help —— 手动改边界的命令写法

playsound minecraft:ui.button.click player @s ~ ~ ~ 1 1
tellraw @s {{TXT_S}}—— 手动改活动边界 ——{{TXT_M}}gold{{TXT_E}}
tellraw @s {{TXT_S}}命令收的是边长，书里的半径要乘 2{{TXT_E}}
tellraw @s [{{TXT_S}}半径 120 → {{TXT_E}},{{TXT_S}}/worldborder set 240{{TXT_M}}gray{{TXT_E}}]
tellraw @s [{{TXT_S}}半径 240 → {{TXT_E}},{{TXT_S}}/worldborder set 480{{TXT_M}}gray{{TXT_E}}]
tellraw @s [{{TXT_S}}把中心对到集合点：站在集合点上敲 {{TXT_E}},{{TXT_S}}/worldborder center ~ ~{{TXT_M}}gray{{TXT_E}}]
tellraw @s {{TXT_S}}想让自己敲的尺寸在开局时保留，就在书里把半径选成「跟随手动」{{TXT_M}}gray{{TXT_E}}
tellraw @s {{TXT_S}}边界只在主世界生效，别让玩家钻进下界躲着{{TXT_M}}gray{{TXT_E}}
