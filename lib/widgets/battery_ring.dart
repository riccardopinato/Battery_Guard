import 'dart:math' as math;
import 'package:flutter/material.dart';

class BatteryRing extends StatelessWidget {
  const BatteryRing({required this.level,required this.temperatureC,required this.isCharging,super.key});
  final int level; final double temperatureC; final bool isCharging;
  Color _ringColor(BuildContext context) { final scheme=Theme.of(context).colorScheme; if(temperatureC>=45)return scheme.error; if(temperatureC>=40)return const Color(0xFFF59E0B); if(level<=15)return scheme.error; if(isCharging)return const Color(0xFF2F80ED); return scheme.primary; }
  @override
  Widget build(BuildContext context) { final color=_ringColor(context); return TweenAnimationBuilder<double>(tween:Tween(begin:0,end:level/100),duration:const Duration(milliseconds:250),curve:Curves.easeOutCubic,builder:(context,value,child){ return SizedBox.square(dimension:250,child:CustomPaint(painter:_BatteryRingPainter(progress:value,color:color,trackColor:Theme.of(context).colorScheme.surfaceContainerHighest),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(isCharging?Icons.bolt_rounded:Icons.battery_5_bar_rounded,size:30,color:color),const SizedBox(height:6),Text('$level%',style:Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight:FontWeight.w800,letterSpacing:-2)),Text(isCharging?'In carica':'Batteria',style:Theme.of(context).textTheme.titleMedium?.copyWith(color:Theme.of(context).colorScheme.onSurfaceVariant))])))); }); }
}
class _BatteryRingPainter extends CustomPainter {
  const _BatteryRingPainter({required this.progress,required this.color,required this.trackColor}); final double progress; final Color color; final Color trackColor;
  @override void paint(Canvas canvas,Size size){ final center=Offset(size.width/2,size.height/2); final radius=math.min(size.width,size.height)/2-14; const stroke=14.0; final track=Paint()..style=PaintingStyle.stroke..strokeWidth=stroke..strokeCap=StrokeCap.round..color=trackColor; final active=Paint()..style=PaintingStyle.stroke..strokeWidth=stroke..strokeCap=StrokeCap.round..color=color; canvas.drawCircle(center,radius,track); canvas.drawArc(Rect.fromCircle(center:center,radius:radius),-math.pi/2,math.pi*2*progress.clamp(0,1),false,active); }
  @override bool shouldRepaint(covariant _BatteryRingPainter oldDelegate)=>oldDelegate.progress!=progress||oldDelegate.color!=color||oldDelegate.trackColor!=trackColor;
}
