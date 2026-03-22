
import 'package:flutter/material.dart';
import 'package:alagahub/utils/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {
      'q': 'Paano mag-record ng sintomas?',
      'a':
          'Pumunta sa tab na "Konsultasyon" tapos pindutin ang + button. Piliin ang iyong mga sintomas, ilagay ang temperatura at antas ng sakit, tapos pindutin ang Susunod.',
    },
    {
      'q': 'Paano humiling ng gamot?',
      'a':
          'Pumunta sa tab na "Gamot" tapos pindutin ang "Bagong Hiling". Hanapin ang gamot, piliin ang dami, at piliin kung kukuhanin mo o ipapadala sa bahay.',
    },
    {
      'q': 'Gumagana ba ang app nang walang internet?',
      'a':
          'Oo! Ang lahat ng pangunahing features ay gumagana offline. Ang iyong data ay awtomatikong mag-si-sync kapag may koneksyon na.',
    },
    {
      'q': 'Paano magpadala ng SMS sa health center?',
      'a':
          'Sa Messages tab, i-paste ang iyong consultation o medicine summary tapos pindutin ang send button. Magbubukas ang iyong native SMS app para kumpirmahin.',
    },
    {
      'q': 'Paano baguhin ang aking impormasyon?',
      'a':
          'Pumunta sa Account tab, tapos pindutin ang bawat seksyon para i-edit ang iyong personal na impormasyon.',
    },
    {
      'q': 'Hindi ko matandaan ang aking Patient ID. Saan ko makikita?',
      'a':
          'Nasa iyong Home dashboard ang Patient ID sa green na card sa itaas. Maaari mo itong i-copy sa pamamagitan ng pagpindot sa copy icon.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tulong / Help'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 36),
              const SizedBox(height: 10),
              const Text('Kailangan ng Tulong?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Narito kami para tulungan ka.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Mga Madalas na Tanong',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ..._faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.question_mark_rounded,
                        color: AppTheme.primary, size: 16),
                  ),
                  title: Text(faq['q']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  children: [
                    Text(faq['a']!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.6)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.phone_rounded, color: AppTheme.accent, size: 18),
                  SizedBox(width: 8),
                  Text('Makipag-ugnayan',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent)),
                ]),
                SizedBox(height: 8),
                Text(
                  'Para sa karagdagang tulong, makipag-ugnayan sa inyong lokal na health center.',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
