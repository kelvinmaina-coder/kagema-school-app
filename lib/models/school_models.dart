import 'dart:convert';

class Teacher {
  final String teacherId;
  final String name;
  final String email;
  final String phone;
  final List<String> assignedClasses;
  final List<String> subjects;
  final String role;
  final String qualification;

  Teacher({
    required this.teacherId,
    required this.name,
    required this.email,
    required this.phone,
    required this.assignedClasses,
    required this.subjects,
    required this.role,
    this.qualification = '',
  });

  Map<String, dynamic> toMap() => {
    'teacherId': teacherId,
    'name': name,
    'email': email,
    'phone': phone,
    'assignedClasses': assignedClasses.join(','),
    'subjects': subjects.join(','),
    'role': role,
    'qualification': qualification,
  };

  factory Teacher.fromMap(Map<String, dynamic> map) => Teacher(
    teacherId: map['teacherId'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    assignedClasses: (map['assignedClasses'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
    subjects: (map['subjects'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
    role: map['role'] ?? '',
    qualification: map['qualification'] ?? '',
  );
}

class Student {
  final String studentId;
  final String admissionNumber;
  final String name;
  final String gender;
  final String grade;
  final String stream;
  final String dateOfBirth;
  final String parentName;
  final String parentPhone;
  final String? parentEmail;
  final String address;
  final String medicalInfo;
  final String photoUrl;
  final String status; 
  final String? parentId;
  final String? admissionDate;

  Student({
    required this.studentId,
    required this.admissionNumber,
    required this.name,
    required this.gender,
    required this.grade,
    required this.stream,
    required this.dateOfBirth,
    required this.parentName,
    required this.parentPhone,
    this.parentEmail,
    this.address = '',
    this.medicalInfo = '',
    this.photoUrl = '',
    this.status = 'Active',
    this.parentId,
    this.admissionDate,
  });

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'admissionNumber': admissionNumber,
    'name': name,
    'gender': gender,
    'grade': grade,
    'stream': stream,
    'dateOfBirth': dateOfBirth,
    'parentName': parentName,
    'parentPhone': parentPhone,
    'parentEmail': parentEmail,
    'address': address,
    'medicalInfo': medicalInfo,
    'photoUrl': photoUrl,
    'status': status,
    'parentId': parentId,
    'admissionDate': admissionDate,
  };

  factory Student.fromMap(Map<String, dynamic> map) => Student(
    studentId: map['studentId'] ?? '',
    admissionNumber: map['admissionNumber'] ?? '',
    name: map['name'] ?? '',
    gender: map['gender'] ?? 'Other',
    grade: map['grade'] ?? '',
    stream: map['stream'] ?? '',
    dateOfBirth: map['dateOfBirth'] ?? '',
    parentName: map['parentName'] ?? '',
    parentPhone: map['parentPhone'] ?? '',
    parentEmail: map['parentEmail'],
    address: map['address'] ?? '',
    medicalInfo: map['medicalInfo'] ?? '',
    photoUrl: map['photoUrl'] ?? '',
    status: map['status'] ?? 'Active',
    parentId: map['parentId'],
    admissionDate: map['admissionDate'],
  );
}

class ParentModel {
  final String parentId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String occupation;

  ParentModel({
    required this.parentId,
    required this.name,
    required this.phone,
    required this.email,
    this.address = '',
    this.occupation = '',
  });

  Map<String, dynamic> toMap() => {
    'parentId': parentId,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'occupation': occupation,
  };

  factory ParentModel.fromMap(Map<String, dynamic> map) => ParentModel(
    parentId: map['parentId'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    email: map['email'] ?? '',
    address: map['address'] ?? '',
    occupation: map['occupation'] ?? '',
  );
}

class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final String targetRole;
  final String? targetId;
  final String senderId;
  final String timestamp;
  final bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.targetRole,
    this.targetId,
    required this.senderId,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'notificationId': notificationId,
    'title': title,
    'message': message,
    'targetRole': targetRole,
    'targetId': targetId,
    'senderId': senderId,
    'timestamp': timestamp,
    'isRead': isRead ? 1 : 0,
  };

  factory NotificationModel.fromMap(Map<String, dynamic> map) => NotificationModel(
    notificationId: map['notificationId'] ?? '',
    title: map['title'] ?? '',
    message: map['message'] ?? '',
    targetRole: map['targetRole'] ?? '',
    targetId: map['targetId'],
    senderId: map['senderId'] ?? '',
    timestamp: map['timestamp'] ?? '',
    isRead: (map['isRead'] as int? ?? 0) == 1,
  );
}

class Attendance {
  final String date;
  final String studentId;
  final String studentName;
  final String grade;
  final String stream;
  final String status;
  final String? term;
  final int? year;

  Attendance({
    required this.date,
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.stream,
    required this.status,
    this.term,
    this.year,
  });

  Map<String, dynamic> toMap() => {
    'date': date,
    'targetId': studentId,
    'targetName': studentName,
    'grade': grade,
    'stream': stream,
    'status': status,
    'term': term,
    'year': year,
  };

  factory Attendance.fromMap(Map<String, dynamic> map) => Attendance(
    date: map['date'] ?? '',
    studentId: map['targetId'] ?? map['studentId'] ?? '',
    studentName: map['targetName'] ?? map['studentName'] ?? '',
    grade: map['grade'] ?? '',
    stream: map['stream'] ?? '',
    status: map['status'] ?? '',
    term: map['term'],
    year: map['year'] as int?,
  );
}

class Mark {
  final String markId;
  final String studentId;
  final String studentName;
  final String grade;
  final String stream;
  final String subject;
  final double score;
  final int points;
  final String achievementLevel;
  final String term;
  final int year;
  final String examType;

  Mark({
    required this.markId,
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.stream,
    required this.subject,
    required this.score,
    required this.points,
    required this.achievementLevel,
    required this.term,
    required this.year,
    this.examType = 'Opener',
  });

  Map<String, dynamic> toMap() => {
    'markId': markId,
    'studentId': studentId,
    'studentName': studentName,
    'grade': grade,
    'stream': stream,
    'subject': subject,
    'score': score,
    'points': points,
    'achievementLevel': achievementLevel,
    'term': term,
    'year': year,
    'examType': examType,
  };

  factory Mark.fromMap(Map<String, dynamic> map) => Mark(
    markId: map['markId'] ?? '',
    studentId: map['studentId'] ?? '',
    studentName: map['studentName'] ?? '',
    grade: map['grade'] ?? '',
    stream: map['stream'] ?? '',
    subject: map['subject'] ?? '',
    score: (map['score'] as num? ?? 0).toDouble(),
    points: (map['points'] as num? ?? 0).toInt(),
    achievementLevel: map['achievementLevel'] ?? '',
    term: map['term'] ?? '',
    year: map['year'] as int? ?? 0,
    examType: map['examType'] ?? 'Opener',
  );
}

class Homework {
  final String homeworkId;
  final String title;
  final String description;
  final String subject;
  final String grade;
  final String stream;
  final String dueDate;
  final String postedDate;
  final String postedBy;

  Homework({
    required this.homeworkId,
    required this.title,
    required this.description,
    required this.subject,
    required this.grade,
    required this.stream,
    required this.dueDate,
    required this.postedDate,
    this.postedBy = '',
  });

  Map<String, dynamic> toMap() => {
    'homeworkId': homeworkId,
    'title': title,
    'description': description,
    'subject': subject,
    'grade': grade,
    'stream': stream,
    'dueDate': dueDate,
    'postedDate': postedDate,
    'postedBy': postedBy,
  };

  factory Homework.fromMap(Map<String, dynamic> map) => Homework(
    homeworkId: map['homeworkId'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    subject: map['subject'] ?? '',
    grade: map['grade'] ?? '',
    stream: map['stream'] ?? '',
    dueDate: map['dueDate'] ?? '',
    postedDate: map['postedDate'] ?? '',
    postedBy: map['postedBy'] ?? '',
  );
}

class Book {
  final String bookId;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final int totalCopies;
  final int availableCopies;

  Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.totalCopies,
    required this.availableCopies,
  });

  Map<String, dynamic> toMap() => {
    'bookId': bookId,
    'title': title,
    'author': author,
    'isbn': isbn,
    'category': category,
    'totalCopies': totalCopies,
    'availableCopies': availableCopies,
  };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
    bookId: map['bookId'] ?? '',
    title: map['title'] ?? '',
    author: map['author'] ?? '',
    isbn: map['isbn'] ?? '',
    category: map['category'] ?? '',
    totalCopies: map['totalCopies'] ?? 0,
    availableCopies: map['availableCopies'] ?? 0,
  );
}
