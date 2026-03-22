import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alagahub/utils/app_theme.dart';
import 'package:alagahub/utils/lang.dart';
import 'package:alagahub/widgets/app_bar_widget.dart';
import 'package:alagahub/widgets/reg_progress_bar.dart';
import 'package:alagahub/services/registration_provider.dart';
import 'package:alagahub/screens/auth/registration/reg_step3_screen.dart';

const Map<String, Map<String, Map<String, List<String>>>> phData = {
  'NCR': {
    'Metro Manila': {
      'Manila': ['Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4', 'Barangay 5', 'Barangay 6', 'Barangay 7', 'Barangay 8', 'Barangay 9', 'Barangay 10', 'Barangay 11', 'Barangay 12', 'Barangay 13', 'Barangay 14', 'Barangay 15', 'Barangay 16', 'Barangay 17', 'Barangay 18', 'Barangay 19', 'Barangay 20', 'Barangay 21', 'Barangay 22', 'Barangay 23', 'Barangay 24', 'Barangay 25', 'Barangay 26', 'Barangay 27', 'Barangay 28', 'Barangay 29', 'Barangay 30', 'Barangay 31', 'Barangay 32', 'Barangay 33', 'Barangay 34', 'Barangay 35', 'Barangay 36', 'Barangay 37', 'Barangay 38', 'Barangay 39', 'Barangay 40', 'Barangay 41', 'Barangay 42', 'Barangay 43', 'Barangay 44', 'Barangay 45', 'Barangay 46', 'Barangay 47', 'Barangay 48', 'Barangay 49', 'Barangay 50', 'Barangay 51', 'Barangay 52', 'Barangay 53', 'Barangay 54', 'Barangay 55', 'Barangay 56', 'Barangay 57', 'Barangay 58', 'Barangay 59', 'Barangay 60', 'Barangay 61', 'Barangay 62', 'Barangay 63', 'Barangay 64', 'Barangay 65', 'Barangay 66', 'Barangay 67', 'Barangay 68', 'Barangay 69', 'Barangay 70', 'Barangay 71', 'Barangay 72', 'Barangay 73', 'Barangay 74', 'Barangay 75', 'Barangay 76', 'Barangay 77', 'Barangay 78', 'Barangay 79', 'Barangay 80', 'Barangay 81', 'Barangay 82', 'Barangay 83', 'Barangay 84', 'Barangay 85', 'Barangay 86', 'Barangay 87', 'Barangay 88', 'Barangay 89', 'Barangay 90', 'Barangay 91', 'Barangay 92', 'Barangay 93', 'Barangay 94', 'Barangay 95', 'Barangay 96', 'Barangay 97', 'Barangay 98', 'Barangay 99', 'Barangay 100', 'Barangay 101', 'Barangay 102', 'Barangay 103', 'Barangay 104', 'Barangay 105', 'Barangay 106', 'Barangay 107', 'Barangay 108', 'Barangay 109', 'Barangay 110'],
      'Quezon City': ['Alicia', 'Amihan', 'Apolonio Samson', 'Arana', 'Ardent', 'Bagbag', 'Bagong Silangan', 'Bagong Pag-asa', 'Bagumbayan', 'Bagumbuhay', 'Bahay Toro', 'Balingasa', 'Balumbato', 'Batasan Hills', 'Botocan', 'Camarin', 'Capri', 'Central', 'Claro', 'Commonwealth', 'Cubao', 'Culiat', 'Dagat-Dagatan', 'Del Monte', 'Dioquino Zobel', 'Diliman', 'Don Manuel', 'Dona Aurora', 'Dona Imelda', 'Dona Josefa', 'Duyan-Duyan', 'E. Rodriguez', 'East Kamias', 'Escopa I', 'Escopa II', 'Escopa III', 'Escopa IV', 'Fairview', 'Greater Lagro', 'Gulod', 'Holy Spirit', 'Horseshoe', 'Immaculate Concepcion', 'Kaligayahan', 'Kalusugan', 'Kamuning', 'Katipunan', 'Kaunlaran', 'Kristong Hari', 'Krus na Ligas', 'Laging Handa', 'Libis', 'Lourdes', 'Loyola Heights', 'Luzon', 'Maharlika', 'Malaya', 'Manresa', 'Mangga', 'Mariana', 'Mariblo', 'Marilag', 'Masagana', 'Masambong', 'Matandang Balara', 'Milagrosa', 'Nagkaisang Nayon', 'New Era', 'Novaliches Proper', 'Nayong Kanluran', 'Obrero', 'Old Capitol Site', 'Paang Bundok', 'Pag-ibig sa Nayon', 'Paligsahan', 'Paltok', 'Pansol', 'Paraiso', 'Pasong Putik', 'Pasong Tamo', 'Payatas', 'Phil-Am', 'Pinagkaisahan', 'Pinyahan', 'Project 4', 'Project 6', 'Project 7', 'Project 8', 'Quirino 2-A', 'Quirino 2-B', 'Quirino 2-C', 'Quirino 3-A', 'Ramon Magsaysay', 'Roxas', 'Sacred Heart', 'Saint Ignatius', 'Saint Peter', 'Salvacion', 'San Agustin', 'San Antonio', 'San Bartolome', 'San Isidro', 'San Isidro Labrador', 'San Jose', 'San Martin de Porres', 'San Roque', 'San Vicente', 'Santa Cruz', 'Santa Lucia', 'Santa Monica', 'Santo Cristo', 'Santo Domingo', 'Santo Nino', 'Santol', 'Sauyo', 'Siena', 'Sikatuna Village', 'Silangan', 'Socorro', 'South Triangle', 'Tagumpay', 'Tandang Sora', 'Tatalon', 'Teachers Village East', 'Teachers Village West', 'U.P. Campus', 'Ugong Norte', 'Unang Sigaw', 'UP Village', 'Valencia', 'Vasra', 'Veterans Village', 'Villa Maria Clara', 'West Kamias', 'West Triangle', 'White Plains'],
      'Caloocan': ['Bagong Barrio', 'Camarin', 'Grace Park', 'Kaunlaran', 'Maypajo', 'Sangandaan'],
      'Las Piñas': ['Almanza Uno', 'Almanza Dos', 'BF Homes', 'Pamplona Tres', 'Talon Uno'],
      'Makati': ['Bel-Air', 'Forbes Park', 'Guadalupe Nuevo', 'Poblacion', 'Rockwell', 'San Lorenzo', 'Urdaneta'],
      'Malabon': ['Acacia', 'Catmon', 'Hulong Duhat', 'Panghulo', 'Potrero', 'Tañong'],
      'Mandaluyong': ['Addition Hills', 'Barangka', 'Highway Hills', 'Mauwak', 'Plainview', 'Wack-Wack'],
      'Marikina': ['Calumpang', 'Concepcion Uno', 'Nangka', 'Parang', 'San Roque', 'Tumana'],
      'Muntinlupa': ['Alabang', 'Ayala Alabang', 'Buli', 'Cupang', 'Poblacion', 'Putatan', 'Sucat', 'Tunasan'],
      'Navotas': ['Bangculasi', 'Daanghari', 'North Bay Boulevard', 'San Roque', 'Tangos'],
      'Parañaque': ['BF Homes', 'Don Bosco', 'Marcelo Green', 'Moonwalk', 'San Martin de Porres', 'Santo Niño'],
      'Pasay': ['Baclaran', 'Maricaban', 'Pasay Poblacion', 'San Isidro', 'Victoria Valley'],
      'Pasig': ['Bagong Ilog', 'Bagong Katipunan', 'Kapitolyo', 'Manggahan', 'Ortigas', 'Rosario', 'San Antonio', 'Ugong'],
      'San Juan': ['Addition Hills', 'Balong-Bato', 'Ermitaño', 'Kabayanan', 'Pasadena', 'Rivera', 'Salapan'],
      'Taguig': ['Bagumbayan', 'Fort Bonifacio', 'Hagonoy', 'Ligid-Tipas', 'Pinagsama', 'Signal Village', 'Ususan', 'Western Bicutan'],
      'Valenzuela': ['Arkong Bato', 'Balangkas', 'Dalandanan', 'Gen. T. de Leon', 'Isla', 'Lawang Bato', 'Malinta', 'Mapulang Lupa', 'Paso de Blas', 'Punturin'],
      'Pateros': ['Aguho', 'Magtanggol', 'Poblacion', 'San Pedro', 'Santa Ana', 'Santo Rosario', 'Tabacalera'],
    },
  },
  'Region I': {
    'Ilocos Norte': {
      'Laoag City': ['Barangay 1', 'Barangay 2', 'Barangay 3', 'San Lorenzo', 'San Nicolas', 'San Pedro', 'San Vicente'],
      'Batac': ['Ablan', 'Baay', 'Balindoc', 'Capitaan', 'Colo', 'Quiling Norte'],
      'Paoay': ['Bacsil', 'Cayus', 'Dodan', 'Laoa', 'Malasin', 'Pambuhan', 'Polong'],
    },
    'Ilocos Sur': {
      'Vigan City': ['Barangay I', 'Barangay II', 'Barangay III', 'Barangay IV', 'Barangay V', 'Barangay VI', 'Barangay VII', 'Barangay VIII', 'Barangay IX'],
      'Candon City': ['Bagani', 'Calaoaan', 'Darapidap', 'Langlangca', 'Paras', 'San Nicolas', 'San Pedro', 'San Quintin'],
    },
    'La Union': {
      'San Fernando City': ['Abut', 'Bangaoilan East', 'Bangaoilan West', 'Catbangen', 'Dalumpinas', 'Madayegdeg', 'Pagdaraoan', 'Poro', 'Tanqui'],
      'Agoo': ['Calabiao', 'Consolacion', 'Macalva', 'San Agustin', 'San Nicolas', 'Sta. Barbara'],
    },
    'Pangasinan': {
      'Dagupan City': ['Bacayao Norte', 'Bacayao Sur', 'Barangay I', 'Barangay II', 'Barangay III', 'Bonuan Binloc', 'Bonuan Boquig', 'Bonuan Gueset', 'Calmay', 'Lomboy', 'Pantal', 'Salisay', 'Tebeng'],
      'San Carlos City': ['Abanon', 'Anando', 'Antipangol', 'Aponit', 'Balaya', 'Bautista', 'Binating', 'Bued'],
      'Urdaneta City': ['Anonas', 'Cabaruan', 'Cabuloan', 'Camantiles', 'Casantaan', 'Cayambanan', 'Consolacion'],
    },
  },
  'Region III': {
    'Bulacan': {
      'Malolos City': ['Anilao', 'Atlag', 'Babatnin', 'Bagna', 'Balingasa', 'Balite', 'Bangkal', 'Caingin', 'Calero', 'Caltagan', 'Cofradia', 'Dakila'],
      'Meycauayan City': ['Bagbaguin', 'Bahay Pare', 'Bancal', 'Banga', 'Bingunan', 'Bisig', 'Calvario', 'Camalig', 'Gasak'],
      'San Jose del Monte City': ['Assumption', 'Bagong Buhay', 'Citrus', 'Dulong Bayan', 'Fatima', 'Graceville', 'Gumaoc'],
    },
    'Pampanga': {
      'Angeles City': ['Agapito del Rosario', 'Amsic', 'Anunas', 'Balibago', 'Capaya', 'Claro M. Recto', 'Cuayan', 'Cutcut', 'Cutud'],
      'San Fernando City': ['Alasas', 'Baliti', 'Bulaon', 'Calulut', 'Del Carmen', 'Del Pilar', 'Del Rosario', 'Dolores'],
    },
    'Zambales': {
      'Olongapo City': ['Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4', 'Barangay 5', 'Barangay 6', 'Barangay 7', 'Barangay 8', 'Barangay 9', 'Barangay 10'],
      'Iba': ['Amungan', 'Bangantalinga', 'Dirita-Baloguen', 'Lipay', 'Palanginan', 'San Agustin', 'Santiago'],
    },
  },
  'Region IV-A': {
    'Batangas': {
      'Batangas City': ['Balagtas', 'Bilogo', 'Bolbok', 'Bukal', 'Calicanto', 'Cuta', 'Dela Paz', 'Kumintang Ibaba', 'Kumintang Ilaya', 'Libjo', 'Liponpon', 'Maapas', 'Pagkilatan', 'Pallocan Kanluran'],
      'Lipa City': ['Anilao-Labac', 'Antipolo del Norte', 'Antipolo del Sur', 'Bagong Pook', 'Balintawak', 'Banaybanay', 'Banjo East', 'Banjo West', 'Bolbok'],
      'Tanauan City': ['Altura Bata', 'Altura Matanda', 'Altura South', 'Ambulong', 'Bagbag', 'Bagumbayan', 'Balele'],
    },
    'Cavite': {
      'Bacoor City': ['Alima', 'Aniban I', 'Aniban II', 'Aniban III', 'Aniban IV', 'Aniban V', 'Bayanan', 'Camposanto', 'Dagatan'],
      'Cavite City': ['Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4', 'Barangay 5', 'Barangay 6', 'Barangay 7', 'Barangay 8', 'Barangay 9', 'Barangay 10'],
      'Dasmarinas City': ['Burol I', 'Burol II', 'Burol III', 'Salawag', 'Salitran I', 'Salitran II', 'Sampaloc I', 'Zone I', 'Zone II', 'Zone III', 'Zone IV'],
    },
    'Laguna': {
      'Calamba City': ['Bagong Kalsada', 'Banadero', 'Banlic', 'Barandal', 'Batino', 'Burol', 'Canlubang', 'Halang', 'Laguerta', 'Lawa', 'Lecheria'],
      'San Pablo City': ['Barangay I', 'Barangay II', 'Barangay III', 'Barangay IV', 'Barangay V', 'Barangay VI', 'Concepcion', 'Del Remedio', 'San Buenaventura'],
      'Santa Rosa City': ['Balibago', 'Caingin', 'Dila', 'Dita', 'Don Jose', 'Ibaba', 'Kanluran', 'Labas', 'Macabling', 'Malitlit', 'Malusak'],
    },
    'Rizal': {
      'Antipolo City': ['Bagong Nayon', 'Beverly Hills', 'Calawis', 'Cupang', 'Dalig', 'Del Montes', 'Inarawan', 'Mambugan', 'Mayamot', 'Munting Dilaw'],
      'Cainta': ['Bagong Nayon', 'Bago-Bago', 'Cainta Poblacion', 'Dela Paz', 'San Andres', 'San Juan', 'Santa Rosa'],
      'Taytay': ['Dolores', 'Muzon', 'San Isidro', 'San Juan', 'Santa Ana'],
    },
  },
  'Region VII': {
    'Cebu': {
      'Cebu City': ['Apas', 'Babag', 'Bacayan', 'Banilad', 'Basak Pardo', 'Basak San Nicolas', 'Binaliw', 'Bonbon', 'Budlaan', 'Busay', 'Calamba', 'Cambinocot', 'Capitol Site', 'Carreta', 'Central Poblacion', 'Cogon Pardo', 'Cogon Ramos', 'Day-as', 'Duljo', 'Ermita', 'Guadalupe', 'Guba', 'Hippodromo', 'Inayawan', 'Kalubihan', 'Kalunasan', 'Kamagayan', 'Kasambagan', 'Kinasang-an', 'Labangon', 'Lahug', 'Lorega', 'Lusaran', 'Luz', 'Mabini', 'Mabolo'],
      'Mandaue City': ['Alang-alang', 'Bakilid', 'Banilad', 'Basak', 'Cambaro', 'Canduman', 'Casili', 'Casuntingan', 'Centro', 'Cubacub', 'Guizo', 'Ibabao-Estancia', 'Jagobiao', 'Labogon', 'Looc', 'Maguikay', 'Mahiga', 'Mandaue Pob.', 'Mantuyong', 'Mengga'],
      'Lapu-Lapu City': ['Agus', 'Babag', 'Bankal', 'Baring', 'Basak', 'Buaya', 'Gun-ob', 'Ibo', 'Looc', 'Mactan', 'Maribago', 'Marigondon', 'Pajac', 'Pajo', 'Poblacion', 'Punta Engaño', 'Pusok', 'Subabasbas', 'Talima', 'Tingo', 'Tungasan'],
    },
    'Bohol': {
      'Tagbilaran City': ['Bool', 'Booy', 'Cabawan', 'Cogon', 'Dao', 'Dampas', 'Manga', 'Mansasa', 'Poblacion I', 'Poblacion II', 'Poblacion III', 'San Isidro', 'Taloto', 'Tiptip', 'Ubujan'],
    },
  },
  'Region XI': {
    'Davao del Sur': {
      'Davao City': ['Agdao', 'Alambre', 'Alejandra Navarro', 'Alfonso Angliongto Sr.', 'Angalan', 'Atan-awe', 'Baganihan', 'Bago Aplaya', 'Bago Gallera', 'Bago Oshiro', 'Baguio', 'Balengaeng', 'Baliok', 'Bangkas Heights', 'Baracatan', 'Barangay 1-A', 'Barangay 2-A', 'Barangay 3-A', 'Barangay 4-A', 'Barangay 5-A', 'Barangay 6-A', 'Barangay 7-A', 'Barangay 8-A', 'Barangay 9-A', 'Barangay 10-A', 'Barangay 11-B', 'Barangay 12-B', 'Barangay 13-B', 'Barangay 14-B', 'Barangay 15-B', 'Barangay 16-B', 'Barangay 17-B', 'Barangay 18-B', 'Barangay 19-B', 'Barangay 20-B', 'Barangay 21-C', 'Barangay 22-C', 'Barangay 23-C', 'Barangay 24-C', 'Barangay 25-C', 'Barangay 26-C', 'Barangay 27-C', 'Barangay 28-C', 'Barangay 29-C', 'Barangay 30-C', 'Barangay 31-D', 'Barangay 32-D', 'Barangay 33-D', 'Barangay 34-D', 'Barangay 35-D', 'Barangay 36-D', 'Barangay 37-D', 'Barangay 38-D', 'Barangay 39-D', 'Barangay 40-D'],
    },
  },
  'CAR': {
    'Benguet': {
      'Baguio City': ['Abanao-Zandueta-Kayong-Chugum-Otek', 'Absentee Voters Precinct', 'Alfonso Tabora', 'Ambiong', 'Andres Bonifacio', 'Asin Road', 'Aurora Hill Proper', 'Bakakeng Central', 'Bakakeng Norte', 'Bayan Park East', 'Bayan Park Village', 'Bayan Park West', 'BGH Compound', 'Cabinet Hill-Teacher\'s Camp', 'Camp Allen', 'Campo Filipino'],
    },
  },
};

