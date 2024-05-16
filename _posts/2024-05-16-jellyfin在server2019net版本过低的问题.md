---
title: "jellyfin10.9.1在server2019提示net版本过低的问题"
date: 2024-05-16 12:00:00 +0800
categories:
- blog
tags: 
- jellyfin
---

# 操作环境
jellyfin : 10.9.1
windows : server 2019
# 问题
在最新的 [jellyfin](https://repo.jellyfin.org/)  10.9.1 中, 打开后会提示需要 [.net 4.8.1](https://dotnet.microsoft.com/zh-cn/download/dotnet-framework/net481) 才能运行, 但如果使用 server2019 做NAS, server2019 可以安装的最高版本是 [.net 4.8.0](https://dotnet.microsoft.com/zh-cn/download/dotnet-framework/net48),  导致可以安装却无法运行。
# 临时解决
安装后打开文件夹内的 `Jellyfin.Windows.Tray.exe.config` 文件, 将第四行的`4.8.1`改回为之前的`4.7.2`, 此时就能运行jellyfin, 目前还不知道会有什么其他bug问题。

# 其他相关讨论
官方论坛上有一个[讨论](https://forum.jellyfin.org/t-solved-strange-choice-for-10-9-1-making-it-non-functional-in-win-server-2019?highlight=4.8.1) ,但是他给的解决方案是替换带`tray`的4个文件, 目前还不知道两种方案谁优谁劣。
[百度贴吧](https://tieba.baidu.com/p/9016646307)也有人反映了这个问题。
