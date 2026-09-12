import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:laboraya_app/app/config/env_config.dart';

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
  final bool isPublisherVerified;

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
    this.isPublisherVerified = false,
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
    if (myId != null && myId.isNotEmpty && myId != '0') {
      return publisherId.toString().trim() == myId.toString().trim();
    }
    if (myName != null && myName.trim().isNotEmpty) {
      final cleanMy = myName.trim().toLowerCase();
      final cleanPub = publisherName.trim().toLowerCase();
      if (cleanPub == 'empleador' || cleanMy == 'empleador') return false;
      if (cleanPub == cleanMy || cleanPub == 'tú' || cleanPub == 'tu') {
        return true;
      }
    }
    return false;
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      final s = val.trim();
      if (s.isEmpty || s == 'null') return null;
      return double.tryParse(s);
    }
    return null;
  }

  static String formatUrl(String rawPath) {
    var trimmed = rawPath.trim().replaceAll('\\', '/');
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.contains('localhost') || trimmed.contains('127.0.0.1') || trimmed.contains('10.0.2.2')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.path.isNotEmpty) {
        return '${EnvConfig.development.apiBaseUrl}${uri.path}';
      }
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:image')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${EnvConfig.development.apiBaseUrl}$trimmed';
    }
    return '${EnvConfig.development.apiBaseUrl}/$trimmed';
  }

  static ImageProvider? getAvatarImageProvider(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final formatted = formatUrl(rawUrl);
    if (formatted.isEmpty) return null;
    if (formatted.startsWith('data:image')) {
      try {
        final commaIdx = formatted.indexOf(',');
        final base64Str = commaIdx >= 0 ? formatted.substring(commaIdx + 1) : formatted;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    if (formatted.startsWith('http')) {
      return NetworkImage(formatted);
    }
    if (File(formatted).existsSync()) {
      return FileImage(File(formatted));
    }
    return null;
  }

  static Widget buildImageWidget(
    String path, {
    BoxFit fit = BoxFit.cover,
    Widget Function()? fallbackBuilder,
  }) {
    final formatted = formatUrl(path);
    if (formatted.isEmpty) {
      return fallbackBuilder?.call() ?? const SizedBox.shrink();
    }
    if (formatted.startsWith('data:image')) {
      try {
        final commaIdx = formatted.indexOf(',');
        final base64Str = commaIdx >= 0 ? formatted.substring(commaIdx + 1) : formatted;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          errorBuilder: (_, __, ___) => fallbackBuilder?.call() ?? const SizedBox.shrink(),
        );
      } catch (_) {
        return fallbackBuilder?.call() ?? const SizedBox.shrink();
      }
    }
    if (formatted.startsWith('http')) {
      return Image.network(
        formatted,
        fit: fit,
        errorBuilder: (_, __, ___) => fallbackBuilder?.call() ?? const SizedBox.shrink(),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => fallbackBuilder?.call() ?? const SizedBox.shrink(),
    );
  }

  static String fixUtf8Encoding(String input) {
    if (input.isEmpty) return input;
    if (input.contains('Ã') || input.contains('Â') || input.contains('ï¿½')) {
      try {
        final latin1Bytes = latin1.encode(input);
        return utf8.decode(latin1Bytes);
      } catch (_) {}
    }
    return input;
  }

  factory JobEntity.fromJson(Map<String, dynamic> json) {
    final publisher = json['publisher'] as Map<String, dynamic>? ?? json['Publisher'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>? ?? json['Category'] as Map<String, dynamic>?;
    final rawImagesList = (json['images'] ?? json['Images'] ?? json['jobPhotos'] ?? json['JobPhotos']) as List?;

    final jobId = (json['id'] ?? json['Id'] ?? json['trabajoId'] ?? json['TrabajoId'] ?? '1').toString();
    final rawTitle = (json['title'] ?? json['Title'] ?? json['titulo'] ?? json['Titulo'] ?? '').toString();
    final rawDesc = (json['description'] ?? json['Description'] ?? json['descripcion'] ?? json['Descripcion'] ?? '').toString();
    final title = fixUtf8Encoding(rawTitle);
    final desc = fixUtf8Encoding(rawDesc);
    final catId = (json['categoryId'] ?? json['CategoryId'] ?? json['categoriaId'] ?? json['CategoriaId'] ?? '1').toString();
    final rawCatName =
        (category?['name'] ??
                category?['Name'] ??
                json['categoryName'] ??
                json['CategoryName'] ??
                json['categoriaNombre'] ??
                json['CategoriaNombre'] ??
                'General')
            .toString();
    final catName = fixUtf8Encoding(rawCatName);
    final rawAddr = (json['address'] ?? json['Address'] ?? json['direccion'] ?? json['Direccion'] ?? json['distrito'] ?? json['Distrito'])
        ?.toString();
    final addr = rawAddr != null ? fixUtf8Encoding(rawAddr) : null;

    final parsedLat = _parseDouble(
      json['latitude'] ?? json['Latitude'] ?? json['latitud'] ?? json['Latitud'] ?? json['lat'] ?? json['Lat'],
    );
    final parsedLng = _parseDouble(
      json['longitude'] ?? json['Longitude'] ?? json['longitud'] ?? json['Longitud'] ?? json['lng'] ?? json['Lng'] ?? json['lon'],
    );

    // Coordenadas con fallback determinista en Lima si no vienen en la BD
    final lat = (parsedLat != null && parsedLat != 0.0)
        ? parsedLat
        : (-12.0464 + (jobId.hashCode.abs() % 50) * 0.001);
    final lng = (parsedLng != null && parsedLng != 0.0)
        ? parsedLng
        : (-77.0428 + ((jobId.hashCode.abs() ~/ 50) % 50) * 0.001);

    final budget = _parseDouble(
      json['presupuesto'] ?? json['Presupuesto'] ?? json['budgetMin'] ?? json['BudgetMin'] ?? json['precio'] ?? json['Precio'],
    );

    final pubId =
        (publisher?['id'] ?? publisher?['Id'] ?? json['publisherId'] ?? json['PublisherId'] ?? json['EmployerId'] ?? json['employerId'] ?? json['empleadorId'] ?? json['EmpleadorId'] ?? '1')
            .toString();
    final rawPubName =
        (json['empleadorNombre'] ??
                json['EmpleadorNombre'] ??
                json['EmployerName'] ??
                '${publisher?['firstName'] ?? publisher?['FirstName'] ?? ''} ${publisher?['lastName'] ?? publisher?['LastName'] ?? ''}'
                    .trim())
            .toString();
    final pubName = fixUtf8Encoding(formatPrivacyName(rawPubName));
    final rawAvatar = json['empleadorFoto'] ??
        json['EmpleadorFoto'] ??
        json['empleadorAvatar'] ??
        json['EmployerAvatar'] ??
        publisher?['avatar'] ??
        publisher?['Avatar'] ??
        json['avatarUrl'] ??
        json['AvatarUrl'];
    final pubAvatar = rawAvatar != null && rawAvatar.toString().trim().isNotEmpty
        ? formatUrl(rawAvatar.toString())
        : null;
    final pubRating = _parseDouble(
        json['empleadorCalificacion'] ?? json['publisherRating'] ?? json['PublisherRating']);
    final pubReviews = (json['empleadorTotalResenas'] ?? json['publisherReviews'] ?? json['PublisherReviews'] as num?)?.toInt();

    final rawSingleImage = json['imageUrl'] ??
        json['ImageUrl'] ??
        json['imagenUrl'] ??
        json['ImagenUrl'] ??
        json['fotoTrabajo'] ??
        json['FotoTrabajo'] ??
        json['imagenPrincipalUrl'] ??
        json['ImagenPrincipalUrl'] ??
        json['foto'] ??
        json['Foto'] ??
        json['imagen'] ??
        json['Imagen'] ??
        json['photoUrl'] ??
        json['PhotoUrl'];

    final List<String> imgs = [];
    void addImg(String? raw) {
      if (raw == null) return;
      final formatted = formatUrl(raw.trim());
      if (formatted.isNotEmpty && !imgs.contains(formatted)) {
        imgs.add(formatted);
      }
    }

    // 1. Extraer de lista de objetos/strings
    if (rawImagesList != null) {
      for (final item in rawImagesList) {
        if (item is Map) {
          final u = (item['imageUrl'] ?? item['ImageUrl'] ?? item['rutaImagen'] ?? item['url'] ?? item['path'])?.toString();
          addImg(u);
        } else if (item != null) {
          addImg(item.toString());
        }
      }
    }

    // 2. Extraer de cadena 'fotos' / 'Fotos' separada por comas
    final rawFotosStr = json['fotos'] ?? json['Fotos'];
    if (rawFotosStr is String && rawFotosStr.trim().isNotEmpty) {
      final parts = rawFotosStr.split(',');
      for (final p in parts) {
        addImg(p);
      }
    }

    // 3. Extraer imagen principal si no está en la lista
    if (rawSingleImage != null) {
      addImg(rawSingleImage.toString());
    }

    return JobEntity(
      id: jobId,
      title: title,
      description: desc,
      categoryId: catId,
      categoryName: catName,
      subcategoryName: (json['subcategory'] ?? json['Subcategory'])?['name']?.toString(),
      address: addr,
      latitude: lat,
      longitude: lng,
      modality: (json['modality'] ?? json['TipoPago'] ?? json['tipoPago'] ?? 'FIXED').toString(),
      budgetMin: budget,
      budgetMax: _parseDouble(json['budgetMax'] ?? json['BudgetMax']),
      budgetFixed: json['budgetFixed'] as bool? ?? json['BudgetFixed'] as bool? ?? true,
      currency: (json['currency'] ?? json['Currency'] ?? 'PEN').toString(),
      isRemote: json['isRemote'] as bool? ?? json['IsRemote'] as bool? ?? false,
      status: (json['status'] ?? json['estado'] ?? json['Estado'] ?? 'PUBLISHED').toString(),
      duration: (json['duration'] ?? json['Duration'])?.toString(),
      workersNeeded: (json['workersNeeded'] ?? json['WorkersNeeded'] as num?)?.toInt() ?? 1,
      experienceReq: (json['experienceReq'] ?? json['ExperienceReq'])?.toString(),
      materials: (json['materials'] ?? json['Materials'] ?? 'TO_COORDINATE').toString(),
      requiredDate: (json['requiredDate'] ?? json['RequiredDate'])?.toString(),
      applicantsCount: (json['applicantsCount'] ?? json['ApplicantsCount'] as num?)?.toInt() ?? 0,
      publisherId: pubId,
      publisherName: pubName.isNotEmpty ? pubName : 'Empleador',
      publisherAvatar: pubAvatar?.toString(),
      publisherRating: pubRating,
      publisherReviews: pubReviews,
      images: imgs,
      publishedAt: (json['publishedAt'] ?? json['PublishedAt']) != null
          ? DateTime.tryParse((json['publishedAt'] ?? json['PublishedAt']).toString())
          : null,
      createdAt: (json['createdAt'] ?? json['CreatedAt']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['CreatedAt']).toString()) ?? DateTime.now()
          : DateTime.now(),
      isUrgent: json['isUrgent'] == true || json['IsUrgent'] == true || json['urgente'] == true || json['Urgente'] == true,
      isPublisherVerified: json['isPublisherVerified'] == true ||
          json['publisherIsVerified'] == true ||
          json['verificado'] == true ||
          json['Verificado'] == true ||
          (publisher != null && (publisher['isVerified'] == true || publisher['verificado'] == true || publisher['Verificado'] == true)),
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
