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
  final double salary;

  Teacher({
    required this.teacherId,
    required this.name,
    required this.email,
    required this.phone,
    required this.assignedClasses,
    required this.subjects,
    required this.role,
    this.qualification = '',
    this.salary = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'staff_id': teacherId,
    'name': name,
    'email': email,
    'phone': phone,
    'assigned_classes': assignedClasses.join(','),
    'subjects': subjects.join(','),
    'role': role,
    'qualification': qualification,
    'salary': salary,
  };

  factory Teacher.fromMap(Map<String, dynamic> map) => Teacher(
    teacherId: map['staff_id'] ?? map['teacher_id'] ?? map['teacherId'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    assignedClasses: (map['assigned_classes'] ?? map['assignedClasses'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
    subjects: (map['subjects'] as String? ?? '').split(',').where((e) => e.isNotEmpty).toList(),
    role: map['role'] ?? '',
    qualification: map['qualification'] ?? '',
    salary: (map['salary'] as num? ?? 0.0).toDouble(),
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

  int get age {
    if (dateOfBirth.isEmpty) return 0;
    try {
      DateTime dob = DateTime.parse(dateOfBirth);
      DateTime now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
      return age;
    } catch (_) { return 0; }
  }

  Map<String, dynamic> toMap() => {
    'student_id': studentId,
    'admission_number': admissionNumber,
    'name': name,
    'gender': gender,
    'grade': grade,
    'stream': stream,
    'date_of_birth': dateOfBirth,
    'parent_name': parentName,
    'parent_phone': parentPhone,
    'parent_email': parentEmail,
    'address': address,
    'medical_info': medicalInfo,
    'photo_url': photoUrl,
    'status': status,
    'parent_id': parentId,
    'admission_date': admissionDate,
  };

  factory Student.fromMap(Map<String, dynamic> map) => Student(
    studentId: map['student_id'] ?? map['studentId'] ?? '',
    admissionNumber: map['admission_number'] ?? map['admissionNumber'] ?? '',
    name: map['name'] ?? '',
    gender: map['gender'] ?? 'Other',
    grade: map['grade'] ?? '',
    stream: map['stream'] ?? '',
    dateOfBirth: map['date_of_birth'] ?? map['dateOfBirth'] ?? '',
    parentName: map['parent_name'] ?? map['parentName'] ?? '',
    parentPhone: map['parent_phone'] ?? map['parentPhone'] ?? '',
    parentEmail: map['parent_email'] ?? map['parentEmail'],
    address: map['address'] ?? '',
    medicalInfo: map['medical_info'] ?? map['medicalInfo'] ?? '',
    photoUrl: map['photo_url'] ?? map['photoUrl'] ?? '',
    status: map['status'] ?? 'Active',
    parentId: map['parent_id'] ?? map['parentId'],
    admissionDate: map['admission_date'] ?? map['admissionDate'],
  );
}

class FeeStructure {
  final String grade;
  final double totalFee;
  final Map<String, double> breakdown;

  FeeStructure({
    required this.grade,
    required this.totalFee,
    this.breakdown = const {},
  });

  Map<String, dynamic> toMap() => {
    'grade': grade,
    'total_fee': totalFee,
    'breakdown': jsonEncode(breakdown),
  };

  factory FeeStructure.fromMap(Map<String, dynamic> map) {
    Map<String, double> b = {};
    if (map['breakdown'] != null) {
      try {
        final decoded = jsonDecode(map['breakdown']);
        if (decoded is Map) {
          decoded.forEach((k, v) => b[k.toString()] = (v as num).toDouble());
        }
      } catch (_) {}
    }
    return FeeStructure(
      grade: map['grade'] ?? '',
      totalFee: (map['total_fee'] as num? ?? 0.0).toDouble(),
      breakdown: b,
    );
  }
}

class FeePayment {
  final String? feeId;
  final String studentId;
  final String studentName;
  final double amountPaid;
  final String term;
  final int year;
  final String paymentMethod;
  final String category;
  final String? reference;
  final String receiptNumber;
  final String paymentDate;

  FeePayment({
    this.feeId,
    required this.studentId,
    required this.studentName,
    required this.amountPaid,
    required this.term,
    required this.year,
    required this.paymentMethod,
    required this.category,
    this.reference,
    required this.receiptNumber,
    required this.paymentDate,
  });

  Map<String, dynamic> toMap() => {
    'fee_id': feeId,
    'student_id': studentId,
    'student_name': studentName,
    'amount_paid': amountPaid,
    'term': term,
    'year': year,
    'payment_method': paymentMethod,
    'category': category,
    'reference': reference,
    'receipt_number': receiptNumber,
    'payment_date': paymentDate,
  };

  factory FeePayment.fromMap(Map<String, dynamic> map) => FeePayment(
    feeId: map['fee_id']?.toString(),
    studentId: map['student_id'] ?? '',
    studentName: map['student_name'] ?? '',
    amountPaid: (map['amount_paid'] as num? ?? 0.0).toDouble(),
    term: map['term'] ?? '',
    year: (map['year'] as num? ?? DateTime.now().year).toInt(),
    paymentMethod: map['payment_method'] ?? 'Cash',
    category: map['category'] ?? 'Tuition',
    reference: map['reference'],
    receiptNumber: map['receipt_number'] ?? '',
    paymentDate: map['payment_date'] ?? '',
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
    'parent_id': parentId,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'occupation': occupation,
  };

  factory ParentModel.fromMap(Map<String, dynamic> map) => ParentModel(
    parentId: map['parent_id'] ?? map['parentId'] ?? '',
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
    'notification_id': notificationId,
    'title': title,
    'message': message,
    'target_role': targetRole,
    'target_id': targetId,
    'sender_id': senderId,
    'timestamp': timestamp,
    'is_read': isRead ? 1 : 0,
  };

  factory NotificationModel.fromMap(Map<String, dynamic> map) => NotificationModel(
    notificationId: map['notification_id'] ?? map['notificationId'] ?? '',
    title: map['title'] ?? '',
    message: map['message'] ?? '',
    targetRole: map['target_role'] ?? map['targetRole'] ?? '',
    targetId: map['target_id'] ?? map['targetId'],
    senderId: map['sender_id'] ?? map['senderId'] ?? '',
    timestamp: map['timestamp'] ?? '',
    isRead: (map['is_read'] ?? map['isRead'] as int? ?? 0) == 1,
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
    'target_id': studentId,
    'target_name': studentName,
    'grade': grade,
    'stream': stream,
    'status': status,
    'term': term,
    'year': year,
  };

  factory Attendance.fromMap(Map<String, dynamic> map) => Attendance(
    date: map['date'] ?? '',
    studentId: map['target_id'] ?? map['targetId'] ?? map['student_id'] ?? map['studentId'] ?? '',
    studentName: map['target_name'] ?? map['targetName'] ?? map['student_name'] ?? map['studentName'] ?? '',
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
    'mark_id': markId,
    'student_id': studentId,
    'student_name': studentName,
    'grade': grade,
    'stream': stream,
    'subject': subject,
    'score': score,
    'points': points,
    'achievement_level': achievementLevel,
    'term': term,
    'year': year,
    'exam_type': examType,
  };

  factory Mark.fromMap(Map<String, dynamic> map) => Mark(
    markId: map['mark_id'] ?? map['markId'] ?? '',
    studentId: map['student_id'] ?? map['studentId'] ?? '',
    studentName: map['student_name'] ?? map['studentName'] ?? '',
    grade: map['grade'] ?? '',
    stream: map['stream'] ?? '',
    subject: map['subject'] ?? '',
    score: (map['score'] as num? ?? 0).toDouble(),
    points: (map['points'] as num? ?? 0).toInt(),
    achievementLevel: map['achievement_level'] ?? map['achievementLevel'] ?? '',
    term: map['term'] ?? '',
    year: map['year'] as int? ?? 0,
    examType: map['exam_type'] ?? map['examType'] ?? 'Opener',
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
    'homework_id': homeworkId,
    'title': title,
    'description': description,
    'subject': subject,
    'grade': grade,
    'stream': stream,
    'due_date': dueDate,
    'posted_date': postedDate,
    'posted_by': postedBy,
  };

  factory Homework.fromMap(Map<String, dynamic> map) => Homework(
    homeworkId: map['homework_id'] ?? map['homeworkId'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    subject: map['subject'] ?? '',
    grade: map['grade'] ?? '',
    stream: map['stream'] ?? '',
    dueDate: map['due_date'] ?? map['dueDate'] ?? '',
    postedDate: map['posted_date'] ?? map['postedDate'] ?? '',
    postedBy: map['posted_by'] ?? map['postedBy'] ?? '',
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
    'book_id': bookId,
    'title': title,
    'author': author,
    'isbn': isbn,
    'category': category,
    'total_copies': totalCopies,
    'available_copies': availableCopies,
  };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
    bookId: map['book_id'] ?? map['bookId'] ?? '',
    title: map['title'] ?? '',
    author: map['author'] ?? '',
    isbn: map['isbn'] ?? '',
    category: map['category'] ?? '',
    totalCopies: map['total_copies'] ?? map['totalCopies'] ?? 0,
    availableCopies: map['available_copies'] ?? map['availableCopies'] ?? 0,
  );
}
