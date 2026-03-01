class Course {
  final String id;
  final String name;
  final String teacher;
  final String location;
  final int weekday; // 1-7 (周一到周日)
  final int startSection; // 第几节课开始 (1-12)
  final int endSection; // 第几节课结束
  final List<int> weeks; // 哪些周上课
  final String? description;

  Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.location,
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weeks,
    this.description,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      teacher: json['teacher'],
      location: json['location'],
      weekday: json['weekday'],
      startSection: json['startSection'],
      endSection: json['endSection'],
      weeks: List<int>.from(json['weeks']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'location': location,
      'weekday': weekday,
      'startSection': startSection,
      'endSection': endSection,
      'weeks': weeks,
      'description': description,
    };
  }

  // 获取上课时间段
  String getTimeRange() {
    final times = [
      '08:00-08:45',
      '08:55-09:40',
      '10:00-10:45',
      '10:55-11:40',
      '13:30-14:15',
      '14:25-15:10',
      '15:30-16:15',
      '16:25-17:10',
      '18:30-19:15',
      '19:25-20:10',
      '20:20-21:05',
      '21:15-22:00',
    ];
    if (startSection > 0 && startSection <= times.length) {
      String start = times[startSection - 1].split('-')[0];
      String end = times[endSection - 1].split('-')[1];
      return '$start-$end';
    }
    return '';
  }
}
