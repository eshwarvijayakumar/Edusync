class AppConstants {
  static const String appName = 'EduSync';
  static const String appTagline = 'India-First AI Study Companion';
  static const String appVersion = '1.1.0';
  static const int dailyFreeQuestionLimit = 10;
  static const int maxUploadSizeBytes = 15 * 1024 * 1024; // 15 MB

  // School Grades: Specifically tailored to Grades 9 to 12
  static const List<String> schoolGrades = [
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  // School Boards: Specifically supporting CBSE and Tamil Nadu State Board
  static const List<String> schoolBoards = [
    'CBSE',
    'Tamil Nadu State Board',
    'Other',
  ];

  // Indian States & UTs (Tamil Nadu first)
  static const List<String> indianStates = [
    'Tamil Nadu',
    'Karnataka',
    'Andhra Pradesh',
    'Kerala',
    'Telangana',
    'Maharashtra',
    'Delhi (NCR)',
    'Rajasthan',
    'Gujarat',
    'Punjab',
    'Haryana',
    'Bihar',
    'Madhya Pradesh',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Odisha',
    'Assam',
    'Goa',
    'Jammu and Kashmir',
    'Ladakh',
    'Chandigarh',
    'Other State / UT',
  ];

  // Indian Mediums / Languages
  static const List<String> mediums = [
    'English',
    'Hindi',
    'Malayalam',
    'Tamil',
    'Telugu',
    'Kannada',
    'Marathi',
    'Bengali',
    'Gujarati',
    'Odia',
    'Punjabi',
    'Other',
  ];

  // Common School Subjects
  static const List<String> schoolSubjects = [
    'Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'Social Science',
    'History',
    'Geography',
    'English',
    'Hindi',
    'Computer Science',
    'Economics',
    'Accountancy',
    'Business Studies',
  ];

  // School Learning Goals
  static const List<String> schoolGoals = [
    'Understand concepts',
    'Complete homework',
    'Prepare for exams',
    'Improve marks',
  ];

  // College Degrees
  static const List<String> collegeDegrees = [
    'B.Tech / B.E.',
    'B.Sc',
    'B.Com',
    'BA',
    'MBBS / BDS',
    'BBA / BMS',
    'Law (LLB / BA LLB)',
    'BCA / MCA',
    'M.Tech',
    'MBA',
    'Pharmacy (B.Pharm)',
    'Other',
  ];

  // Common College Departments
  static const List<String> collegeDepartments = [
    'Computer Science & Engg (CSE)',
    'Information Technology (IT)',
    'AI & Data Science',
    'Electronics & Comm (ECE)',
    'Electrical & Electronics (EEE)',
    'Mechanical Engineering',
    'Civil Engineering',
    'Commerce & Accounting',
    'Management & Finance',
    'Humanities & Social Sciences',
    'Medical / Clinical',
    'Law & Jurisprudence',
    'Physics / Chemistry / Maths',
    'Other',
  ];

  // College Semesters
  static const List<String> collegeSemesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  // College Learning Goals
  static const List<String> collegeGoals = [
    'Exam preparation',
    'Assignments & projects',
    'Placements & interviews',
    'Coding practice & DSA',
    'Concept learning',
  ];

  // Supabase Configuration Keys (fallback to env)
  static const String defaultSupabaseUrl = 'https://YOUR_SUPABASE_PROJECT_ID.supabase.co';
  static const String defaultSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
