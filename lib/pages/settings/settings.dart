import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:event_bus/event_bus.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.eventBus});

  final EventBus? eventBus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('Settings'),
              backgroundColor: Colors.transparent, // 半透明叠加
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 54, left: 12, right: 12),
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView(
            children: [
              SettingItemContainer(child: SettingDropdown(title: 'Theme Mode')),
              SettingItemContainer(
                child: SettingSwitch(
                  title: 'Enable Notifications',
                  rxValue: false.obs,
                  eventBus: eventBus,
                ),
              ),
              SettingItemContainer(child: SettingTextField(title: 'Username')),
              SettingItemContainer(
                child: SettingChild(title: 'Advanced Settings'),
              ),
              SettingItemContainer(
                child: SettingFilePicker(
                  title: 'Select Album Folders',
                  eventBus: eventBus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingItemContainer extends StatelessWidget {
  final Widget child;
  const SettingItemContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 50,    // 移除固定高度，改为最小高度，允许内部动态扩展
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      // 保证至少有一定高度以保持外观一致
      constraints: const BoxConstraints(minHeight: 50),
      child: child,
    );
  }
}

class SettingDropdown extends StatefulWidget {
  final String title;
  const SettingDropdown({super.key, required this.title});

  @override
  State<SettingDropdown> createState() => _SettingDropdownState();
}

class _SettingDropdownState extends State<SettingDropdown> {
  String dropdownValue = 'Light';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 标题：使用 Expanded 并限制为一行，超出显示省略号，避免撑破布局
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 右侧下拉使用固定宽度，不再放进 Expanded，避免在窄屏时的宽度冲突
        SizedBox(
          width: 140, // 固定宽度，确保每个 dropdown 的锚点一致
          child: Builder(
            builder: (context) {
              final textColor =
                  Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
              return Theme(
                data: Theme.of(context).copyWith(),
                child: Material(
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Builder(
                      builder: (ctx) {
                        final bg = Theme.of(ctx).colorScheme.surface;
                        return GFDropdown(
                          value: dropdownValue,
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(6),
                          dropdownColor: bg.withOpacity(0.98),
                          dropdownButtonColor: Colors.transparent,
                          elevation: 0,
                          onTap: () {},
                          onChanged: (newValue) {
                            final val = newValue.toString();
                            setState(() => dropdownValue = val);
                            if (val == 'Light') {
                              Get.changeThemeMode(ThemeMode.light);
                            } else if (val == 'Dark')
                              Get.changeThemeMode(ThemeMode.dark);
                            else
                              Get.changeThemeMode(ThemeMode.system);
                          },
                          items: const ['Light', 'Dark', 'System']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SettingTextField extends StatelessWidget {
  final String title;
  const SettingTextField({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(title, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          flex: 1,
          child: TextField(
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingSwitch extends StatelessWidget {
  final String title;
  final RxBool rxValue;
  final void Function(bool)? onChanged;
  final EventBus? eventBus;

  const SettingSwitch({
    super.key,
    required this.title,
    required this.rxValue,
    this.onChanged,
    this.eventBus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 标题：可收缩、单行、超出显示省略号
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Switch 放入受限容器，使用 FittedBox 防止在窄宽度下溢出
        Obx(
          () => SizedBox(
            // 最小宽度保证触控可点击，最大宽度避免占满剩余空间
            width: 72,
            height: 36,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: rxValue.value,
                onChanged: (value) {
                  rxValue.value = value;
                  eventBus?.fire('SettingSwitch:$title:$value');
                  if (onChanged != null) onChanged!(value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingFilePicker extends StatelessWidget {
  final String title;
  SettingFilePicker({super.key, required this.title, this.eventBus});
  final EventBus? eventBus;
  // remove selectedPath (no single selection anymore)
  final RxList<String> selectedPaths = <String>[].obs;

  // 可配置的最大可见行数
  final int maxLines = 4;
  // 每行高度（估算，用于计算容器最大高度）
  static const double _itemHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            // 按钮：打开目录选择器（保持原有行为，但不设置 selectedPath）
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () async {
                String? selectedDirectory = await FilePicker.platform
                    .getDirectoryPath();

                if (selectedDirectory != null) {
                  eventBus?.fire('AlbumFolderPicker;$selectedDirectory');
                  // 防止重复添加相同路径
                  if (!selectedPaths.contains(selectedDirectory)) {
                    selectedPaths.add(selectedDirectory);
                  }
                }
              },
            ),
            // 按钮：一键清空已选目录
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all',
              onPressed: () {
                if (selectedPaths.isNotEmpty) {
                  selectedPaths.clear();
                  eventBus?.fire('AlbumFolderCleared');
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 多行列表区域（动态高度，最多显示 maxLines 行，超过可滚动）
        Obx(() {
          if (selectedPaths.isEmpty) {
            return Text(
              '未选择目录',
              style: TextStyle(color: Theme.of(context).hintColor),
            );
          }

          final visibleCount = selectedPaths.length < maxLines
              ? selectedPaths.length
              : maxLines;
          final containerHeight = visibleCount * _itemHeight;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: containerHeight),
            child: Material(
              color: Colors.transparent,
              child: ListView.separated(
                // 关键修改：去掉内边距、不作为 primary 滚动视图、根据条目数控制是否可滚动
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                physics: selectedPaths.length > maxLines
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: selectedPaths.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final p = selectedPaths[index];
                  return SizedBox(
                    height: _itemHeight,
                    child: ListTile(
                      dense: true,
                      title: Text(
                        p,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.folder, size: 20),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: 'Delete',
                        onPressed: () {
                          selectedPaths.removeAt(index);
                          eventBus?.fire('AlbumFolderRemoved;$p');
                        },
                      ),
                      // 新增：点击行调用目录选择器，选择后替换该条目并触发更新事件
                      onTap: () async {
                        String? newDir = await FilePicker.platform
                            .getDirectoryPath();
                        if (newDir != null) {
                          final old = p;
                          final existingIndex = selectedPaths.indexOf(newDir);
                          if (existingIndex != -1 && existingIndex != index) {
                            // 若新目录在列表中已有，先移除已存在项，避免重复；
                            // 移除后若其索引在当前索引之前，需要调整目标索引
                            selectedPaths.removeAt(existingIndex);
                            final targetIndex = existingIndex < index
                                ? index - 1
                                : index;
                            selectedPaths[targetIndex] = newDir;
                          } else {
                            // 直接替换当前索引
                            selectedPaths[index] = newDir;
                          }
                          eventBus?.fire('AlbumFolderUpdated;$old;$newDir');
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SettingChild extends StatelessWidget {
  final String title;
  const SettingChild({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          flex: 12,
          child: Text(title, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          flex: 1,
          child: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () async {
              String? selectedDirectory = await FilePicker.platform
                  .getDirectoryPath();

              if (selectedDirectory == null) {
                // User canceled the picker
              } else {
                // Use the selected directory path
                print('Selected directory: $selectedDirectory');
              }
            },
          ),
        ),
      ],
    );
  }
}
