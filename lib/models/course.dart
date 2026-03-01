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
    // 根据吉林大学教务系统实际时间表
    final times = [
      '08:00-08:45',   // 第1节
      '08:55-09:40',   // 第2节
      '10:00-10:45',   // 第3节
      '10:55-11:40',   // 第4节
      '13:30-14:15',   // 第5节
      '14:25-15:10',   // 第6节
      '15:30-16:15',   // 第7节
      '16:25-17:10',   // 第8节
      '18:20-19:05',   // 第9节
      '19:06-19:50',   // 第10节
      '20:00-20:45',   // 第11节
      '20:46-21:30',   // 第12节
    ];
    if (startSection > 0 && startSection <= times.length && 
        endSection > 0 && endSection <= times.length) {
      String start = times[startSection - 1].split('-')[0];
      String end = times[endSection - 1].split('-')[1];
      return '$start-$end';
    }
    return '';
  }
}
