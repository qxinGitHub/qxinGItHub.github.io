---
title: "Obsidian Web Clipper 剪辑知乎专栏"
date: 2025-01-16 16:11:22 +0800
categories:
- blog
tags: 
- obsidian
---

# 一、概述
Obsidian官方的剪辑插件 [Obsidian Web Clipper](https://obsidian.md/clipper)无法剪辑知乎专栏, 但是并没有搜到相关内容, 经过查阅[官方文档](https://help.obsidian.md/web-clipper) , 发现插件的自由度极高, 稍作修改,即可剪辑专栏内容。  

# 二、修改方法
方法极为简单: 先新建模板, 将插件中的笔记内容`'{{'content'}}'`更改为```'{{'selectorHtml:.Post-RichText|markdown'}}'```   

**自动调用模板的实现:**  
将`模板触发器`的规则加入 `https://zhuanlan.zhihu.com/`,可实现在知乎专栏页面自动调用该模板。

**效果展示**    
![文件管理器演示](/assets/blog/20250116/2025-01-16_16-31-01.png)    

# 三、成品
**代码使用方法**  
可以在`编辑模板`界面,选择`导入`,将下方的json代码复制进去即可, 属性可以根据自己需要自行删减,如果想将专栏的tags也剪辑到Ob中, 可以自己继续添加属性,属性名称`tags`,属性值`'{{'selector:.Tag-content'}}'`  
{% raw %}
```json
{
	"schemaVersion": "0.1.0",
	"name": "知乎专栏",
	"behavior": "create",
	"noteContentFormat": "{{selectorHtml:.Post-RichText|markdown}}",
	"properties": [
		{
			"name": "标题",
			"value": "{{title}}",
			"type": "text"
		},
		{
			"name": "作者",
			"value": "{{selector:.AuthorInfo-content}}",
			"type": "text"
		},
		{
			"name": "发布时间",
			"value": "{{selector:.Post-Header .ContentItem-time|slice:4}}",
			"type": "text"
		},
		{
			"name": "原文链接",
			"value": "{{url}}",
			"type": "text"
		},
		{
			"name": "created",
			"value": "{{date|date:\\\"YYYY-MM-DD HH:mm:ss\\\"}}",
			"type": "date"
		}
	],
	"triggers": [
		"https://zhuanlan.zhihu.com/"
	],
	"noteNameFormat": "{{title}}",
	"path": "Clippings"
}
```
{% endraw %}


