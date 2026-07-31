/// Mapeo de categorías a imágenes de assets
class JobImages {
  static String getImageForCategory(String category) {
    final cat = category.toLowerCase().trim();

    if (cat.contains('plom') ||
        cat.contains('grifo') ||
        cat.contains('fuga') ||
        cat.contains('tubería')) {
      return 'assets/images/job_albanileria.png';
    }
    if (cat.contains('electri')) {
      return 'assets/images/job_electricidad.png';
    }
    if (cat.contains('pintu') || cat.contains('pintar')) {
      return 'assets/images/job_pintura.png';
    }
    if (cat.contains('carpint') || cat.contains('madera')) {
      return 'assets/images/job_carpinteria.png';
    }
    if (cat.contains('albañil') ||
        cat.contains('construc') ||
        cat.contains('pared') ||
        cat.contains('ladrillo')) {
      return 'assets/images/job_albanileria.png';
    }
    if (cat.contains('limpi')) {
      return 'assets/images/job_limpieza.png';
    }
    if (cat.contains('cerraj') ||
        cat.contains('chapa') ||
        cat.contains('llave')) {
      return 'assets/images/job_cerrajeria.png';
    }
    if (cat.contains('mecáni') ||
        cat.contains('motor') ||
        cat.contains('auto')) {
      return 'assets/images/job_mecanica.png';
    }
    if (cat.contains('tecno') ||
        cat.contains('comput') ||
        cat.contains('pc') ||
        cat.contains('laptop')) {
      return 'assets/images/job_tecnico_pc.png';
    }

    // Default
    return 'assets/images/job_albanileria.png';
  }

  /// Imagen basada en título o descripción del trabajo (más preciso)
  static String getImageForJob(String categoryName, String title) {
    final text = '$categoryName $title'.toLowerCase();

    if (text.contains('electri') ||
        text.contains('cable') ||
        text.contains('enchufe')) {
      return 'assets/images/job_electricidad.png';
    }
    if (text.contains('pintu') ||
        text.contains('pintar') ||
        text.contains('pintor')) {
      return 'assets/images/job_pintura.png';
    }
    if (text.contains('carpint') ||
        text.contains('closet') ||
        text.contains('madera') ||
        text.contains('mueble')) {
      return 'assets/images/job_carpinteria.png';
    }
    if (text.contains('albañil') ||
        text.contains('pared') ||
        text.contains('construc') ||
        text.contains('ladrillo')) {
      return 'assets/images/job_albanileria.png';
    }
    if (text.contains('limpi') || text.contains('aseo')) {
      return 'assets/images/job_limpieza.png';
    }
    if (text.contains('cerraj') ||
        text.contains('chapa') ||
        text.contains('cerradura')) {
      return 'assets/images/job_cerrajeria.png';
    }
    if (text.contains('mecáni') ||
        text.contains('motor') ||
        text.contains('auto') ||
        text.contains('carro')) {
      return 'assets/images/job_mecanica.png';
    }
    if (text.contains('tecno') ||
        text.contains('comput') ||
        text.contains('pc') ||
        text.contains('laptop') ||
        text.contains('redes')) {
      return 'assets/images/job_tecnico_pc.png';
    }
    if (text.contains('plom') ||
        text.contains('fuga') ||
        text.contains('grifo') ||
        text.contains('tubería') ||
        text.contains('agua')) {
      return 'assets/images/job_electricidad.png'; // plomería usa electricidad como similar visual
    }

    return getImageForCategory(categoryName);
  }
}
