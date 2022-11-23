import 'package:de/Controllers/ThemeController.dart';
import 'package:flutter/material.dart';

const List<IconData> default_icons = [
  Icons.calendar_today,
  Icons.event,
  Icons.event_available,
  Icons.event_note,
  Icons.date_range,
  Icons.assignment_late,
  Icons.cake,
  Icons.favorite,
  Icons.favorite_border,
  Icons.star,
  Icons.star_border,
  Icons.all_inclusive,
  Icons.extension,
  Icons.cloud,
  Icons.filter_drama,
  Icons.filter_hdr,
  Icons.filter_vintage,
  Icons.whatshot,
  Icons.home,
  Icons.group,
  Icons.people_outline,
  Icons.directions_bike,
  Icons.directions_bus,
  Icons.directions_car,
  Icons.directions_railway,
  Icons.directions_boat,
  Icons.local_airport,
  Icons.hotel,
  Icons.ac_unit,
  Icons.brightness_2,
  Icons.wb_sunny,
  Icons.work,
  Icons.school,
  Icons.schedule,
  Icons.audiotrack,
  Icons.beach_access,
  Icons.fitness_center,
  Icons.pool,
  Icons.pets,
  Icons.alarm,
  Icons.android,
  Icons.build,
  Icons.camera,
  Icons.apps,
  Icons.blur_on,
  Icons.bubble_chart,
  Icons.dashboard,
  Icons.layers,
  Icons.equalizer,
  Icons.timeline,
  Icons.account_balance,
  Icons.euro_symbol,
  Icons.attach_money,
  Icons.check,
  Icons.done_outline,
  Icons.block,
  Icons.clear,
  Icons.lock,
  Icons.delete,
  Icons.priority_high,
  Icons.mood,
  Icons.create,
  Icons.call,
  Icons.email,
  Icons.business,
  Icons.language,
  Icons.attach_file,
  Icons.business_center,
  Icons.build,
  Icons.translate,
  Icons.child_friendly,
  Icons.flag,
  Icons.location_on,
  Icons.public,
  Icons.fingerprint,
  Icons.restaurant,
  Icons.fastfood,
  Icons.format_paint,
  Icons.color_lens,
  Icons.free_breakfast,
  Icons.explore,
  Icons.computer,
  Icons.power_settings_new,
  Icons.memory,
  Icons.headset,
  Icons.http,
  Icons.gamepad,
  Icons.videogame_asset,
  Icons.golf_course,
  Icons.local_movies,
  Icons.event_seat,
];

typedef PickerLayoutBuilder = Widget Function(BuildContext context, List<IconData> icons, PickerItem child);
typedef PickerItem = Widget Function(IconData icon);
typedef PickerItemBuilder = Widget Function(IconData icon, bool isCurrentIcon, Function changeIcon);

class IconPicker extends StatefulWidget {
  const IconPicker({
    @required this.pickerIcon,
    @required this.onIconChanged,
    this.availableIcons = default_icons,
    this.layoutBuilder = defaultLayoutBuilder,
    this.itemBuilder = defaultItemBuilder,
  });

  final IconData pickerIcon;
  final ValueChanged<IconData> onIconChanged;
  final List<IconData> availableIcons;
  final PickerLayoutBuilder layoutBuilder;
  final PickerItemBuilder itemBuilder;

  static Widget defaultLayoutBuilder(BuildContext context, List<IconData> icons, PickerItem child) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return Container(
      width: orientation == Orientation.portrait ? 300.0 : 300.0,
      height: orientation == Orientation.portrait ? 360.0 : 200.0,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait ? 4 : 6,
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
        children: icons.map((IconData icon) => child(icon)).toList(),
      ),
    );
  }

  static Widget defaultItemBuilder(IconData icon, bool isCurrentIcon, Function changeIcon) {
    return Container(
      margin: EdgeInsets.all(5.0),
      child: Material(
        borderRadius: BorderRadius.circular(50.0),
        color: isCurrentIcon ? Colors.amber : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50.0),
          onTap: changeIcon,
          child: Icon(
            icon,
            color: ThemeController.activeTheme().iconColor,
            size: 40,
          ),
        ),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  IconData _currentIcon;

  @override
  void initState() {
    _currentIcon = widget.pickerIcon;
    super.initState();
  }

  void changeIcon(IconData icon) {
    setState(() => _currentIcon = icon);
    widget.onIconChanged(icon);
  }

  @override
  Widget build(BuildContext context) {
    return widget.layoutBuilder(
      context,
      widget.availableIcons ?? default_icons,
      (IconData icon, [bool _, Function __]) => widget.itemBuilder(icon, _currentIcon == icon, () => changeIcon(icon)),
    );
  }
}
