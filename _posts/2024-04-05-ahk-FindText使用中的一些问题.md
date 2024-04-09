---
title: "AHK中FindText使用的一些问题"
date: 2024-04-05 20:31:26 +0800
categories:
- blog
tags: 
- ahk
---

# 一、简要
这个函数库非常优秀, 可以极大的提高生产效率。  
作者飞跃的介绍说明: 
>这是一个简单的辅助工具，用于生成屏幕文字或图像的单行字符串字库。配合强大的“查找文字()”函数，在脚本中非常好用！  

>在编写自动化脚本时，如果采用先抓图，再制作小图，再用ImageSearch，操作太复杂，且不能仅使用脚本，还要打包图片。  

>如果仅仅采用颜色判断，显而易见太简陋了，不能精确判断当前的屏幕文字（或图像），及精确定位。  

>所以这个工具就应运而生了，生成“0_”字符组成的形象化图像描述，并且自动生成“查找文字()”的调用代码，复制到自己的脚本中就行了。  


本文中的代码均使用 AutoHotkey v2版本  

# 二、使用中的2个问题
不过使用中有两个地方不解, 也可能是我没找到正确的用法

## 1. 控件有悬停动画无法抓取成功的问题
当点击抓图的时候,需要右键才会抓图, 但把鼠标移动到某些需要抓取的文字上时, 文字的背景发生变化,导致抓到的图和最后需要识别的图有细微差别, 导致识别失败。但是脚本中是有 `ShowScreenShot` 这个函数的, 完全可以在点击抓取的时候,调用这个函数, 显示屏幕截图, 避免鼠标滑过对文字的影响。

解决方法:  
先使用`ShowScreenShot` 进行屏幕截图, 然后在抓图

## 2. 无法抓取鼠标右键菜单的问题
无法抓取某些页面, 比较典型的是鼠标右键菜单, 此时点击 `抓图` , 右键菜单会消失, 感觉可以在抓图按钮旁边加个延迟抓图的选项, 点击按钮后延迟再抓图。

解决方法:  
增加个 `CaptureTimeout`的选项, 抓图前增加2秒的延迟

## 解决方法
问题1和2 都是抓图时出现的, 解决方法都很简单, 下面是修改的部分代码
```autohotkey
Case "Capture", "CaptureS","CaptureTimeout":
	_Gui := FindText_Main
	if WinExist() != _Gui.Hwnd
		return this.GetRange()
	this.Hide()
	; 解决第二个问题: 靠下面这个判断加上2s的延迟
	if(cmd="CaptureTimeout"){
		sleep 2000
	}
	sleep 100
	; 解决第一个问题, 先贴图, 在抓图
	this.ShowScreenShot(-1000, -1000, 3000, 2000, ScreenShot:=1)
	sleep 100
	if !InStr(cmd, "CaptureS")
	{
		_Gui := FindText_Main
		w := _Gui["Myww"].Value
		h := _Gui["Myhh"].Value
		p := this.GetRange(w, h)
		sx := p[1], sy := p[2], sw := p[3] - p[1] + 1, sh := p[4] - p[2] + 1
			, Bind_ID := p[5], bind_mode := ""
		_Gui := FindText_Capture
		_Gui["MyTab1"].Choose(1)
	}
	else
	{
		sx := 0, sy := 0, sw := 1, sh := 1, Bind_ID := WinExist("A"), bind_mode := ""
		_Gui := FindText_Capture
		_Gui["MyTab1"].Choose(2)
	}
	; 解决第一个问题, 取消贴图
	this.ShowScreenShot()
	; this.ScreenShot()
```

修改后的程序, 增加了`延迟抓图`选项 
![延迟抓图](/assets/blog/20240405213921.bmp) 

# 三、其他改动
## 1. 将图像ID附加到命名中
默认的复制内容
```autohotkey
Text:="|<手机号>*135$71.000"
if (ok:=FindText(&X, &Y, 2190-150000, 351-150000, 2190+150000, 351+150000, 0, 0, Text)){
  ; FindText().Click(X, Y, "L")
}
```
修改后的复制内容
```autohotkey
Text手机号:="|<手机号>*135$71.000"
if (ok手机号:=FindText(&X手机号, &Y手机号, 2553-150000, 161-150000, 2553+150000, 161+150000, 0, 0, Text手机号)){
  ; FindText().Click(X手机号, Y手机号, "L")
}

```


