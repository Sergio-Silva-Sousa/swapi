import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/databank_image_provider.dart';

class DatabankImage extends ConsumerStatefulWidget {
  const DatabankImage.person({super.key, required this.name}) : _isPerson = true;
  const DatabankImage.planet({super.key, required this.name}) : _isPerson = false;
  final String name;
  final bool _isPerson;
  @override ConsumerState<DatabankImage> createState() => _DatabankImageState();
}
class _DatabankImageState extends ConsumerState<DatabankImage> {
  Future<String?>? _image;
  @override void initState() { super.initState(); final resolver=ref.read(databankImageResolverProvider); _image=widget._isPerson?resolver.personImage(widget.name):resolver.planetImage(widget.name); }
  @override Widget build(BuildContext context) => FutureBuilder<String?>(future:_image,builder:(context,snapshot){final url=snapshot.data; if(url==null)return const CircleAvatar(child:Icon(Icons.image_not_supported)); return ClipOval(child:CachedNetworkImage(imageUrl:url,width:48,height:48,fit:BoxFit.cover,placeholder:(_,__)=>const SizedBox(width:48,height:48,child:Center(child:CircularProgressIndicator(strokeWidth:2))),errorWidget:(_,__,___)=>const CircleAvatar(child:Icon(Icons.broken_image)),));});
}
