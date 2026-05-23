# 弧迹 (Huji)

<p align="center">
  <img src="assets/logo.png" alt="弧迹" width="200"/>
</p>

<p align="center">
  <strong>智能视频剪辑：自动识别乒乓球、羽毛球比赛并剪辑精彩片段</strong>
</p>

<p align="center">
  <a href="#概述">概述</a> •
  <a href="#主要功能">主要功能</a> •
  <a href="#项目结构">项目结构</a> •
  <a href="#快速开始">快速开始</a> •
  <a href="#license">License</a>
</p>

[![LICENSE](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

## 概述

<p align="center">
  <img src="assets/cover.png" alt="弧迹"/>
</p>

弧迹是一个智能视频剪辑 Android 应用，它用于自动检测乒乓球、羽毛球比赛中的精彩回合，去除捡球等冗余片段，输出精简的比赛集锦。。

## 主要功能

- [x] **比赛视频剪辑**：已有视频剪辑 / 边拍边剪辑
- [x] **自动剪辑配置与执行**：云端或本地检测、上传、流式剪辑进度
- [x] **边拍边剪辑**：录制同时实时检测回合并生成剪辑
- [x] **回合剪辑编辑**：多片段预览、拖拽排序、增删改回合、导出清晰度与保存
- [x] **回合选择弹窗**：从检测结果中勾选要保留的回合
- [x] **剪辑后编辑**：对生成视频片段做基础编辑（简单的剪映功能）
- [x] **视频列表**：Feed/列表切换、筛选、入口到个人与设置
- [x] **任务与记录**：本地剪辑任务 Tab、视频记录 Tab、任务进度弹窗、跳转回合编辑
- [x] **视频剪辑进度**：单任务进度展示与覆盖层
- [x] **视频记录详情**：单条记录详情

### 已经支持的视频类型

- [x] **乒乓球比赛视频**
- [x] **羽毛球比赛视频**

### 剪辑速度

PC(4050):

- 算法侧：16分钟视频剪辑耗时：69.53s

Android(未统计):

## 项目结构

| 子项目 | 技术栈 | 说明 |
| ----- | ------ | ---- |
| `huji-app` | Flutter | 弧迹客户端，提供视频选择、智能剪辑、片段编辑、任务管理等功能 |
| `huji-algorithm` | Python | 算法服务（Git 子模块），负责乒乓球/羽毛球比赛检测与自动剪辑 |

`huji-algorithm` 以 Git 子模块方式引入，仓库地址：[hhoao/huji-algorithm](https://github.com/hhoao/huji-algorithm)。

## 快速开始

### 克隆仓库

首次克隆需同时拉取子模块：

```bash
git clone --recurse-submodules https://github.com/hhoao/huji.git
```

若已克隆主仓库，可初始化子模块：

```bash
git submodule update --init --recursive
```

### 桌面 Linux 依赖

```bash
sudo apt-get install -y libasound2-dev libmpv-dev mpv
```

### huji-app（客户端）

```bash
cd huji-app
flutter pub get
flutter run
```

### huji-algorithm（算法服务）

```bash
cd huji-algorithm
./setup.sh
cd docker/dev && docker compose up -d   # 消息模式需要 Kafka
python main.py                          # 默认读取 src/resources/application.yml
```

## License

[Apache License 2.0](LICENSE)
