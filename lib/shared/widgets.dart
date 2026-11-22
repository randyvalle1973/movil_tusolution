import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor))],
      ])),
      if (action != null) action!,
    ]),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: .65)),
    const SizedBox(height: 14), Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
  ])));
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      'recibida' => (const Color(0xFFE6F0FF), const Color(0xFF1769E0)),
      'en_reparacion' => (const Color(0xFFFFF2D9), const Color(0xFFB7791F)),
      'lista' => (const Color(0xFFE1F7ED), const Color(0xFF168454)),
      'entregada' => (const Color(0xFFE8EAF0), const Color(0xFF596579)),
      _ => (const Color(0xFFFFE8E8), const Color(0xFFB42318)),
    };
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(decoration: BoxDecoration(color: dark ? colors.$2.withValues(alpha: .18) : colors.$1, borderRadius: BorderRadius.circular(30)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: dark ? colors.$2.withValues(alpha: .95) : colors.$2, fontSize: 10, fontWeight: FontWeight.w800))));
  }
}

InputDecoration fieldDecoration(String label, {String? hint, IconData? icon}) => InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon));
