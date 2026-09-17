# ybih:stop —— 中止当前对局（不发奖励、不播报排名）

playsound minecraft:ui.button.click player @s ~ ~ ~ 1 1
execute if score #state ybih.config matches 0 run tellraw @s {{TXT_S}}当前没有进行中的对局{{TXT_M}}red{{TXT_E}}
execute unless score #state ybih.config matches 0 run tellraw @a {{TXT_S}}[你的按钮我来藏] 对局已中止{{TXT_M}}yellow{{TXT_E}}
execute unless score #state ybih.config matches 0 run function ybih:game/cleanup_end
