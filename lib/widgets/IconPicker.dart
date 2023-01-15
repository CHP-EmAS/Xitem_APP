import 'package:xitem/controllers/ThemeController.dart';
import 'package:flutter/material.dart';

class IconPicker extends StatefulWidget {

  const IconPicker({super.key,
    required this.currentIconIndex,
    required this.onIconChanged,
  });

  final int currentIconIndex;
  final ValueChanged<int> onIconChanged;

  @override
  State<StatefulWidget> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  late int _currentIconIndex;
  List<IconData> icons = ThemeController.calendarIcons;

  @override
  void initState() {
    _currentIconIndex = widget.currentIconIndex;
    super.initState();
  }

  void changeIcon(int iconIndex) {
    setState(() => _currentIconIndex = iconIndex);
    widget.onIconChanged(iconIndex);
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      width: orientation == Orientation.portrait ? 300.0 : 300.0,
      height: orientation == Orientation.portrait ? 360.0 : 200.0,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait ? 4 : 6,
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
        children: ThemeController.calendarIcons.map((IconData icon) {
          return Container(
            margin: const EdgeInsets.all(5.0),
            child: Material(
              borderRadius: BorderRadius.circular(50.0),
              color: _currentIconIndex == icons.indexOf(icon) ? Colors.amber : Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50.0),
                onTap: () {
                  changeIcon(icons.indexOf(icon));
                },
                child: Icon(
                  icon,
                  color: ThemeController.activeTheme().iconColor,
                  size: 40,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
