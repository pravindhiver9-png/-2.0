import 'util.dart';

DateTime day(DateTime x) => DateTime.utc(x.year, x.month, x.day);

DateTime addMonths(DateTime d, int n) {
  final y = d.year + (d.month - 1 + n) ~/ 12;
  final m = (d.month - 1 + n) % 12 + 1;
  final last = DateTime.utc(y, m + 1, 0).day;
  return DateTime.utc(y, m, d.day > last ? last : d.day);
}

/// whole calendar months + leftover days between two dates
({int months, int days}) period(DateTime a, DateTime b) {
  a = day(a);
  b = day(b);
  if (!b.isAfter(a)) return (months: 0, days: 0);
  var m = (b.year - a.year) * 12 + b.month - a.month;
  if (addMonths(a, m).isAfter(b)) m--;
  return (months: m, days: b.difference(addMonths(a, m)).inDays);
}

/// simple interest, rate is % per month, calendar months + days/30, rounded to rupee
double expectedInterest(double p, double rate, DateTime a, DateTime b) {
  final x = period(a, b);
  return (p * rate / 100 * (x.months + x.days / 30)).roundToDouble();
}

/// date up to which a given interest payment covers the loan
DateTime coveredDate(DateTime from, double p, double rate, double paid) {
  final monthly = p * rate / 100;
  if (monthly <= 0) return day(from);
  final m = paid / monthly;
  final whole = m.floor();
  final days = ((m - whole) * 30).round();
  return addMonths(day(from), whole).add(Duration(days: days));
}

String periodText(DateTime a, DateTime b) {
  final x = period(a, b);
  final parts = <String>[];
  if (x.months > 0) parts.add('${x.months} माह');
  if (x.days > 0 || parts.isEmpty) parts.add('${x.days} दिन');
  return parts.join(' ');
}

class Plan {
  final String kind; // paid | carry | grace
  final DateTime? date; // carry date, or new grace end (null = keep)
  final double amt, unpaid;
  const Plan(this.kind, this.date, this.amt, this.unpaid);
}

/// What happens to a loan after a repayment. Pure function (also used for preview).
Plan planRepayment({
  required bool grace,
  required double principal, // current principal (rem_principal when in grace)
  required double rate,
  required DateTime loanDate,
  required DateTime pay,
  required double finalInt,
  required double ip,
  required double pp,
  double graceUnpaid = 0,
}) {
  pay = day(pay);
  const eps = 0.5;
  if (grace) {
    final u = graceUnpaid - ip;
    final r = principal - pp;
    if (u <= eps) return r > eps ? Plan('carry', pay, r, 0) : const Plan('paid', null, 0, 0);
    return Plan('grace', null, r < 0 ? 0 : r, u);
  }
  final u = finalInt - ip;
  final graceEnd = pay.add(const Duration(days: 15));
  if (pp >= principal - eps) {
    return u <= eps ? const Plan('paid', null, 0, 0) : Plan('grace', graceEnd, 0, u);
  }
  if (pp > 0) {
    final r = principal - pp;
    return u <= eps ? Plan('carry', pay, r, 0) : Plan('grace', graceEnd, r, u);
  }
  final cd = ip >= finalInt - eps ? pay : coveredDate(loanDate, principal, rate, ip);
  return Plan('carry', cd, principal, 0);
}
