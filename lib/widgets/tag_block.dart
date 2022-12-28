import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nhentai/data_model.dart';

enum TagState {
  none,
  included,
  excluded;

  TagState next() =>
    TagState.values[(index + 1)% TagState.values.length];
}

// ignore: must_be_immutable
class TagWithState extends Tag {
  TagWithState({ 
    required Tag tag,
    this.state = TagState.none,
  }) : super(
    id: tag.id,
    count: tag.count,
    type: tag.type,
    name: tag.name,
    url: tag.url,
  );

  TagWithState.none(Tag tag, [this.state = TagState.none]) : super(
    id: tag.id,
    count: tag.count,
    type: tag.type,
    name: tag.name,
    url: tag.url,
  );

  TagState state;
}


class TagBlock extends StatelessWidget {
  const TagBlock({
    required this.tag,
    super.key,
  });

  static final numberFormat = NumberFormat.compact();

  final TagWithState tag;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3.0),
      // boxShadow: const [
      //   BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(2, 2)),
      // ],
    ),
    child: Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Wrap(
        children: [
          if(tag.state == TagState.included)
            const Icon(Icons.add_circle)
          else if(tag.state == TagState.excluded)
            const Icon(Icons.remove_circle),
          Container(
            padding: const EdgeInsets.all(4.0),
            color: const Color.fromARGB(0xff, 0x4d, 0x4d, 0x4d),
            child: Text(tag.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4.0),
            color: const Color.fromARGB(0xff, 0x33, 0x33, 0x33),
            child: Text(TagBlock.numberFormat.format(tag.count),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          )
        ],
      ),
    ),  
  );
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TagWithState>('tagWithState', tag));
  }

}
