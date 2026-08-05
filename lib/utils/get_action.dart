List<Map<String, dynamic>> getActions(List<Map<String, dynamic>> children) {
  if (children.isNotEmpty) {
    return [
      ...children.where((c) => c['type'] == 'action'),
      ...getActions(children[children.indexWhere((c) => c['type'] == 'action')]
          ['children'])
    ];
  } else {
    return [];
  }
}

Map<String, dynamic>? getAction(List<Map<String, dynamic>> children,
    {String type = 'view'}) {
  if (children.isNotEmpty) {
    return getActions(children).firstWhere((c) => c['type'] == type);
  } else {
    return null;
  }
}
