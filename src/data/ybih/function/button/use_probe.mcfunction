# ybih:button/use_probe —— 当前这一步的位置上有没有本局的按钮标记
# 执行者是射线发起玩家。命中就交给 use_lock 锁定编号并停止射线
#
# 只认本局的按钮：往局残留在未加载区块里的标记也带着 ybih_button，
# 若锁到它就会抄来一个旧编号，press_scan 那边比对不上，这次按下白按。
# ybih.era 的比对放在 use_lock 里做 —— 选择器里写不下记分板比较

execute if entity @e[tag=ybih_button,tag=!ybih_pending,distance=..0.8,limit=1,sort=nearest] unless entity @s[tag=ybih_ray_found] run function ybih:button/use_lock
