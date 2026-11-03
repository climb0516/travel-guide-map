# 🗺 攻略地图 · travel-guide-map

高德足迹式的中国点亮地图：做过旅行攻略的城市整块点亮，点进去直接看攻略；点没亮的城市填需求，生成一句指令，复制到本地 Claude Code 里用 go-travel-guide 生成，做完推送上来它就亮了。

**🌐 在线访问：[https://climb0516.github.io/travel-guide-map/](https://climb0516.github.io/travel-guide-map/)**

---

## 功能

- **点亮地图**：370 个地级行政单元（直辖市、港澳台按整体），有攻略的整块点亮并带光圈；拖动平移、滚轮 / 双指缩放、「全国」复位；缩小只显示省名和点亮城市，放大显示视野内城市名
- **悬停**：城市、所属省份、本省点亮进度（如 浙江 1/11）
- **点城市**
  - 已点亮：攻略标题、天数、出发地、更新日期、简介，「打开攻略」直达；「刷新」「改版」生成对应指令
  - 没点亮：需求表单（出发地默认杭州、三天两晚、最近的周五、自驾、偏好、备注），提交后生成指令，一键复制
- **搜城市**：支持地级市名，县城、景区也能填（生成指令时不带区划代码）
- **已点亮的攻略**列表：按更新时间排，可「在地图上看」
- 深色 / 浅色跟随系统，手机可用

## 目录

```
index.html      点亮地图（地图数据内嵌）
guides.json     已点亮城市清单，地图按 adcode 点亮
zhoushan/       舟山三日攻略（index.html + img/）
```

## 加一座城市

go-travel-guide 交付时自动完成：

1. 把攻略文件夹的 `index.html`（补 doctype / charset 文档头）和 `img/` 复制到 `<城市拼音>/`
2. 在 `guides.json` 加一行：city、adcode（地级市行政区划代码）、pinyin、title、url（`<城市拼音>/`）、days、nights、from、updated、summary、local_dir
3. 提交推送，GitHub Pages 1–2 分钟后生效

## 数据与说明

- 行政区划边界：DataV.GeoAtlas（数据来自高德开放平台），按市级行政区分块，Albers 投影，仅作示意，不作为国界、行政区划的依据；南海诸岛见左下角插图
- 攻略照片来自高德、小红书、大众点评等平台的实拍，仅供个人参考
- 地图数据由 go-travel-guide 的 `scripts/build_china.py` 生成