List<String> _getProvinces(String region) {
  final m = phData[region];
  if (m == null) return [];
  return m.keys.toList()..sort();
}

List<String> _getCities(String region, String province) {
  final m = phData[region]?[province];
  if (m == null) return [];
  return m.keys.toList()..sort();
}

List<String> _getBarangays(String region, String province, String city) {
  return phData[region]?[province]?[city] ?? [];
}

class RegStep2Screen extends ConsumerStatefulWidget {
  final String role;
  const RegStep2Screen({super.key, this.role = 'patient'});
  @override
  ConsumerState<RegStep2Screen> createState() => _RegStep2ScreenState();
}

class _RegStep2ScreenState extends ConsumerState<RegStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _house;
  String _region = '';
  String _province = '';
  String _city = '';
  String _barangay = '';

  final _regions = [
    'NCR','Region I','Region II','Region III','Region IV-A','Region IV-B',
    'Region V','Region VI','Region VII','Region VIII','Region IX','Region X',
    'Region XI','Region XII','Region XIII','BARMM','CAR','NIR',
  ];

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationProvider);
    _house = TextEditingController(text: d.houseStreet);
    _region = d.region;
    _province = d.province;
    _city = d.city;
    _barangay = d.barangay;
  }

  @override
  void dispose() { _house.dispose(); super.dispose(); }

  void _save() {
    ref.read(registrationProvider.notifier).update((d) => d.copyWith(
      houseStreet: _house.text.trim(),
      region: _region,
      province: _province,
      city: _city,
      barangay: _barangay,
    ));
  }

  void _next() {
    final s = S(ref.read(langProvider));
    if (!_formKey.currentState!.validate()) return;
    if (_region.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.selectRegion), backgroundColor: AppTheme.error));
      return;
    }
    _save();
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => RegStep3Screen(role: widget.role)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(langProvider));
    final provinces = _getProvinces(_region);
    final cities = _getCities(_region, _province);
    final barangays = _getBarangays(_region, _province, _city);

    return Scaffold(
      appBar: buildAppBar(context, s.createAccountTitle),
      body: Column(children: [
        const RegProgressBar(step: 2, total: 4),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(key: _formKey, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.step2Title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),

              // Region first
              DropdownButtonFormField<String>(
                initialValue: _region.isEmpty ? null : _region,
                decoration: InputDecoration(labelText: '${s.region} *'),
                items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() {
                  _region = v ?? '';
                  _province = ''; _city = ''; _barangay = '';
                }),
                validator: (_) => _region.isEmpty ? s.selectRegion : null,
              ),
              const SizedBox(height: 16),

              // Province (filtered by region)
              DropdownButtonFormField<String>(
                initialValue: _province.isEmpty || !provinces.contains(_province) ? null : _province,
                decoration: InputDecoration(
                  labelText: s.province,
                  enabled: _region.isNotEmpty,
                ),
                items: provinces.isEmpty
                    ? [DropdownMenuItem(value: '', child: Text(s.none))]
                    : provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: _region.isEmpty ? null : (v) => setState(() {
                  _province = v ?? '';
                  _city = ''; _barangay = '';
                }),
              ),
              const SizedBox(height: 16),

              // City (filtered by province)
              DropdownButtonFormField<String>(
                initialValue: _city.isEmpty || !cities.contains(_city) ? null : _city,
                decoration: InputDecoration(
                  labelText: '${s.cityMunicipality} *',
                  enabled: _province.isNotEmpty,
                  helperText: _province.isEmpty ? (s.isEn ? 'Select a province first' : 'Pumili ng lalawigan muna') : null,
                ),
                items: cities.isEmpty
                    ? [DropdownMenuItem(value: '', child: Text(s.isEn ? 'Select province first' : 'Pumili ng lalawigan muna'))]
                    : cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: _province.isEmpty ? null : (v) => setState(() {
                  _city = v ?? '';
                  _barangay = '';
                }),
                validator: (_) => _city.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 16),

              // Barangay (filtered by city)
              DropdownButtonFormField<String>(
                initialValue: _barangay.isEmpty || !barangays.contains(_barangay) ? null : _barangay,
                decoration: InputDecoration(
                  labelText: '${s.barangay} *',
                  enabled: _city.isNotEmpty,
                  helperText: _city.isEmpty ? (s.isEn ? 'Select a city first' : 'Pumili ng lungsod muna') : null,
                ),
                items: barangays.isEmpty
                    ? [DropdownMenuItem(value: '', child: Text(s.isEn ? 'Select city first' : 'Pumili ng lungsod muna'))]
                    : barangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: _city.isEmpty ? null : (v) => setState(() => _barangay = v ?? ''),
                validator: (_) => _barangay.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 16),

              // House/Street (free text)
              TextFormField(
                controller: _house,
                decoration: InputDecoration(labelText: '${s.houseStreet} *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v?.isEmpty ?? true) ? s.required : null,
              ),
              const SizedBox(height: 40),

              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { _save(); Navigator.pop(context); },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(s.back),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                    onPressed: _next, child: Text('${s.next} →'))),
              ]),
              const SizedBox(height: 24),
            ],
          )),
        )),
      ]),
    );
  }
}
