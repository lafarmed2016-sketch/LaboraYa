class JobEntity {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? subcategoryName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String modality;
  final double? budgetMin;
  final double? budgetMax;
  final bool budgetFixed;
  final String currency;
  final bool isRemote;
  final String status;
  final String? duration;
  final int workersNeeded;
  final String? experienceReq;
  final String materials;
  final String? requiredDate;
  final int applicantsCount;
  final String publisherId;
  final String publisherName;
  final String? publisherAvatar;
  final double? publisherRating;
  final int? publisherReviews;
  final List<String> images;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final bool isUrgent;

  const JobEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryName,
    this.address,
    this.latitude,
    this.longitude,
    required this.modality,
    this.budgetMin,
    this.budgetMax,
    this.budgetFixed = false,
    this.currency = 'PEN',
    this.isRemote = false,
    this.status = 'PUBLISHED',
    this.duration,
    this.workersNeeded = 1,
    this.experienceReq,
    this.materials = 'TO_COORDINATE',
    this.requiredDate,
    this.applicantsCount = 0,
    required this.publisherId,
    required this.publisherName,
    this.publisherAvatar,
    this.publisherRating,
    this.publisherReviews,
    this.images = const [],
    this.publishedAt,
    required this.createdAt,
    this.isUrgent = false,
  });

  JobEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? subcategoryName,
    String? address,
    double? latitude,
    double? longitude,
    String? modality,
    double? budgetMin,
    double? budgetMax,
    bool? budgetFixed,
    String? currency,
    bool? isRemote,
    String? status,
    String? duration,
    int? workersNeeded,
    String? experienceReq,
    String? materials,
    String? requiredDate,
    int? applicantsCount,
    String? publisherId,
    String? publisherName,
    String? publisherAvatar,
    double? publisherRating,
    int? publisherReviews,
    List<String>? images,
    DateTime? publishedAt,
    DateTime? createdAt,
    bool? isUrgent,
  }) {
    return JobEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      modality: modality ?? this.modality,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      budgetFixed: budgetFixed ?? this.budgetFixed,
      currency: currency ?? this.currency,
      isRemote: isRemote ?? this.isRemote,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      workersNeeded: workersNeeded ?? this.workersNeeded,
      experienceReq: experienceReq ?? this.experienceReq,
      materials: materials ?? this.materials,
      requiredDate: requiredDate ?? this.requiredDate,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      publisherId: publisherId ?? this.publisherId,
      publisherName: publisherName ?? this.publisherName,
      publisherAvatar: publisherAvatar ?? this.publisherAvatar,
      publisherRating: publisherRating ?? this.publisherRating,
      publisherReviews: publisherReviews ?? this.publisherReviews,
      images: images ?? this.images,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  String get modalityLabel => modality == 'FIXED' ? 'Precio fijo' : 'Por hora';

  String get formattedBudget {
    if (budgetMin != null && budgetMax != null && budgetMin != budgetMax) {
      return 'S/ ${budgetMin!.toStringAsFixed(0)} - S/ ${budgetMax!.toStringAsFixed(0)}';
    } else if (budgetMin != null) {
      return 'S/ ${budgetMin!.toStringAsFixed(0)}';
    }
    return 'A convenir';
  }

  String get materialsLabel => materials == 'BY_EMPLOYER'
      ? 'Cliente provee materiales'
      : materials == 'BY_WORKER'
      ? 'Trabajador provee materiales'
      : 'A coordinar';

  bool isMine({String? myId, String? myName}) {
    if (publisherId == 'user_current') return true;
    if (myId != null && myId.isNotEmpty && publisherId.toString() == myId.toString()) {
      return true;
    }
    if (myName != null && myName.trim().isNotEmpty) {
      final cleanMy = myName.trim().toLowerCase();
      final cleanPub = publisherName.trim().toLowerCase();
      if (cleanPub == cleanMy || cleanPub == 'tú' || cleanPub == 'tu') {
        return true;
      }
      final myParts = cleanMy.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (myParts.length >= 2) {
        final expectedShort = '${myParts[0]} ${myParts[1][0]}.';
        if (cleanPub == expectedShort.toLowerCase()) {
          return true;
        }
      }
    }
    return false;
  }

  factory JobEntity.fromJson(Map<String, dynamic> json) {
    final publisher = json['publisher'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    final imagesList = json['images'] as List?;

    final jobId = (json['id'] ?? json['trabajoId'] ?? '1').toString();
    final title = (json['title'] ?? json['titulo'] ?? '').toString();
    final desc = (json['description'] ?? json['descripcion'] ?? '').toString();
    final catId = (json['categoryId'] ?? json['categoriaId'] ?? '1').toString();
    final catName =
        (category?['name'] ??
                json['categoryName'] ??
                json['categoriaNombre'] ??
                'General')
            .toString();
    final addr = (json['address'] ?? json['direccion'] ?? json['distrito'])
        ?.toString();
    final lat = (json['latitude'] ?? json['latitud'] as num?)?.toDouble();
    final lng = (json['longitude'] ?? json['longitud'] as num?)?.toDouble();
    final budget = (json['presupuesto'] ?? json['budgetMin'] as num?)
        ?.toDouble();
    final pubId =
        (publisher?['id'] ?? json['publisherId'] ?? json['empleadorId'] ?? '1')
            .toString();
    final rawPubName =
        (json['empleadorNombre'] ??
                '${publisher?['firstName'] ?? ''} ${publisher?['lastName'] ?? ''}'
                    .trim())
            .toString();
    final pubName = formatPrivacyName(rawPubName);
    final pubAvatar = json['empleadorAvatar'] ?? publisher?['avatar'];
    final pubRating =
        (json['empleadorCalificacion'] ?? json['publisherRating'] as num?)
            ?.toDouble();
    final pubReviews =
        json['empleadorTotalResenas'] ?? json['publisherReviews'];

    List<String> imgs = [];
    if (imagesList != null) {
      imgs = imagesList.map((e) => e.toString()).toList();
    } else if (json['imagenPrincipalUrl'] != null) {
      imgs = [json['imagenPrincipalUrl'].toString()];
    }

    return JobEntity(
      id: jobId,
      title: title,
      description: desc,
      categoryId: catId,
      categoryName: catName,
      subcategoryName: json['subcategory']?['name']?.toString(),
      address: addr,
      latitude: lat,
      longitude: lng,
      modality: (json['modality'] ?? json['tipoPago'] ?? 'FIXED').toString(),
      budgetMin: budget,
      budgetMax: (json['budgetMax'] as num?)?.toDouble(),
      budgetFixed: json['budgetFixed'] as bool? ?? true,
      currency: (json['currency'] ?? 'PEN').toString(),
      isRemote: json['isRemote'] as bool? ?? false,
      status: (json['status'] ?? json['estado'] ?? 'PUBLISHED').toString(),
      duration: json['duration']?.toString(),
      workersNeeded: json['workersNeeded'] as int? ?? 1,
      experienceReq: json['experienceReq']?.toString(),
      materials: (json['materials'] ?? 'TO_COORDINATE').toString(),
      requiredDate: json['requiredDate']?.toString(),
      applicantsCount: json['applicantsCount'] as int? ?? 0,
      publisherId: pubId,
      publisherName: pubName.isNotEmpty ? pubName : 'Empleador',
      publisherAvatar: pubAvatar?.toString(),
      publisherRating: pubRating,
      publisherReviews: pubReviews as int?,
      images: imgs,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isUrgent: json['isUrgent'] == true || json['urgente'] == true,
    );
  }

  static String formatPrivacyName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Empleador';
    final parts = raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Empleador';
    
    String cap(String s) => s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
    
    final firstName = cap(parts[0]);
    if (parts.length == 1) return firstName;

    String lastNameInitial = '';
    if (parts.length >= 4) {
      lastNameInitial = parts[2][0].toUpperCase();
    } else if (parts.length >= 2) {
      lastNameInitial = parts[1][0].toUpperCase();
    }

    if (lastNameInitial.isNotEmpty) {
      return '$firstName $lastNameInitial.';
    }
    return firstName;
  }
}
