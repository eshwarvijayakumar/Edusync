class StudentProfile {
  final String id;
  final String email;
  final String? mobile;
  final String name;
  final bool isSchoolStudent;
  
  // School fields
  final String? grade;
  final String? board;
  final String? state;
  final String? medium;
  final String? schoolName;

  // College fields
  final String? degree;
  final String? collegeName;
  final String? department;
  final String? yearOrSem;

  // Common
  final List<String> subjects;
  final String mainGoal;
  final int dailyQuestionsUsed;
  final String? lastQuestionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentProfile({
    required this.id,
    required this.email,
    this.mobile,
    required this.name,
    required this.isSchoolStudent,
    this.grade,
    this.board,
    this.state,
    this.medium,
    this.schoolName,
    this.degree,
    this.collegeName,
    this.department,
    this.yearOrSem,
    required this.subjects,
    required this.mainGoal,
    this.dailyQuestionsUsed = 0,
    this.lastQuestionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get studentBadge {
    if (isSchoolStudent) {
      final b = board?.isNotEmpty == true ? board : 'School';
      final g = grade?.isNotEmpty == true ? grade : '';
      return [b, g].where((s) => s != null && s.isNotEmpty).join(' • ');
    } else {
      final d = degree?.isNotEmpty == true ? degree : 'College';
      final dept = department?.isNotEmpty == true ? department : '';
      final sem = yearOrSem?.isNotEmpty == true ? yearOrSem : '';
      final parts = [d, dept, sem].where((s) => s != null && s.isNotEmpty).toList();
      return parts.join(' • ');
    }
  }

  String get preferredLanguage => medium ?? 'English';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'mobile': mobile,
      'name': name,
      'is_school_student': isSchoolStudent,
      'grade': grade,
      'board': board,
      'state': state,
      'medium': medium,
      'school_name': schoolName,
      'degree': degree,
      'college_name': collegeName,
      'department': department,
      'year_or_sem': yearOrSem,
      'subjects': subjects,
      'main_goal': mainGoal,
      'daily_questions_used': dailyQuestionsUsed,
      'last_question_date': lastQuestionDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String?,
      name: json['name'] as String? ?? 'Student',
      isSchoolStudent: json['is_school_student'] as bool? ?? true,
      grade: json['grade'] as String?,
      board: json['board'] as String?,
      state: json['state'] as String?,
      medium: json['medium'] as String?,
      schoolName: json['school_name'] as String?,
      degree: json['degree'] as String?,
      collegeName: json['college_name'] as String?,
      department: json['department'] as String?,
      yearOrSem: json['year_or_sem'] as String?,
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mainGoal: json['main_goal'] as String? ?? 'Understand concepts',
      dailyQuestionsUsed: json['daily_questions_used'] as int? ?? 0,
      lastQuestionDate: json['last_question_date'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  StudentProfile copyWith({
    String? id,
    String? email,
    String? mobile,
    String? name,
    bool? isSchoolStudent,
    String? grade,
    String? board,
    String? state,
    String? medium,
    String? schoolName,
    String? degree,
    String? collegeName,
    String? department,
    String? yearOrSem,
    List<String>? subjects,
    String? mainGoal,
    int? dailyQuestionsUsed,
    String? lastQuestionDate,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      isSchoolStudent: isSchoolStudent ?? this.isSchoolStudent,
      grade: grade ?? this.grade,
      board: board ?? this.board,
      state: state ?? this.state,
      medium: medium ?? this.medium,
      schoolName: schoolName ?? this.schoolName,
      degree: degree ?? this.degree,
      collegeName: collegeName ?? this.collegeName,
      department: department ?? this.department,
      yearOrSem: yearOrSem ?? this.yearOrSem,
      subjects: subjects ?? this.subjects,
      mainGoal: mainGoal ?? this.mainGoal,
      dailyQuestionsUsed: dailyQuestionsUsed ?? this.dailyQuestionsUsed,
      lastQuestionDate: lastQuestionDate ?? this.lastQuestionDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
