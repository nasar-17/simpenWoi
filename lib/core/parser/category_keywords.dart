import '../constants/category_catalog.dart';
import '../constants/transaction_values.dart';

class CategoryKeywordGroup {
  const CategoryKeywordGroup({
    required this.categoryId,
    required this.type,
    required this.keywords,
  });

  final int categoryId;
  final String type;
  final List<String> keywords;
}

const List<CategoryKeywordGroup> categoryKeywords = <CategoryKeywordGroup>[
  CategoryKeywordGroup(
    categoryId: CategoryIds.makan,
    type: TransactionType.expense,
    keywords: <String>[
      'makan',
      'bakso',
      'kopi',
      'nasi',
      'mie',
      'ayam',
      'sate',
      'resto',
      'restoran',
      'warung',
      'kafe',
      'cafe',
      'minum',
      'jajan',
      'sarapan',
      'gofood',
      'grabfood',
    ],
  ),
  CategoryKeywordGroup(
    categoryId: CategoryIds.transport,
    type: TransactionType.expense,
    keywords: <String>[
      'ojek',
      'gojek',
      'grab',
      'bensin',
      'parkir',
      'tol',
      'transport',
      'angkot',
      'bus',
      'kereta',
      'tiket',
      'bengkel',
      'servis',
    ],
  ),
  CategoryKeywordGroup(
    categoryId: CategoryIds.belanja,
    type: TransactionType.expense,
    keywords: <String>[
      'belanja',
      'supermarket',
      'indomaret',
      'alfamart',
      'shopee',
      'tokopedia',
      'pasar',
      'baju',
      'sepatu',
      'beli',
    ],
  ),
  CategoryKeywordGroup(
    categoryId: CategoryIds.tagihan,
    type: TransactionType.expense,
    keywords: <String>[
      'listrik',
      'pulsa',
      'wifi',
      'internet',
      'air',
      'pdam',
      'token',
      'tagihan',
      'cicilan',
      'kos',
      'sewa',
    ],
  ),
  CategoryKeywordGroup(
    categoryId: CategoryIds.hiburan,
    type: TransactionType.expense,
    keywords: <String>[
      'nonton',
      'bioskop',
      'game',
      'spotify',
      'netflix',
      'liburan',
      'hiburan',
      'konser',
    ],
  ),
  CategoryKeywordGroup(
    categoryId: CategoryIds.kesehatan,
    type: TransactionType.expense,
    keywords: <String>[
      'obat',
      'dokter',
      'rumah sakit',
      'klinik',
      'vitamin',
      'kesehatan',
      'apotek',
    ],
  ),
  CategoryKeywordGroup(
    categoryId: CategoryIds.gaji,
    type: TransactionType.income,
    keywords: <String>['gaji', 'upah', 'honor'],
  ),
];

const List<String> incomeKeywords = <String>[
  'gaji',
  'terima',
  'dapat',
  'masuk',
  'transfer masuk',
];
