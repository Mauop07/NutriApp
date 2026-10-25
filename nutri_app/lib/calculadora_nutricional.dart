class CalculadoraNutricional {
  /// Calcula la Tasa Metabólica Basal (TMB) usando la fórmula de Harris-Benedict[cite: 8].
  static double calcularTMB({
    required String genero,
    required double pesoKg,
    required double alturaCm,
    required int edad,
  }) {
    if (genero.toLowerCase() == 'masculino') {
      return 88.362 + (13.397 * pesoKg) + (4.799 * alturaCm) - (5.677 * edad);
    } else {
      return 447.593 + (9.247 * pesoKg) + (3.098 * alturaCm) - (4.330 * edad);
    }
  }

  /// Calcula las calorías de mantenimiento según el factor de actividad[cite: 8].
  static double calcularMantenimiento(double tmb, double factorActividad) {
    return tmb * factorActividad;
  }
}
