class AlertTool {
  AlertTool._();

  static Map<String, dynamic> draftSms({
    required String sector,
    required String crisisType,
    required String severity,
  }) {
    final en = _englishMessage(sector, crisisType, severity);
    final ur = _urduMessage(sector, crisisType, severity);
    final recipients = _estimateRecipients(sector);

    return {
      'status': 'BROADCAST_QUEUED',
      'channel': 'SMS + Cell Broadcast',
      'message_en': en,
      'message_ur': ur,
      'recipient_count_estimate': recipients,
      'estimated_delivery_minutes': 5,
      'broadcast_center': 'NDMA Emergency Communication Cell, Islamabad',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static String _englishMessage(String sector, String crisisType, String severity) {
    switch (crisisType) {
      case 'flood':
        return 'NDMA ALERT [$severity]: Flash flooding in $sector. Avoid underpasses. '
            'Move to higher ground. Rescue 1122: 1122. Stay safe.';
      case 'heatwave':
        return 'NDMA ALERT [$severity]: Extreme heatwave in $sector. Stay indoors 11am–5pm. '
            'Drink water. Check on elderly neighbours. Cooling centers open.';
      case 'protest':
        return 'ITP ADVISORY [$severity]: $sector blocked due to gathering. '
            'Use alternate routes. Allow extra travel time. Updates on @ITP_Official.';
      default:
        return 'EMERGENCY ALERT [$severity]: Incident reported in $sector. Follow official channels for updates.';
    }
  }

  static String _urduMessage(String sector, String crisisType, String severity) {
    switch (crisisType) {
      case 'flood':
        return 'این ڈی ایم اے انتباہ: $sector میں سیلاب کی صورتحال ہے۔ زیر گزر راستوں سے گریز کریں۔ '
            'بلند جگہ پر منتقل ہوں۔ ریسکیو 1122 پر رابطہ کریں۔';
      case 'heatwave':
        return 'این ڈی ایم اے انتباہ: $sector میں شدید گرمی کی لہر ہے۔ گیارہ بجے سے پانچ بجے تک گھر میں رہیں۔ '
            'پانی پئیں اور بزرگوں کا خیال رکھیں۔';
      case 'protest':
        return 'آئی ٹی پی ہدایت: $sector دھرنے کی وجہ سے بند ہے۔ متبادل راستے استعمال کریں۔ '
            'سفر کے لیے اضافی وقت رکھیں۔';
      default:
        return 'ہنگامی انتباہ: $sector میں ایک واقعہ رپورٹ ہوا ہے۔ سرکاری ذرائع سے رابطے میں رہیں۔';
    }
  }

  static int _estimateRecipients(String sector) {
    final s = sector.toUpperCase();
    if (s.contains('JACOBABAD')) return 220000;
    if (s.contains('FAIZABAD')) return 180000;
    if (s.contains('G-10') || s.contains('G-11')) return 45000;
    if (s.contains('BLUE AREA')) return 28000;
    return 22000;
  }
}
