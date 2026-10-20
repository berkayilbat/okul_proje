import 'package:flutter/material.dart';

/// İlan meslek kategorileri ve görsel yardımcıları
class JobCategoryHelper {
  /// İlan başlığına göre kategori ikonunu döner
  static IconData getCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('barista') || lower.contains('kahve') || lower.contains('cafe') || lower.contains('kafe')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('garson') || lower.contains('komi') || lower.contains('restoran') || lower.contains('mutfak') || lower.contains('aşçı') || lower.contains('servis')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('kurye') || lower.contains('motor') || lower.contains('dağıtım') || lower.contains('paket') || lower.contains('teslimat')) {
      return Icons.two_wheeler_rounded;
    }
    if (lower.contains('depo') || lower.contains('lojistik') || lower.contains('taşıma') || lower.contains('yükleme') || lower.contains('sayım') || lower.contains('koli') || lower.contains('sevkiyat')) {
      return Icons.inventory_2_rounded;
    }
    if (lower.contains('temizlik') || lower.contains('hijyen') || lower.contains('kat görevli')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('satış') || lower.contains('mağaza') || lower.contains('kasiyer') || lower.contains('reyon') || lower.contains('stand') || lower.contains('tanıtım')) {
      return Icons.storefront_rounded;
    }
    if (lower.contains('etkinlik') || lower.contains('fuar') || lower.contains('organizasyon') || lower.contains('host')) {
      return Icons.celebration_rounded;
    }
    if (lower.contains('inşaat') || lower.contains('tadilat') || lower.contains('montaj') || lower.contains('usta')) {
      return Icons.construction_rounded;
    }
    if (lower.contains('güvenlik') || lower.contains('danışma')) {
      return Icons.security_rounded;
    }
    return Icons.work_outline_rounded;
  }
}
