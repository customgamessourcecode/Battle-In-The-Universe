require("customsys.reg.config")
---dota7.20护甲公式改变，护甲减伤会提高至100%，导致怪物不受伤害。这个是自定义的护甲系统
CustomArmor = require("customsys.custom_armor.CustomArmor")
Elements = require("customsys.Elements")
--用来获取单位的闪避、输入输出伤害加成效果
SpecialAttributes = require("customsys.SpecialAttributes")

Path = require("customsys.path")
Spawner = require("customsys.spawner.spawner")
Towermgr = require("customsys.towermgr")
Cardmgr = require("customsys.cardmgr.cardmgr")

--游戏开始的设置界面
setup = require("customsys.setup")
---游戏内抽卡功能
draw = require("customsys.draw")
Shop = require("customsys.Shop")
Store = require("customsys.Store")

RankList = require("customsys.RankList")

bgm = require("customsys.bgm")