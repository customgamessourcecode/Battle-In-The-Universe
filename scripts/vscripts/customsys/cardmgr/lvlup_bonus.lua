---卡牌升级后，给单位增加的增益技能。这里只记录特殊的，比如金币收益的，丹宝的炼丹，唐心莲的奉献等。
--如果没有记录，则默认就添加上伤害提升效果
local m = {
	--刘金彪
	tower_xn_liujinbiao = "card_lvlup_bonus_money",
	--缥缈
	tower_wwdx_piaomiao = "card_lvlup_bonus_money",
	--血刃神帝
	tower_xylz_xuerenshendi = "card_lvlup_bonus_money",
	--李亿玄
	tower_dzhz_liyixuan = "card_lvlup_bonus_money",
	--刘启
	tower_dzhz_liuqi = "card_lvlup_bonus_money",
	--刘彻
	tower_dzhz_liuche = "card_lvlup_bonus_money",
	--秃毛鹤
	tower_qm_tumaohe = "card_lvlup_bonus_money",
	--杜必书
	tower_zx_dubishu = "card_lvlup_bonus_money",
	--君念生
	tower_dzhz_junniansheng = "card_lvlup_bonus_money",
	--丹宝
	tower_mhj_danbao = "card_lvlup_bonus_danbao",
	--唐心莲
	tower_wdqk_tangxinlian = "card_lvlup_bonus_tangxinlian",
	--李逍遥
	tower_xjqxz_lixiaoyao = "card_lvlup_bonus_lixiaoyao"
}


--local init = function()
--	for cardName, ability in pairs(m) do
--		SetNetTableValue("card_lvlup",cardName,{ability=ability})
--	end
--end
--
--init()
return m;