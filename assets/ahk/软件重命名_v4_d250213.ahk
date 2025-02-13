#Requires AutoHotkey v2.0
; #Include <fun_toStr>
; F9:: Filerename()
#F2:: Filerename()

reNameGui := Gui()

; 当前文件的基本信息
; fName.ext 扩展名
; fName.sel 文件名(包括地址)
; fName.parentPath 所在文件夹
; fName.FileNameNoExt 文件名，不带扩展名
; fName.Drive 文件所在的盘符
; fName.official 是否官方
; fName.setup 安装或便携版
; fName.remarks  备注
; fName.folder 是否文件夹
fName := {}
; GUI中的显示信息
; reNameInput.class 分类
; reNameInput.onlyName 软件名
; reNameInput.official 是否官方
; reNameInput.setup 安装或便携版
; reNameInput.version 版本号
; reNameInput.date  修改日期
; reNameInput.remarks  备注
; reNameInput.ext 扩展名
; reNameInput.DelimiterChars 分隔符
reNameInput := {}
; GUI 中的一些设置选项
reNameSet := {}
reNameSet.dateShort := false
; 预览名字
name_pre := ""
Filerename() {
    global fName
    ; 临时存储剪贴板
    Candy_Saved_ClipBoard := ClipboardAll()
    A_Clipboard := ""
    send "^c"
    Errorlevel := !ClipWait(0.5)
    ; 在 edge 浏览器中 会出现 ctrl 没有释放的情况
    Send("{Ctrl Up}")
    ;如果选择为空，则退出
    If (ErrorLevel) {
        ;还原粘贴板
        A_Clipboard := Candy_Saved_ClipBoard
        Candy_Saved_ClipBoard := ""
        Return
    }

    ; 分类
    ; 分类前缀，可以没有
    class_list_1 := ["", "01", "02", "03", "04", "05", "06", "07", "08", "09"]
    ; 分类后缀，实际以此为准, 修改此处就可以修改分类
    class_list_2 := ["", "装机", "办公", "图片", "视频", "系统", "工具", "整理", "硬件", "其他", "NAS", "Adobe"]
    class_list_1_length := class_list_1.Length
    class_list := []
    for index, value in class_list_2 {
        if (index <= class_list_1_length) {
            class_list.Push(class_list_1[index] . value)
        } else {
            class_list.Push(value)
        }
    }
    ; class_list := ["01核心","02日用","03办公","04图片","05视频","06文件","07工具","08硬件","09其他",""]

    ; 下面三行仅代表下拉菜单的内容， 如果修改，还有两处需要修改，第二处是匹配文件名的地方， 第三处是根据匹配到的文件名选择下拉菜单的地方
    offici_list := ["", "官方", "破解", "修改", "可激活"]
    setup_list := ["", "安装包", "便携版"]
    plugins_list := ["", "插件", "汉化补丁", "存档数据", "配置文件", "修改器", "MOD"]

    fName := {}
    ; 文件: 后缀名, 多文件“MultiFiles”
    ; 文本: ShortText 或者 LongText
    fName.ext := ""
    ; 文件: 文件名(包括地址)
    ; 文本: 具体文本
    fName.sel := ""
    ; 文件: 所在文件夹
    ; 文本: 则内容为空
    fName.parentPath := ""

    fName.sel := A_Clipboard

    ; 判断网络路径, 如何是映射的网络驱动器, 则不支持
    netPath_check(fName.sel)

    SplitPath(fName.sel, &CandySel_FileNameWithExt, &oparentPath, &oext, &CandySel_FileNameNoExt, &CandySel_Drive)

    fName.FileName := CandySel_FileNameWithExt
    fName.parentPath := oparentPath
    fName.ext := oext
    fName.FileNameNoExt := Trim(CandySel_FileNameNoExt)
    fName.Drive := CandySel_Drive

    fName.classIndex := ""
    fName.plugins := ""
    fName.date := ""
    fName.version := ""
    fName.official := ""
    fName.setup := ""
    fName.remarks := ""
    fName.folder := false

    ; 判断是否是文件夹
    if DirExist(fName.sel) {
        ; MsgBox "The target folder does exist."
        ; fName.FileNameNoExt .= "." . fName.ext
        fName.FileNameNoExt := fName.FileName
        fName.ext := ""
        fName.folder := true
    }

    fileNameSplit()

    ; 显示 GUI
    FilerenameGui()

    ; -- 结束，下面是调用的函数

    ; 处理文件名
    fileNameSplit() {
        global fName
        global reNameSet
        fName.DelimiterChars := " "
        arr := []
        arr1 := StrSplit(fName.FileNameNoExt, "_")
        arr2 := StrSplit(fName.FileNameNoExt, " ")
        if (arr1.length > 1) {
            for index, v in arr1 {
                ; 匹配分类
                for class_index, class_value in class_list {
                    if (v == class_value) {
                        fName.classIndex := class_index
                        arr1.Delete(index)
                    }
                }
                ; 匹配
                if (RegExMatch(v, "(插件|汉化补丁|存档数据|配置文件|修改器|MOD)", &fplugins)) {
                    fName.plugins := fplugins[1]
                    arr1.Delete(index)
                }
                ; 匹配版本号
                if (RegExMatch(v, "i)^v(.*)", &fVersion)) {
                    fName.version := fVersion[1]
                    arr1.Delete(index)
                }
                ; 匹配日期
                if (RegExMatch(v, "d?(\d{4}[-\.]\d{2}[-\.]\d{2})", &fDate)) {   ; 长日期 2010-03-17
                    oDate := StrReplace(fDate[1], ".")
                    oDate := StrReplace(oDate, "-")
                    fName.date := FormatTime(oDate, "yyMMdd")
                    arr1.Delete(index)
                } else if (RegExMatch(v, "(^\d{1,2}[-\.]\d{2})", &fDate)) {  ; 月日： 03-17
                    reNameSet.dateShort := true
                    fName.date := fDate[1]
                    arr1.Delete(index)
                } else if (RegExMatch(v, "^d(\d{6})", &fDate)) { ;  短日期： 220317
                    fName.date := fDate[1]
                    arr1.Delete(index)
                }
                ; 匹配 官方|破解|修改
                if (RegExMatch(v, "^(官方|破解|修改|可激活)$", &fofficial)) {
                    fName.official := fofficial[1]
                    arr1.Delete(index)
                }
                ; 匹配 便携特征
                if (RegExMatch(v, "i)^(安装包|便携版|Setup|installer|Portable)$", &fsetup)) {
                    fName.setup := fsetup[1]
                    arr1.Delete(index)
                }
                ; 匹配 备注
                if (RegExMatch(v, "^&(.*)", &fremarks)) {
                    fName.remarks := fremarks[1]
                    arr1.Delete(index)
                }

                fName.DelimiterChars := "_"
            }
            arr := arr1
        } else if (arr2.length > 1) {
            for index, v in arr2 {
                if (RegExMatch(v, "^v(.*)", &fVersion)) {
                    fName.version := fVersion[1]
                    arr2.Delete(index)
                }
                if (RegExMatch(v, "d?(\d{4}[-\.]\d{2}[-\.]\d{2})", &fDate)) {
                    fName.date := fDate[1]
                    arr2.Delete(index)
                } else if (RegExMatch(v, "(^\d{1,2}[-\.]\d{2})", &fDate)) {
                    reNameSet.dateShort := true
                    fName.date := fDate[1]
                    arr2.Delete(index)
                }
            }
            arr := arr2
        }

        ; 解析后文件名数组
        arrFinal := []
        if (arr.Length) {
            for index, v in arr {
                if (arr.Has(index)) {
                    arrFinal.Push(v)
                }
            }
        } else {
            arrFinal.Push(fName.FileNameNoExt)
        }

        ; 根据日期是否是最开始判断order顺序
        if (RegExMatch(fName.FileNameNoExt, "^\d{4}[-\.]\d{2}[-\.]\d{2}") || RegExMatch(fName.FileNameNoExt, "^\d{1,2}[-\.]\d{2}")) {
            reNameSet.order := true
        } else {
            reNameSet.order := false
        }

        ; put "输出str"
        ; put toStr(arrFinal, "_")
        fName.nameArr := arrFinal
        fName.onlyName := toStr(arrFinal, fName.DelimiterChars)

    }

    ; 弹出Gui
    FilerenameGui() {
        global fName
        global reNameGui
        global reNameInput

        reNameGui := Gui()
        reNameGui.OnEvent("Close", GuiClose)
        reNameGui.OnEvent("Escape", GuiClose)

        oSaved := reNameGui.Submit()
        ; reNameGui.Opt("+AlwaysOnTop   +Owner +LastFound -MinimizeBox")
        reNameGui.Opt("+Owner +LastFound -MinimizeBox")
        WinSetTitle("文件名修改")

        reNameGui.Add("Text", "xm y+10", "原文件名：")
        reNameGui.Add("Text", "xm+10 R3 W250 Center 0x80", fName.FileNameNoExt)

        ; 分类
        reNameGui.Add("Text", "xm y+10", "分 类 ：")
        reNameInput.class := reNameGui.Add("DropDownList", "xp+50 yp-2 w80 vClass Choose" . fName.classIndex, class_list)
        reNameInput.class.OnEvent("Change", nameUpdate)

        ; 二级分类
        reNameGui.Add("Text", "x+20 yp+2", "二级:")
        reNameInput.classSec := reNameGui.Add("Edit", "x+5 yp-4 w65", "")
        reNameInput.classSec.OnEvent("Change", nameUpdate)
        reNameGui.Add("Button", "x+10 yp-1 W40", "删除").OnEvent("click", fName_classSec_del)

        ; 仅文件名
        if (fName.onlyName) {
            reNameGui.Add("Text", "xm y+10", "名 称 ：")
            reNameInput.onlyName := reNameGui.Add("Edit", "xp+50 yp-2 H20 W155", fName.onlyName)
            reNameInput.onlyName.OnEvent("Change", nameUpdate)
            reNameGui.Add("Button", "x+10 yp-1 W25", "分↕").OnEvent("click", fName_classSec_get)
            reNameGui.Add("Button", "x+10 yp-1 W50", "搜索").OnEvent("click", fName_search)
        }

        ; 插件|汉化补丁|存档数据|配置文件|修改器|MOD
        reNameGui.Add("Text", "xm y+10", "附 属 ：")
        choose_plugins := "Choose1"
        if (fName.plugins) {
            switch (fName.plugins) {
                case "插件": choose_plugins := "Choose2"
                case "汉化补丁": choose_plugins := "Choose3"
                case "存档数据": choose_plugins := "Choose4"
                case "配置文件": choose_plugins := "Choose5"
                case "修改器": choose_plugins := "Choose6"
                case "MOD": choose_plugins := "Choose7"
            }
        }
        reNameInput.plugins := reNameGui.Add("DropDownList", "xp+50 yp-2 " . choose_plugins, plugins_list)
        reNameInput.plugins.OnEvent("Change", nameUpdate)

        ; 版本号
        ; if (fName.version) {
        reNameGui.Add("Text", "xm yp+30", "版 本 ：")
        if (RegExMatch(fName.version, "(^\d{1,4}$)")) {
            reNameInput.version := reNameGui.Add("Edit", "xp+50 yp-2 H20 W90", fName.version)
            reNameGui.Add("Button", "x+10 yp-1 W30", "+1").OnEvent("click", fName_versionAdd)
        } else {
            reNameInput.version := reNameGui.Add("Edit", "xp+50 yp-2 H20 W130", fName.version)
        }
        reNameInput.version.OnEvent("Change", nameUpdate)
        reNameGui.Add("Button", "x+10 yp-1 W50", "获取").OnEvent("click", fName_version_get)
        reNameGui.Add("Button", "x+10 yp W50", "恢复").OnEvent("click", fName_version_re)
        ; reNameGui.Add("Button", "xp+90 yp W60", "加1").OnEvent("click", fName_versionAdd)
        ; reNameGui.Add("Button", "xp+70 yp W60", "减1").OnEvent("click", fName_versionMinus)
        ; }

        ; 是否官方
        reNameGui.Add("Text", "xm y+10", "来 源 ：")
        choose_official := "Choose1"
        if (fName.official) {
            switch (fName.official) {
                case "官方": choose_official := "Choose2"
                case "破解": choose_official := "Choose3"
                case "修改": choose_official := "Choose4"
                case "可激活": choose_official := "Choose5"
            }
        }
        reNameInput.official := reNameGui.Add("DropDownList", "xp+50 yp-2 " . choose_official, offici_list)
        reNameInput.official.OnEvent("Change", nameUpdate)
        ; 添加两个按钮 2，3选项的快捷选择
        reNameGui.Add("Button", "x+10 yp-2 w50", offici_list[2]).OnEvent("click", fName_official_2)
        reNameGui.Add("Button", "x+10 yp w50", offici_list[3]).OnEvent("click", fName_official_3)

        ; 便携特征
        reNameGui.Add("Text", "xm y+10", "便 携 ：")
        choose_setup := "Choose1"
        if (fName.setup) {
            switch (StrLower(fName.setup)) {
                case "安装包": choose_setup := "Choose2"
                case "setup": choose_setup := "Choose2"
                case "installer": choose_setup := "Choose2"
                case "portable": choose_setup := "Choose3"
                case "便携版": choose_setup := "Choose3"
            }
        }
        reNameInput.setup := reNameGui.Add("DropDownList", "xp+50 yp-2 " . choose_setup, setup_list)
        reNameInput.setup.OnEvent("Change", nameUpdate)
        ; 添加两个按钮 2，3选项的快捷选择
        reNameGui.Add("Button", "x+10 yp-2 w50", setup_list[2]).OnEvent("click", fName_setup_2)
        reNameGui.Add("Button", "x+10 yp w50", setup_list[3]).OnEvent("click", fName_setup_3)


        ; 日期
        ; if (fName.date) {
        reNameGui.Add("Text", "xm yp+30", "日 期 ：")
        ; otime := FormatTime(StrReplace(fName.date,"-"), "yyMMdd")
        reNameInput.date := reNameGui.Add("Edit", "xp+50 yp-2 H20 W60", fName.date)
        reNameGui.Add("Button", "x+10 yp-1 w60", "修改时间").OnEvent("click", fName_modifyTime)
        reNameGui.Add("Button", "x+10 yp w50", "今天").OnEvent("click", fName_renewDate)
        reNameGui.Add("Button", "x+10 yp w50", "删除").OnEvent("click", fName_modifyTime_del)

        ; reNameGui.Add("Button", "xp+50 yp w30", "短").OnEvent("click", fName_dateShort)
        ; reNameGui.Add("Button", "xp+40 yp w30", "长").OnEvent("click", fName_dateLong)
        reNameInput.date.OnEvent("Change", nameUpdate)
        ; }

        ; 备注
        reNameGui.Add("Text", "xm y+10", "备 注 ：")
        reNameInput.remarks := reNameGui.Add("Edit", "xp+50 yp-2 H20 W220", fName.remarks)
        reNameInput.remarks.OnEvent("Change", nameUpdate)

        ; 扩展名
        reNameGui.Add("Text", "xm yp+30", "扩展名：")
        reNameInput.ext := reNameGui.Add("Edit", "xp+50 yp-2 H20 W100 vExt", fName.ext)
        reNameInput.ext.OnEvent("Change", nameUpdate)

        ; 分隔符
        ; reNameGui.Add("Text", "xm yp+30", "分隔符：")
        ; reNameInput.DelimiterChars := reNameGui.Add("Edit", "xp+50 yp H20 W80", fName.DelimiterChars)
        ; reNameGui.Add("Button", "xp+90 yp W60", "空格").OnEvent("click", fName_DelimiterCharsSpace)
        ; reNameGui.Add("Button", "xp+70 yp W60", "-").OnEvent("click", fName_DelimiterCharsHENG)
        ; reNameGui.Add("DropDownList","xp+50 yp w200 Choose1",["空格","_"])

        ; 顺序
        ; reNameGui.Add("Text", "xm yp+30", "顺序：")
        ; reNameGui.Add("Button", "xp+50 yp W60", "D N V").OnEvent("click", fName_orderDNV)
        ; reNameGui.Add("Button", "xp+70 yp W60", "N V D").OnEvent("click", fName_orderNVD)

        ; 修改后的名字
        reNameGui.Add("Text", "xm y+20", "修改后名称：")
        reNameInput.nameUpdate := reNameGui.Add("Text", "xm y+10 R3 W250 Center 0x80", fName.FileName)

        ; 更新文件夹图标
        reNameGui.Add("Button", "xm yp+50 W100", "修改图标").OnEvent("click", change_icon)

        ; 保存
        reNameGui.Add("Button", "xm yp+30 W50", "刷新").OnEvent("click", nameUpdate)
        reNameGui.Add("Button", "x+10 yp W50", "7zip(&z)").OnEvent("click", fName_7zip)
        reNameGui.Add("Button", "x+10 yp W50", "复制(&v)").OnEvent("click", fNameReName_copy)
        reNameGui.Add("Button", "x+10 yp W50", "保存(&S)").OnEvent("click", fNameReName)
        reNameGui.Add("Button", "x+10 yp W50 Default", "关闭").OnEvent("click", GuiClose)
        ; reNameGui.Add("Button", "xp+70 yp W50  Default", "保存(&S)").OnEvent("click", fNameReName)

        reNameGui.Add("Link", "xm yp+30 center", '该程序是为了存档软件,整理文档使用，<a href="https://12456789.xyz/blog/%E9%87%8D%E5%91%BD%E5%90%8D%E5%B7%A5%E5%85%B7/">发布地址及说明</a>')

        reNameGui.Show()
        Return
    }

    ; 处理顺序
    fName_orderDNV(*) {
        global reNameInput
        global reNameSet

        reNameSet.order := true
    }
    fName_orderNVD(*) {
        global reNameInput
        global reNameSet

        reNameSet.order := false
    }

    ; 处理分隔符
    fName_DelimiterCharsSpace(*) {
        global reNameInput
        global reNameSet
        reNameInput.DelimiterChars.Value := " "
        reNameSet.fName_DelimiterCharsSpace := true
    }
    fName_DelimiterCharsHENG(*) {
        global reNameInput
        global reNameSet
        reNameInput.DelimiterChars.Value := "-"
        reNameSet.fName_DelimiterCharsSpace := false
    }

    ; 搜索文件名
    fName_search(*) {
        Run "https://www.baidu.com/s?wd=" . reNameInput.onlyName.value
    }

    ; 删除二级分类
    fName_classSec_del(*) {
        reNameInput.classSec.Value := ""
        nameUpdate()
    }
    ; 从文件名中获取二级分类或将二级分类添加到文件名中
    fName_classSec_get(*) {
        arr1 := StrSplit(reNameInput.onlyName.Value, "_")

        if (reNameInput.classSec.Value == "" && arr1.Length != 1) {   ; 如果二级分类为空，且名称中可以进行分隔，将名称中的第一个分隔放到二级分类
            reNameInput.classSec.Value := arr1[1]
            reNameInput.onlyName.Value := StrReplace(reNameInput.onlyName.Value, arr1[1] . "_")
        } else if (reNameInput.classSec.Value) {   ; 如果二级有内容，把内容放到名称中
            reNameInput.onlyName.Value := reNameInput.classSec.Value . "_" . reNameInput.onlyName.Value
            reNameInput.classSec.Value := ""
        }
        nameUpdate()
    }

    ; 处理日期
    ; 将日期变短
    fName_dateShort(*) {
        global reNameInput
        global reNameSet
        reNameSet.dateShort := true
        dateText := reNameInput.date.Value
        ; put dateText
        if (StrLen(dateText) > 6) {
            dateText := StrReplace(dateText, "-")
            ; put dateText
        } else {
            return
        }
        reNameInput.date.Value := FormatTime(dateText, "M.dd")
    }
    ; 将日期变长
    fName_dateLong(*) {
        global reNameInput
        global reNameSet
        reNameSet.dateShort := false
        dateText := reNameInput.date.Value
        if (StrLen(dateText) < 6) {
            dateText := StrReplace(dateText, ".")
            if (StrLen(dateText) = 3) {
                dateText := "0" . dateText
            }
            dateText := FormatTime(, "yyyy") . dateText
        } else {
            return
        }
        reNameInput.date.Value := FormatTime(dateText, "yyyy-MM-dd")
    }

    ; 更新日期
    fName_renewDate(*) {
        global reNameInput
        global reNameSet
        dateTxt := reNameInput.date.Value
        ; if(reNameSet.dateShort){
        ; reNameInput.date.Value := FormatTime(, "M.dd")
        ; }else{
        reNameInput.date.Value := FormatTime(, "yyMMdd")
        ; }
        nameUpdate()
    }
    ; 获取文件的修改时间
    fName_modifyTime(*) {
        Timestamp := FileGetTime(fName.sel)
        ; MsgBox FormatTime(Timestamp, "yyyy-MM-dd")
        reNameInput.date.Value := FormatTime(Timestamp, "yyMMdd")
        nameUpdate()
    }
    ; 删除时间
    fName_modifyTime_del(*) {
        reNameInput.date.Value := ""
        nameUpdate()
    }

    ; 处理版本
    fName_versionAdd(*) {
        global reNameInput
        reNameInput.version.Value := reNameInput.version.Value ? reNameInput.version.Value + 1 : 1
        nameUpdate()
    }
    fName_versionMinus(*) {
        global reNameInput
        if (reNameInput.version.Value) {
            reNameInput.version.Value := reNameInput.version.Value - 1 < 1 ? 1 : reNameInput.version.Value - 1
        } else {
            reNameInput.version.Value := 1
        }
    }
    /**
     * 尝试从文件本身获取版本号  
     * 获取失败的情况下， 将版本号设为 0.1 
     */
    fName_version_get(*) {
        try {
            reNameInput.version.Value := FileGetVersion(fName.sel)
        } catch Error {
            reNameInput.version.Value := "1"
        }
        nameUpdate()
    }
    fName_version_re(*) {
        reNameInput.version.Value := fName.version
        nameUpdate()
    }

    fName_official_2(*) {
        reNameInput.official.Value := 2
        nameUpdate()
    }
    fName_official_3(*) {
        reNameInput.official.Value := 3
        nameUpdate()
    }
    fName_setup_2(*) {
        reNameInput.setup.Value := 2
        nameUpdate()
    }
    fName_setup_3(*) {
        reNameInput.setup.Value := 3
        nameUpdate()
    }

    ; 利用7zip进行压缩
    fName_7zip(*) {
        zip_path := "c:\Program Files\7-Zip\7z.exe"   ; 7zip的目录
        ; 判断是否安装了7zip
        if not FileExist(zip_path) {
            msgbox zip_path " not found. Please install 7zip first!!"
            return false
        }

        ; zip 命令
        ; -sdel 删除源文件
        ; -sfx 创建自解压文件

        newName := reNameInput.nameUpdate.Value
        zipDir := fName.parentPath . "\" . newName . ".zip"

        ; 是否输入密码
        IB := InputBox("是否输入密码.", "Phone Number", "w240 h120")
        if IB.Result = "Cancel" {
            ; cmd := zip_path . " a -sdel `"" . zipDir . "`" `"" . fName.sel "`""
            GuiClose()
        } else {
            ; 如果输入为空的情况下，则默认无密码
            if (IB.Value) {
                cmd := zip_path . " a -sdel -p" . IB.Value . " `"" . zipDir . "`" `"" . fName.sel "`""
            } else {
                cmd := zip_path . " a -sdel `"" . zipDir . "`" `"" . fName.sel "`""
            }
            RunWait cmd
        }
        ; MsgBox cmd
        ; RunWait A_ComSpec ' /c "' cmd '"',,"Hide"
        GuiClose()
    }

    ; 更新预览名字
    nameUpdate(*) {
        nameUP := {}
        nameUP.class := reNameInput.class.Text ? reNameInput.class.Text . "_" : ""
        nameUP.classSec := Trim(reNameInput.classSec.Value) ? Trim(reNameInput.classSec.Value) . "_" : ""
        nameUP.onlyName := Trim(reNameInput.onlyName.Value) ? Trim(reNameInput.onlyName.Value) . "_" : ""
        nameUP.plugins := reNameInput.plugins.Text ? reNameInput.plugins.Text . "_" : ""
        nameUP.official := reNameInput.official.Text ? reNameInput.official.Text . "_" : ""
        nameUP.setup := reNameInput.setup.Text ? reNameInput.setup.Text . "_" : ""
        nameUP.version := Trim(reNameInput.version.Value) ? "v" . Trim(reNameInput.version.Value) . "_" : ''
        nameUP.date := Trim(reNameInput.date.Value) ? "d" . Trim(reNameInput.date.Value) . "_" : ""
        nameUP.remarks := Trim(reNameInput.remarks.Value) ? "&" . Trim(reNameInput.remarks.Value) . "_" : ""
        nameUP.ext := Trim(reNameInput.ext.Value) ? "." . Trim(reNameInput.ext.Value) : ""

        ; nameUP.DelimiterChars := reNameInput.DelimiterChars.Value
        ; nameUP.order := reNameSet.order

        ; 如果是文档类型， 则顺序改变，将日期和版本号提到前面
        ; 默认： 分类_二级分类_名称_是否插件_版本_是否官方_是否便携_日期_备注_扩展名
        ; 文档： 分类_二级分类_名称_日期_版本_是否插件_是否官方_是否便携_备注_扩展名
        if (RegExMatch(nameUP.ext, "^.(doc|docx|xls|xlsx|ppt|pptx|pdf)$")) {
            newName := nameUP.class . nameUP.classSec . nameUP.onlyName . nameUP.date . nameUP.version . nameUP.plugins . nameUP.official . nameUP.setup . nameUP.remarks
        } else {
            newName := nameUP.class . nameUP.classSec . nameUP.onlyName . nameUP.plugins . nameUP.version . nameUP.official . nameUP.setup . nameUP.date . nameUP.remarks
        }
        newName := RTrim(newName, "_") . nameUP.ext
        reNameInput.nameUpdate.Value := newName
    }

    ; 复制
    fNameReName_copy(*) {
        global fName
        global reNameSet

        newName := reNameInput.nameUpdate.Value
        newNameFull := fName.parentPath . "\" . newName
        if (fName.sel == newNameFull) {
            MsgBox "已经存在相同文件名"
        } else {
            FileCopy(fName.sel, newNameFull, 0)
            GuiClose()
        }
    }

    ; 正式更名
    fNameReName(*) {
        global fName
        global reNameSet

        newName := reNameInput.nameUpdate.Value
        newNameFull := fName.parentPath . "\" . newName
        try {
            FileMove(fName.sel, newNameFull, 1)
        } catch Error {
            MsgBox("重命名失败")
        }
        GuiClose()
    }

    ; 网络路径判断
    netPath_check(path) {
        ; 获取驱动器类型
        SplitPath Path, &OutFileName, &OutDir, &OutExtension, &OutNameNoExt, &OutDrive
        DriveType := DriveGetType(OutDrive)
        ; 检查驱动器类型
        if (!driveType) {
            ; MsgBox (OutDrive . " 是一个映射的网络驱动器！")
            if (SubStr(OutDrive, 1, 2) != "\\") {
                ; MsgBox("字符串的最前面不是 \\")
                MsgBox("启动失败:`n由于是该文件在映射的网络驱动器中, 目前脚本只支持UNC路径,类似\\Workstation01, 而非 " . OutDrive . " 这种。可以从网络面板中找到该电脑上的文件进行修改。")
                Exit
            }
        }
    }

    GuiClose(*) {
        global reNameGui
        reNameGui.Destroy()
        Return
    }


    ; 添加新的功能, 将文件夹的图标更改为里面的exe图标
    change_icon(*) {
        ; 初始化结果数组
        exeFiles := []

        ; 遍历文件夹中的所有文件
        Loop Files, fName.sel "\*.exe", "F" {
            exeFiles.Push(A_LoopFileFullPath) ; 将文件的完整路径添加到数组中
        }

        ; 如果没有找到 .exe 文件
        if (exeFiles.Length = 0) {
            MsgBox "所选文件夹中没有找到 .exe 文件。"
            GuiClose()
        }

        ; 创建 GUI 窗口
        ExeListGui := Gui()
        ExeListGui.Title := "选择要查看的 .exe 文件"
        ExeListGui.SetFont("s10", "Arial")

        ; 创建 ListView 控件
        LV := ExeListGui.Add("ListView", "w600 h400", ["文件名", "路径"])
        LV.ModifyCol(1, 200) ; 设置第一列宽度
        LV.ModifyCol(2, 400) ; 设置第二列宽度

        ; 创建图像列表（设置大图标，32x32 像素）
        ImageList := IL_Create(exeFiles.Length, 1, 1) ; 参数：初始大小、是否为大图标、是否支持掩码
        LV.SetImageList(ImageList, 1) ; 1 表示使用大图标列表

        ; 添加图标和文件名到 ListView
        for index, filePath in exeFiles {
            fileName := RegExReplace(filePath, ".*\\") ; 提取文件名
            ; 加载 .exe 文件的图标（32x32 像素）
            iconIndex := IL_Add(ImageList, filePath, 1)
            ; 添加到 ListView
            LV.Add("Icon" iconIndex, fileName, filePath)
        }

        ; 绑定双击事件
        LV.OnEvent("DoubleClick", ShowFilePath)

        ; 显示 GUI
        ExeListGui.Show()

        ; 双击事件处理函数
        ShowFilePath(LV, RowNumber) {
            filePath := LV.GetText(RowNumber, 2) ; 获取第二列（路径）
            ; MsgBox "所选文件的路径为：`n" filePath

            ini := fName.sel "\desktop.ini"
            icofullpath := fName.sel "\folder.ico"

            Png2Icon(filePath, icofullpath)

            IniWrite("folder.ico", ini, ".ShellClassInfo", "IconFile")
            IniWrite(0, ini, ".ShellClassInfo", "IconIndex")
            IniWrite(0, ini, ".ShellClassInfo", "ConfirmFileOp")

            ; 设置文件夹为系统文件夹
            FileSetAttrib("+S", fName.sel)

            ; 刷新文件夹图标
            DllCall("Shell32\SHChangeNotify", "UInt", 0x08000000, "UInt", 0x0000, "Ptr", 0, "Ptr", 0)  ; SHCNF_FLUSH

            MsgBox("文件夹属性已设置并刷新图标")
            ExeListGui.Destroy()
        }
    }
}


