## 修改启动封面

flutter_native_splash

```bash
dart run flutter_native_splash:create
```

## 构建

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## 改名

flutter_rename

```bash
dart pub global run rename setAppName -t ios,android,macos,linux,windows --value "弧迹"
dart pub global run rename setBundleId -t ios,android,macos,linux,windows --value "com.hhoa.restcut"
```

## 修改应用图标

flutter_launcher_icons

```bash
flutter pub run flutter_launcher_icons:main
```