## 2. 增加贴图函数 `ShowScreenShotPin`
供其他脚本调用, 这个脚本中已经有截图功能,  再加上贴图功能,  已经可以简陋的实现一些截图软件的功能, 可以少安装个截图软件, 但是无法完全替代。

## 3. 添加 `all`函数
传入脚本生成的 `Text` 字符串,  当所有目标都被找到时，返回 `true`, 否则返回 `false`
`FindText().all(text1,text2,text3)`
```AutoHotkey
/**
 * 当所有目标都被找到时，返回 true
 */
all(args*) {
	this.ScreenShot()
	for i, v in args {
		res := this.FindText(&x, &y, 0, 0, 3000, 3000, 0, 0, v, 0, 0)
		if (!res) {
			return false
		}
	}
	return true
}
```
## 4. 添加 `any` 函数
传入脚本生成的 `Text` 字符串,  当找到任意目标时，返回该目标的相关信息, , 否则返回 `false`
`FindText().any(text1,text2,text3)`

```autohotkey
/**
 * 当找到任意目标时，返回该目标的相关信息
 */
any(args*) {
	this.ScreenShot()
	for i, v in args {
		res := this.FindText(&x, &y, 0, 0, 3000, 3000, 0, 0, v, 0, 0)
		if (res) {
			return res
		}
	}
	return false
}
```

## 5. 添加一个依次点击功能的函数
解决问题: 点击菜单后会出现二级菜单, 继续点击二级菜单, 出现三级菜单, 还要继续点击的情况
```autohotkey
/**
	* 传入任意多的数组, 依次点击,每个数组有3项, 第一项是脚本生成的`Text`字符串, 第二项是布尔值, 是否需要点击, 第三项是找到后需要延迟多久去寻找下一个
	*/
chain(args*) {
	Sleep 200
	for i, v in args {
		res := this.FindText(&x, &y, 0, 0, 3000, 3000, 0, 0, v[1], 1, 0)
		if(!res){
			; t "第 " i " 个未找到"
			return
		}
		if (v[2]) {
			Click x,y
		}
		if(v[3]){
			Sleep v[3]
		} else {
			Sleep 300
		}
	}
	return true
}  
```

事例:在pr中, 先点击`修改`,在点击`解释素材`, 调整显示速度达到升格效果  
使用原版写的代码:
```autohotkey
  Text修改 := "|<修改>*153$24.8U0EBySUTY2zQM3Yzj3YwkTYRgGwQOEMNYGMMMRYNUH3U"
  if (ok := FindText(&X, &Y, 342 - 150000, 241 - 150000, 342 + 150000, 241 + 150000, 0, 0, Text修改))
  {
      FindText().Click(X, Y, "L")
      sleep 300
      Text解释素材 := "|<解释素材>*145$48.00000U008y7yTy84CGsW0U84IGSIDyzzzy8Q0U84JUzXTzAATI8848OAJzByDsMITYO86ScYJztzDU9YF4884g94b488MW8Q00003U00U"
      if (ok解释素材 := FindText(&X解释素材, &Y解释素材, 635 - 150000, 263 - 150000, 635 + 150000, 263 + 150000, 0, 0, Text解释素材))
      {
          FindText().Click(X解释素材, Y解释素材, "L")
          sleep 300
      }
  }
```
修改后:
```autohotkey
  Text修改 := "|<修改>*153$24.8U0EBySUTY2zQM3Yzj3YwkTYRgGwQOEMNYGMMMRYNUH3U"
  Text解释素材 := "|<解释素材>*145$48.00000U008y7yTy84CGsW0U84IGSIDyzzzy8Q0U84JUzXTzAATI8848OAJzByDsMITYO86ScYJztzDU9YF4884g94b488MW8Q00003U00U"

  FindText().chain(
    [Text修改,true,300],
    [Text解释素材,true,300]
  )
```

# 四、资源
作者:飞跃  
## 1.发布地址
- [[v2] FindText - Capture screen image into text and then find it](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=116471)
- [【函数】FindText中文版 （更新至9.4版本）- 屏幕抓字生成字库工具与找字函数 – AutoAHK](https://www.autoahk.com/archives/28493)  

## 2.相关教程
- [FindText 深度教程 v1.2](https://www.autoahk.com/archives/41636)

## 3.本地备用链接下载
原版备用链接 [FindText-v9.4中文版-V2.ahk](/assets/ahk/FindText-v9.4中文版-V2.ahk)  
修改后的代码 [findText-9.4-v2-qx修改.ahk](/assets/ahk/findText-9.4-v2-qx修改.ahk)  