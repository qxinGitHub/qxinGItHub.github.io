#Requires AutoHotkey v2.0
; #Include <fun_toStr>

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
F9:: Filerename()
Filerename(){
    global fName
    ; 临时存储剪贴板
    Candy_Saved_ClipBoard := ClipboardAll()
    A_Clipboard := ""
    send "^c"
    Errorlevel := !ClipWait(0.5)
    ; 在 edge 浏览器中 会出现 ctrl 没有释放的情况
    Send("{Ctrl Up}")
    ;如果选择为空，则退出
    If (ErrorLevel){
        ;还原粘贴板
        A_Clipboard := Candy_Saved_ClipBoard
        Candy_Saved_ClipBoard := ""
        Return
    }

    ; 分类
    ; 分类前缀，可以没有
    class_list_1 := ["","01"  ,"02"  ,"03" ,"04"  ,"05"  ,"06" ,"07"  ,"08"  ,"09"]
    ; 分类后缀，实际以此为准, 修改此处就可以修改分类
    class_list_2 := ["","装机","办公","图片","视频","系统","工具","整理","硬件","其他","NAS","Adobe"]
    class_list_1_length := class_list_1.Length
    class_list := []
    for index,value in class_list_2{
        if(index<=class_list_1_length){
            class_list.Push(class_list_1[index] . value)
        }else{
            class_list.Push(value)
        }
    }
    ; class_list := ["01核心","02日用","03办公","04图片","05视频","06文件","07工具","08硬件","09其他",""]
    
    ; 下面三行仅代表下拉菜单的内容， 如果修改，还有两处需要修改，第二处是匹配文件名的地方， 第三处是根据匹配到的文件名选择下拉菜单的地方
    offici_list := ["","官方","破解","修改","可激活"]
    setup_list := ["","安装包","便携版"]
    plugins_list := ["","插件","汉化补丁","存档数据","配置文件","修改器","MOD"]

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
    fName.folder:= false

    ; 判断是否是文件夹
    if DirExist(fName.sel){
        ; MsgBox "The target folder does exist."
        ; fName.FileNameNoExt .= "." . fName.ext
        fName.FileNameNoExt := fName.FileName
        fName.ext := ""
        fName.folder:= true
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
                for class_index,class_value in class_list{
                    if(v == class_value){
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
                    oDate := StrReplace(fDate[1],".")
                    oDate := StrReplace(oDate,"-")
                    fName.date := FormatTime(oDate, "yyMMdd")
                    arr1.Delete(index)
                }else if (RegExMatch(v, "(^\d{1,2}[-\.]\d{2})", &fDate)) {  ; 月日： 03-17
                    reNameSet.dateShort := true
                    fName.date := fDate[1]
                    arr1.Delete(index)
                }else if(RegExMatch(v, "^d(\d{6})", &fDate)){ ;  短日期： 220317
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
                }else if (RegExMatch(v, "(^\d{1,2}[-\.]\d{2})", &fDate)) {
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
        if (RegExMatch(fName.FileNameNoExt, "^\d{4}[-\.]\d{2}[-\.]\d{2}") || RegExMatch(fName.FileNameNoExt, "^\d{1,2}[-\.]\d{2}")  ) {
            reNameSet.order := true
        }else{
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
        reNameInput.class.OnEvent("Change",nameUpdate)

        ; 二级分类
        reNameGui.Add("Text", "x+20 yp+2", "二级:")
        reNameInput.classSec := reNameGui.Add("Edit", "x+5 yp-4 w65", "")
        reNameInput.classSec.OnEvent("Change",nameUpdate)
        reNameGui.Add("Button", "x+10 yp-1 W40", "删除").OnEvent("click", fName_classSec_del)

        ; 仅文件名
        if (fName.onlyName) {
            reNameGui.Add("Text", "xm y+10", "名 称 ：")
            reNameInput.onlyName := reNameGui.Add("Edit", "xp+50 yp-2 H20 W155", fName.onlyName)
            reNameInput.onlyName.OnEvent("Change",nameUpdate)
            reNameGui.Add("Button", "x+10 yp-1 W25", "分↕").OnEvent("click", fName_classSec_get)
            reNameGui.Add("Button", "x+10 yp-1 W50", "搜索").OnEvent("click", fName_search)
        }

        ; 插件|汉化补丁|存档数据|配置文件|修改器|MOD
        reNameGui.Add("Text", "xm y+10", "附 属 ：")
        choose_plugins := "Choose1"
        if(fName.plugins){
            switch(fName.plugins){
                case "插件":choose_plugins := "Choose2"
                case "汉化补丁":choose_plugins := "Choose3"
                case "存档数据":choose_plugins := "Choose4"
                case "配置文件":choose_plugins := "Choose5"
                case "修改器":choose_plugins := "Choose6"
                case "MOD":choose_plugins := "Choose7"
            }
        }
        reNameInput.plugins := reNameGui.Add("DropDownList", "xp+50 yp-2 " . choose_plugins, plugins_list)
        reNameInput.plugins.OnEvent("Change",nameUpdate)

        ; 版本号
        ; if (fName.version) {
            reNameGui.Add("Text", "xm yp+30", "版 本 ：")
            if(RegExMatch(fName.version, "(^\d{1,4}$)")){
                reNameInput.version := reNameGui.Add("Edit", "xp+50 yp-2 H20 W90", fName.version)
                reNameGui.Add("Button", "x+10 yp-1 W30", "+1").OnEvent("click", fName_versionAdd)
            }else{
                reNameInput.version := reNameGui.Add("Edit", "xp+50 yp-2 H20 W130", fName.version)
            }
            reNameInput.version.OnEvent("Change",nameUpdate)
            reNameGui.Add("Button", "x+10 yp-1 W50", "获取").OnEvent("click", fName_version_get)
            reNameGui.Add("Button", "x+10 yp W50", "恢复").OnEvent("click", fName_version_re)
            ; reNameGui.Add("Button", "xp+90 yp W60", "加1").OnEvent("click", fName_versionAdd)
            ; reNameGui.Add("Button", "xp+70 yp W60", "减1").OnEvent("click", fName_versionMinus)
        ; }

        ; 是否官方
        reNameGui.Add("Text", "xm y+10", "来 源 ：")
        choose_official := "Choose1"
        if(fName.official){
            switch(fName.official){
                case "官方":choose_official := "Choose2"
                case "破解":choose_official := "Choose3"
                case "修改":choose_official := "Choose4"
                case "可激活":choose_official := "Choose5"
            }
        }
        reNameInput.official := reNameGui.Add("DropDownList", "xp+50 yp-2 " . choose_official, offici_list)
        reNameInput.official.OnEvent("Change",nameUpdate)
        ; 添加两个按钮 2，3选项的快捷选择
        reNameGui.Add("Button", "x+10 yp-2 w50", offici_list[2]).OnEvent("click", fName_official_2)
        reNameGui.Add("Button", "x+10 yp w50", offici_list[3]).OnEvent("click", fName_official_3)

        ; 便携特征
        reNameGui.Add("Text", "xm y+10", "便 携 ：")
        choose_setup := "Choose1"
        if(fName.setup){
            switch(StrLower(fName.setup)){
                case "安装包":choose_setup := "Choose2"
                case "setup":choose_setup := "Choose2"
                case "installer":choose_setup := "Choose2"
                case "portable":choose_setup := "Choose3"
                case "便携版":choose_setup := "Choose3"
            }
        }
        reNameInput.setup := reNameGui.Add("DropDownList", "xp+50 yp-2 " . choose_setup, setup_list)
        reNameInput.setup.OnEvent("Change",nameUpdate)
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
            reNameInput.date.OnEvent("Change",nameUpdate)
        ; }

        ; 备注
        reNameGui.Add("Text", "xm y+10", "备 注 ：")
        reNameInput.remarks := reNameGui.Add("Edit", "xp+50 yp-2 H20 W220", fName.remarks)
        reNameInput.remarks.OnEvent("Change",nameUpdate)

        ; 扩展名
        reNameGui.Add("Text", "xm yp+30", "扩展名：")
        reNameInput.ext := reNameGui.Add("Edit", "xp+50 yp-2 H20 W100 vExt", fName.ext)
        reNameInput.ext.OnEvent("Change",nameUpdate)

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

        ; 保存
        reNameGui.Add("Button", "xm yp+50 W50", "刷新").OnEvent("click", nameUpdate)
        reNameGui.Add("Button", "x+10 yp W50", "7zip(&z)").OnEvent("click", fName_7zip)
        reNameGui.Add("Button", "x+10 yp W50", "复制(&v)").OnEvent("click", fNameReName_copy)
        reNameGui.Add("Button", "x+10 yp W50", "保存(&S)").OnEvent("click", fNameReName)
        reNameGui.Add("Button", "x+10 yp W50 Default", "关闭").OnEvent("click", GuiClose)
        ; reNameGui.Add("Button", "xp+70 yp W50  Default", "保存(&S)").OnEvent("click", fNameReName)

        reNameGui.Add("Link","xm yp+30 center", '该程序是为了存档软件,整理文档使用，<a href="https://www.autohotkey.com">发布地址及说明</a>')

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
    fName_search(*){
        Run "https://www.baidu.com/s?wd=" . reNameInput.onlyName.value
    }

    ; 删除二级分类
    fName_classSec_del(*){
        reNameInput.classSec.Value := ""
        nameUpdate()
    }
    ; 从文件名中获取二级分类或将二级分类添加到文件名中
    fName_classSec_get(*){
        arr1 := StrSplit(reNameInput.onlyName.Value, "_")

        if(reNameInput.classSec.Value == "" && arr1.Length != 1){   ; 如果二级分类为空，且名称中可以进行分隔，将名称中的第一个分隔放到二级分类
            reNameInput.classSec.Value := arr1[1]
            reNameInput.onlyName.Value := StrReplace(reNameInput.onlyName.Value,arr1[1] . "_")
        }else if(reNameInput.classSec.Value){   ; 如果二级有内容，把内容放到名称中
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
        if(StrLen(dateText)>6){
            dateText := StrReplace(dateText,"-")
            ; put dateText
        }else{
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
        if(StrLen(dateText)<6){
            dateText := StrReplace(dateText,".")
            if(StrLen(dateText)=3){
                dateText := "0" . dateText
            }
            dateText := FormatTime(, "yyyy") . dateText
        }else{
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
    fName_modifyTime(*){
        Timestamp := FileGetTime(fName.sel)
        ; MsgBox FormatTime(Timestamp, "yyyy-MM-dd")
        reNameInput.date.Value := FormatTime(Timestamp, "yyMMdd")
        nameUpdate()
    }
    ; 删除时间
    fName_modifyTime_del(*){
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
        if(reNameInput.version.Value){
            reNameInput.version.Value := reNameInput.version.Value - 1 < 1 ? 1 : reNameInput.version.Value - 1
        }else{
            reNameInput.version.Value := 1
        }
    }
    /**
     * 尝试从文件本身获取版本号  
     * 获取失败的情况下， 将版本号设为 0.1 
     */
    fName_version_get(*){
        try {
            reNameInput.version.Value := FileGetVersion(fName.sel)
        } catch Error {
            reNameInput.version.Value := "1"
        }
        nameUpdate()
    }
    fName_version_re(*){
        reNameInput.version.Value :=fName.version
        nameUpdate()
    }

    fName_official_2(*){
        reNameInput.official.Value := 2
        nameUpdate()
    }
    fName_official_3(*){
        reNameInput.official.Value := 3
        nameUpdate()
    }
    fName_setup_2(*){
        reNameInput.setup.Value := 2
        nameUpdate()
    }
    fName_setup_3(*){
        reNameInput.setup.Value := 3
        nameUpdate()
    }

    ; 利用7zip进行压缩
    fName_7zip(*){
        zip_path := "c:\Program Files\7-Zip\7z.exe"   ; 7zip的目录
        ; 判断是否安装了7zip
        if not FileExist(zip_path){
            msgbox zip_path " not found. Please install 7zip first!!"
            return false
        }

        newName := reNameInput.nameUpdate.Value
        zipDir := fName.parentPath . "\" . newName . ".exe"

        ; 是否输入密码
        IB := InputBox("是否输入密码.", "Phone Number", "w240 h120")
        if IB.Result = "Cancel"{
            cmd := zip_path . " a -sfx `"" . zipDir . "`" `"" . fName.sel "`""
        }else{
            ; 如果输入为空的情况下，则默认无密码
            if(IB.Value){
                cmd := zip_path . " a -sfx -p" . IB.Value . " `"" . zipDir . "`" `"" . fName.sel "`""
            }else{
                cmd := zip_path . " a -sfx `"" . zipDir . "`" `"" . fName.sel "`""
            }
        }
        ; MsgBox cmd
        ; RunWait A_ComSpec ' /c "' cmd '"',,"Hide"
        RunWait cmd
        GuiClose()
    }

    ; 更新预览名字
    nameUpdate(*){
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
        }else{
            newName := nameUP.class . nameUP.classSec . nameUP.onlyName . nameUP.plugins . nameUP.version . nameUP.official . nameUP.setup . nameUP.date . nameUP.remarks
        }
        newName := RTrim(newName , "_") . nameUP.ext        
        reNameInput.nameUpdate.Value := newName
    }

    ; 复制
    fNameReName_copy(*) {
        global fName
        global reNameSet
        global reNameSet

        newName := reNameInput.nameUpdate.Value
        newNameFull := fName.parentPath . "\" . newName
        if(fName.sel == newNameFull){
            MsgBox "已经存在相同文件名"
        }else{
            FileCopy(fName.sel, newNameFull, 0)
            GuiClose()
        }
    }

    ; 正式更名
    fNameReName(*) {
        global fName
        global reNameSet
        global reNameSet

        newName := reNameInput.nameUpdate.Value
        newNameFull := fName.parentPath . "\" . newName
        FileMove(fName.sel, newNameFull, 0)
        GuiClose()
    }

    GuiClose(*) {
        global reNameGui
        reNameGui.Destroy()
        Return
    }
}

tray := A_TrayMenu
tray.add
tray.add "这是用来给程序存档使用", (*) => showGithub()
tray.add "发布地址", (*) => showGithub()
showGithub(*){
    Run "www.baidu.com"
}
toStr(obj,DelimiterChars := ','){
    if isObj(obj){
        return obj2str(obj)
    } else if isArr(obj){
        return arr2str(obj,DelimiterChars)
    } else{
        return String(obj)
    }
}
arr2str(arr,DelimiterChars := ' '){
    str := ''
    for index,v in arr{
        str2 := ''
        if(isArr(v)){
            str2 .= '[' . arr2str(v,DelimiterChars) . ']' . DelimiterChars
        }else if(isObj(v)){
            str2 .= '`n{`n' . obj2str(v) . '`n}' . DelimiterChars
        }else{
            str2 := v . DelimiterChars
        }
        str .= str2
    }
    return RTrim(str , DelimiterChars)
}
obj2str(obj){
    str := ''
    for k1, v1 in obj.OwnProps(){
        if(isObj(v1)){
            str .= k1 . " : `n{`n" . obj2str(v1) . "`n}`n"
        }else if(isArr(v1)){
            str .= k1 . " : [" . arr2str(v1,',') . "]`n"
        }else{
            str .="`s`s" . k1 . ' : ' . v1 . '`n'
        }
    }
    return RTrim(str,'`n')
}
typeObj(obj){
    if IsObject(obj){
        if (HasProp(obj,'length') && !ObjOwnPropCount(obj)){
            MsgBox 'arr'
        } else {
            MsgBox 'obj'
        }
    } else {
        return Type(obj)
    }
}
isObj(obj){
    if IsObject(obj){
        if (HasProp(obj,'length') && !ObjOwnPropCount(obj)){
            return false
        } else {
            return true
        }
    } else {
        return false
    }
}
isArr(obj){
    if IsObject(obj){
        if (HasProp(obj,'length') && !ObjOwnPropCount(obj)){
            return true
        } else {
            return false
        }
    } else {
        return false
    }
}
