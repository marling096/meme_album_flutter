import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:get/get.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
        child: Column(
          children: [
            SettingItemContainer(child: SettingDropdown(title: 'Theme')),
            SettingItemContainer(child: SettingTextField(title: 'Username')),
            SettingItemContainer(child: SettingChild(title: 'Sync Settings')),
          ],
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
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
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
        Expanded(
          flex: 1,
          child: Text(widget.title, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          flex: 1,
          child: SizedBox(
            width: 140, // 固定宽度，确保每个 dropdown 的锚点一致
            child: Builder(
              builder: (context) {
                final textColor =
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.black;
                return Theme(
                  data: Theme.of(context).copyWith(
                    // canvasColor: Colors.transparent,
                    // cardColor: Colors.transparent,
                  ),
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
                              if (val == 'Light')
                                Get.changeThemeMode(ThemeMode.light);
                              else if (val == 'Dark')
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
            onPressed: () {
              print('clicked');
            },
          ),
        ),
      ],
    );
  }
}
