import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({required this.icon,required this.label,required this.value,this.caption,super.key});
  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(child: Padding(padding: const EdgeInsets.all(16),child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
      DecoratedBox(decoration: BoxDecoration(color: scheme.primaryContainer,borderRadius: BorderRadius.circular(12)),child: Padding(padding: const EdgeInsets.all(8),child: Icon(icon,size:20,color:scheme.onPrimaryContainer))),
      const Spacer(),
      Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700)),
      const SizedBox(height:2),
      Text(label,style:Theme.of(context).textTheme.bodyMedium?.copyWith(color:scheme.onSurfaceVariant)),
      if (caption case final text?) ...[const SizedBox(height:2),Text(text,maxLines:1,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall?.copyWith(color:scheme.onSurfaceVariant))],
    ])));
  }
}
