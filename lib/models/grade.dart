class Grade {
  final String courseId;
  final String courseName;
  final String credit;
  final String score;
  final String gradePoint;
  final String semester;
  final String? examType;

  Grade({
    required this.courseId,
    required this.courseName,
    required this.credit,
    required this.score,
    required this.gradePoint,
    required this.semester,
    this.examType,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      courseId: json['courseId'],
      courseName: json['courseName'],
      credit: json['credit'],
      score: json['score'],
      gradePoint: json['gradePoint'],
      semester: json['semester'],
      examType: json['examType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'credit': credit,
      'score': score,
      'gradePoint': gradePoint,
      'semester': semester,
      'examType': examType,
    };
  }
}
