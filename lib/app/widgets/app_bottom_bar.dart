import 'package:flutter/material.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const List<_BottomItem> _items = <_BottomItem>[
    _BottomItem(Icons.home_outlined, Icons.home, 'Beranda'),
    _BottomItem(Icons.pie_chart_outline, Icons.pie_chart, 'Rekap'),
    _BottomItem(Icons.add, Icons.add, 'Input'),
    _BottomItem(Icons.savings_outlined, Icons.savings, 'Target'),
    _BottomItem(Icons.settings_outlined, Icons.settings, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: List<Widget>.generate(_items.length, (int index) {
              final _BottomItem item = _items[index];
              final bool selected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: index == 2
                      ? _CenterItem(item: item, selected: selected)
                      : _RegularItem(item: item, selected: selected),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomItem {
  const _BottomItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _RegularItem extends StatelessWidget {
  const _RegularItem({required this.item, required this.selected});

  final _BottomItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(selected ? item.selectedIcon : item.icon, color: color),
        const SizedBox(height: 4),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _CenterItem extends StatelessWidget {
  const _CenterItem({required this.item, required this.selected});

  final _BottomItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            item.icon,
            color: selected ? scheme.onPrimary : scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