; 修改图标用到的函数库

Png2Icon(sourcePng, destIco) {
    hBitmap := LoadPicture(sourcePng, "GDI+")
    hIcon := HIconFromHBitmap(hBitmap)
    HiconToFile(hIcon, destIco)
    DllCall("DestroyIcon", "Ptr", hIcon)
    DllCall("DeleteObject", "Ptr", hBitmap)
}

HIconFromHBitmap(hBitmap) {
    ; 分配 BITMAP 结构的内存
    BITMAP := Buffer(4 * 4 + A_PtrSize * 2, 0)
    ; 获取位图信息
    DllCall("GetObject", "Ptr", hBitmap, "Int", BITMAP.Size, "Ptr", BITMAP.Ptr)
    width := NumGet(BITMAP, 4, "UInt")
    height := NumGet(BITMAP, 8, "UInt")

    ; 获取设备上下文
    hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    ; 创建兼容位图
    hCBM := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", width, "Int", height, "Ptr")

    ; 分配 ICONINFO 结构的内存
    ICONINFO := Buffer(4 * 2 + A_PtrSize * 3, 0)
    NumPut("UInt", 1, ICONINFO, 0)  ; fIcon
    NumPut("Ptr", hCBM, ICONINFO, 4 * 2 + A_PtrSize)  ; hbmMask
    NumPut("Ptr", hBitmap, ICONINFO, 4 * 2 + A_PtrSize * 2)  ; hbmColor

    ; 创建图标
    hIcon := DllCall("CreateIconIndirect", "Ptr", ICONINFO.Ptr, "Ptr")

    ; 清理资源
    DllCall("DeleteObject", "Ptr", hCBM)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)

    return hIcon
}

