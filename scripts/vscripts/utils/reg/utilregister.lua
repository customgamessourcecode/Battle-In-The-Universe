--所有工具类的注册，减少在gameMode中的require

--玩家相关的操作
PlayerUtil = require("utils.PlayerUtil")
--实体操作工具类，封装了dota2的接口以便于使用(写代码的时候可以在ide中通过提示获取方法，而不容易出错，也便于查找)
EntityHelper = require('utils.EntityHelper')
--BGM控制
music = require('utils.music')
--提示信息气泡工具类
SpeachUtil = require("utils.SpeachUtil")
--客户端通知工具类，简单包装了Notifications
NotifyUtil = require("utils.NotifyUtil")
--http连接工具类
http = require("utils.http")
--简单的物品操作工具类
ItemUtil = require("utils.ItemUtil")

Filters = require("utils.Filters")
