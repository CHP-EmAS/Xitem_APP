import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:xitem/controllers/ThemeController.dart';
import 'package:xitem/models/Event.dart';

class SlidableEventCard extends StatelessWidget {
  final bool editable;
  final Color color;
  final Widget content;
  final VoidCallback onEventShareTapped;
  final VoidCallback onEventEditTapped;
  final VoidCallback onEventDeleteTapped;

  const SlidableEventCard({super.key, required this.color, required this.editable, required this.content, required this.onEventShareTapped, required this.onEventEditTapped, required this.onEventDeleteTapped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
      child: Slidable(
        startActionPane:  ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              label: "Teilen",
              icon:  Icons.share,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              onPressed: (_) => onEventShareTapped,
            )
          ],
        ),
        endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.45,
            children: editable ? [
              SlidableAction(
                label: 'Ändern',
                icon: Icons.edit,
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                onPressed: (_) => onEventEditTapped,
              ),
              SlidableAction(
                label: 'Löschen',
                icon: Icons.delete,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onPressed: (_) => onEventDeleteTapped,
              ),
            ] : []
        ),
        child: Card(
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 3,
          color: ThemeController.activeTheme().cardColor,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: color,
                  width: 3,
                ),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}