HiconToFile(hIcon, destFile) {
    static szICONHEADER := 6, szICONDIRENTRY := 16, szBITMAP := 16 + A_PtrSize * 2, szBITMAPINFOHEADER := 40
        , IMAGE_BITMAP := 0, flags := (LR_COPYDELETEORG := 0x8) | (LR_CREATEDIBSECTION := 0x2000)
        , szDIBSECTION := szBITMAP + szBITMAPINFOHEADER + 8 + A_PtrSize * 3
        , copyImageParams := ["UInt", IMAGE_BITMAP, "Int", 0, "Int", 0, "UInt", flags, "Ptr"]

    ; 分配 ICONINFO 结构的内存
    ICONINFO := Buffer(8 + A_PtrSize * 3, 0)
    ; 获取图标信息
    DllCall("GetIconInfo", "Ptr", hIcon, "Ptr", ICONINFO.Ptr)

    ; 复制掩码位图
    if !(hbmMask := DllCall("CopyImage", "Ptr", NumGet(ICONINFO, 8 + A_PtrSize, "UPtr"), copyImageParams*)) {
        MsgBox("CopyImage failed. LastError: " . A_LastError)
        return
    }

    ; 复制彩色位图
    hbmColor := DllCall("CopyImage", "Ptr", NumGet(ICONINFO, 8 + A_PtrSize * 2, "UPtr"), copyImageParams*)

    ; 分配 DIBSECTION 结构的内存
    mskDIBSECTION := Buffer(szDIBSECTION, 0)
    clrDIBSECTION := Buffer(szDIBSECTION, 0)

    ; 获取位图信息
    DllCall("GetObject", "Ptr", hbmMask, "Int", szDIBSECTION, "Ptr", mskDIBSECTION.Ptr)
    DllCall("GetObject", "Ptr", hbmColor, "Int", szDIBSECTION, "Ptr", clrDIBSECTION.Ptr)

    ; 获取彩色位图的尺寸和位深度
    clrWidth := NumGet(clrDIBSECTION, 4, "UInt")
    clrHeight := NumGet(clrDIBSECTION, 8, "UInt")
    clrBmWidthBytes := NumGet(clrDIBSECTION, 12, "UInt")
    clrBmPlanes := NumGet(clrDIBSECTION, 16, "UShort")
    clrBmBitsPixel := NumGet(clrDIBSECTION, 18, "UShort")
    clrBits := NumGet(clrDIBSECTION, 16 + A_PtrSize, "UPtr")
    colorCount := clrBmBitsPixel >= 8 ? 0 : 1 << (clrBmBitsPixel * clrBmPlanes)
    clrDataSize := clrBmWidthBytes * clrHeight

    ; 获取掩码位图的尺寸
    mskHeight := NumGet(mskDIBSECTION, 8, "UInt")
    mskBmWidthBytes := NumGet(mskDIBSECTION, 12, "UInt")
    mskBits := NumGet(mskDIBSECTION, 16 + A_PtrSize, "UPtr")
    mskDataSize := mskBmWidthBytes * mskHeight

    ; 计算图标数据大小
    iconDataSize := clrDataSize + mskDataSize
    dwBytesInRes := szBITMAPINFOHEADER + iconDataSize
    dwImageOffset := szICONHEADER + szICONDIRENTRY

    ; 写入图标文件头
    ICONHEADER := Buffer(szICONHEADER, 0)
    NumPut("UShort", 1, ICONHEADER, 2)  ; 图标类型
    NumPut("UShort", 1, ICONHEADER, 4)  ; 图标数量

    ; 写入图标目录项
    ICONDIRENTRY := Buffer(szICONDIRENTRY, 0)
    NumPut("UChar", clrWidth, ICONDIRENTRY, 0)  ; 宽度
    NumPut("UChar", clrHeight, ICONDIRENTRY, 1)  ; 高度
    NumPut("UChar", colorCount, ICONDIRENTRY, 2)  ; 颜色数
    NumPut("UShort", clrBmPlanes, ICONDIRENTRY, 4)  ; 位平面数
    NumPut("UShort", clrBmBitsPixel, ICONDIRENTRY, 6)  ; 位深度
    NumPut("UInt", dwBytesInRes, ICONDIRENTRY, 8)  ; 数据大小
    NumPut("UInt", dwImageOffset, ICONDIRENTRY, 12)  ; 数据偏移

    ; 调整 BITMAPINFOHEADER 的高度
    NumPut("UInt", clrHeight * 2, clrDIBSECTION, szBITMAP + 8)
    NumPut("UInt", iconDataSize, clrDIBSECTION, szBITMAP + 20)

    ; 写入图标文件
    File := FileOpen(destFile, "w")
    File.RawWrite(ICONHEADER, szICONHEADER)
    File.RawWrite(ICONDIRENTRY, szICONDIRENTRY)
    File.RawWrite(clrDIBSECTION.Ptr + szBITMAP, szBITMAPINFOHEADER)
    File.RawWrite(clrBits, clrDataSize)
    File.RawWrite(mskBits, mskDataSize)
    File.Close()

    ; 清理资源
    DllCall("DeleteObject", "Ptr", hbmColor)
    DllCall("DeleteObject", "Ptr", hbmMask)
}