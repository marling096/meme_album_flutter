# Meme Album

Meme Album 是一个基于 Flutter 的本地相册/表情包管理演示应用，包含本地文件访问、数据库存储、文本分词字典（jieba）等功能。

## 主要特性

- 基于 `Get` 和 `GetIt` 的依赖注入与路由管理
- 使用 `sqflite` / `sqlite3` 做本地图片信息持久化
- 支持文件选择（`file_picker`）与运行时权限请求
- 集成中文分词字典（放在 `assets/jieba_dict/`）用于文本处理

## 目录/关键文件

- `lib/main.dart`：应用入口，初始化权限与依赖。[lib/main.dart](lib/main.dart)
- `pubspec.yaml`：依赖与资源配置（包括 `.env` 与字典资源）。[pubspec.yaml](pubspec.yaml)
- `assets/jieba_dict/`：jieba 分词所需词典文件与停用词。

## 运行前准备

1. 安装 Flutter SDK（本项目使用 Dart SDK 约束 `^3.9.2`，请确保 Flutter 版本兼容）。
2. 配置 Android / iOS / Windows 开发环境，确保能使用 `flutter run`。
3. 在项目根目录创建或检查 `.env`（项目在 `pubspec.yaml` 已声明为 asset），如有需要填写运行所需的环境变量。

## 快速开始

克隆项目后，在项目根目录运行：

```bash
flutter pub get
```

运行 Android（连设备或模拟器）：

```bash
flutter run -d android
```

运行 Windows：

```bash
flutter run -d windows
```

运行测试：

```bash
flutter test
```

生成 MobX 相关代码（如有修改 store）：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 重要依赖（摘选）

- `get`：状态管理与路由
- `get_it`：依赖注入
- `mobx` / `flutter_mobx`：响应式状态管理
- `sqflite` / `sqlite3` / `sqlite3_flutter_libs`：本地数据库
- `file_picker`：选择文件（图片）
- `permission_handler`：运行时权限

完整依赖请见 `pubspec.yaml`。[pubspec.yaml](pubspec.yaml)

## 资源说明

- 词典与停用词位于 `assets/jieba_dict/`，包括：
	- `jieba.dict.utf8`
	- `hmm_model.utf8`
	- `idf.utf8`
	- `stop_words.utf8`
	- `user.dict.utf8`

确保这些文件存在并随应用一起打包（`pubspec.yaml` 已列出）。

## 开发与调试提示

- 启动时应用会调用 `requestStoragePermissionOnStartup()` 请求存储权限，调试时请确保允许权限。
- 依赖注入在 `AppInitializer` 中注册，查看 `lib/app/initializer/appInitializer.dart` 以了解服务注册步骤。
- 若修改了 model/store，记得运行 `build_runner` 以生成代码。

## 贡献与提交

欢迎提交 issue 或 PR。提交前请确保：


## 许可
本仓库采用 MIT 许可证，详见 [LICENSE](LICENSE)。





