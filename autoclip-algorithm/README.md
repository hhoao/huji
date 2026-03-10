# 乒乓球自动视频剪辑
## 功能
* 传入视频文件，自动检测并剪辑视频中出现的乒乓球比赛，将捡球过程全部移除，只保留比赛过程。


## 如何开发
### 运行 setup.sh 脚本
```bash
./setup.sh
```

### 需要 kafka 环境
运行docker compose开发脚本
```
cd docker/dev
docker compose up -d
```

可以尝试运行测试脚本了，测试脚本在src/test/service目录下
