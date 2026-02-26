import '../config/constants.dart';

class ScreenContextFormatter {
  static String format(Map<String, dynamic> rawContext) {
    if (rawContext.containsKey('error')) {
      return 'Error: ${rawContext['error']}';
    }

    final packageName = rawContext['packageName'] as String? ?? 'Unknown';
    final nodes = rawContext['nodes'] as List? ?? [];

    final buffer = StringBuffer();
    buffer.writeln('App: $packageName');

    int count = 0;
    for (final node in nodes) {
      if (count >= AppConstants.maxScreenNodes) break;

      final nodeMap = node as Map<String, dynamic>;
      final formatted = _formatNode(nodeMap);
      if (formatted != null) {
        buffer.writeln(formatted);
        count++;
      }
    }

    return buffer.toString().trim();
  }

  static String? _formatNode(Map<String, dynamic> node) {
    final index = node['index'] as int? ?? 0;
    final className = node['className'] as String? ?? '';
    final text = (node['text'] as String? ?? '').trim();
    final contentDescription =
        (node['contentDescription'] as String? ?? '').trim();
    final bounds = node['bounds'] as Map<String, dynamic>?;

    final isClickable = node['isClickable'] as bool? ?? false;
    final isScrollable = node['isScrollable'] as bool? ?? false;
    final isEditable = node['isEditable'] as bool? ?? false;
    final isChecked = node['isChecked'] as bool? ?? false;
    final isSelected = node['isSelected'] as bool? ?? false;

    // Get display text
    String displayText = text.isNotEmpty ? text : contentDescription;
    if (displayText.isEmpty && !isClickable && !isScrollable && !isEditable) {
      return null; // Skip nodes with no useful info
    }

    // Truncate text
    if (displayText.length > AppConstants.maxTextLength) {
      displayText = '${displayText.substring(0, AppConstants.maxTextLength)}...';
    }

    // Get element type
    final elementType = _getElementType(className);

    // Build properties
    final props = <String>[];
    if (isClickable) props.add('clickable');
    if (isScrollable) props.add('scrollable');
    if (isEditable) props.add('editable');
    if (isChecked) props.add('checked');
    if (isSelected) props.add('selected');

    // Build bounds string
    String boundsStr = '';
    if (bounds != null) {
      final left = bounds['left'] ?? 0;
      final top = bounds['top'] ?? 0;
      final right = bounds['right'] ?? 0;
      final bottom = bounds['bottom'] ?? 0;
      boundsStr = ' [$left,$top→$right,$bottom]';
    }

    // Build output
    final propsStr = props.isNotEmpty ? ' (${props.join(', ')})' : '';
    final textStr = displayText.isNotEmpty ? ': "$displayText"' : '';

    return '[$index] $elementType$textStr$propsStr$boundsStr';
  }

  static String _getElementType(String className) {
    final lower = className.toLowerCase();

    if (lower.contains('button')) return 'Button';
    if (lower.contains('edittext')) return 'Input';
    if (lower.contains('textview')) return 'Text';
    if (lower.contains('imageview')) return 'Image';
    if (lower.contains('imagebutton')) return 'ImageButton';
    if (lower.contains('recyclerview') || lower.contains('scrollview')) {
      return 'ScrollView';
    }
    if (lower.contains('checkbox')) return 'Checkbox';
    if (lower.contains('switch')) return 'Switch';
    if (lower.contains('radiobutton')) return 'Radio';
    if (lower.contains('seekbar') || lower.contains('slider')) return 'Slider';
    if (lower.contains('progressbar')) return 'Progress';
    if (lower.contains('spinner')) return 'Dropdown';

    // Return last part of class name
    final parts = className.split('.');
    return parts.isNotEmpty ? parts.last : 'View';
  }
}
