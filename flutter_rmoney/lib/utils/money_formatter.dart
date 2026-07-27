import 'package:intl/intl.dart';

String formatMnt(int amount) {
  return '${NumberFormat('#,###', 'en_US').format(amount)} MNT';
}
