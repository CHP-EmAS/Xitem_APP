import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/widgets/dialogs/PickerDialog.dart';
import 'package:xitem/widgets/dialogs/StandardDialog.dart';

class EventColorsNamesAssigner extends StatelessWidget {
  const EventColorsNamesAssigner({super.key, required this.colorTexts, required this.onColorChange, required this.onColorTextChange, required this.onColorTextDelete});

  final Map<int, String> colorTexts;
  final Function(int, int) onColorChange;
  final Function(int, String) onColorTextChange;
  final Function(int) onColorTextDelete;

  @override
  Widget build(BuildContext context) {

    Map<int, String> sortedColorMap = Map.fromEntries(
        colorTexts.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));

    return ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.only(bottom: 2, top: 2),
        itemCount: sortedColorMap.length,
        itemBuilder: (context, index) {
          int colorIndex = sortedColorMap.keys.elementAt(index);

          Color color = ThemeController.getEventColor(colorIndex);
          final String? text = colorTexts[colorIndex];

          return ListTile(
            leading: GestureDetector(
              onTap: () async {
                int? newColorIndex = await PickerDialog.eventColorPickerDialog(initialColor: colorIndex, colorLegend: colorTexts);
                if(newColorIndex == null) {
                  return;
                }

                onColorChange(colorIndex, newColorIndex);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.8), offset: const Offset(1, 2), blurRadius: 5)],
                ),
              ),
            ),
            title: Text(text ?? ""),
            trailing: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(0),
                  icon: Icon(
                    Icons.edit,
                    color: ThemeController.activeTheme().headlineColor,
                  ),
                  tooltip: "Beschreibung ändern",
                  onPressed: () async {
                    String? newText = await StandardDialog.textDialog("Gebe eine neue Beschreibung für die gewählte Farbe ein", "Beschreibung", text);

                    if(newText != null) {
                      if(newText.isNotEmpty) {
                        onColorTextChange(colorIndex, newText);
                      }
                    }
                  },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(0),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  tooltip: "Beschreibung entfernen",
                  onPressed: () async {
                    ConfirmAction? delete = await StandardDialog.confirmDialog("Farbbeschreibung löschen?", "Möchtest du diese Farbbeschreibung entfernen?");

                    if(delete == ConfirmAction.ok) {
                      onColorTextDelete(colorIndex);
                    }
                  },
                ),
              ],
            ),
          );
        });
  }
}
