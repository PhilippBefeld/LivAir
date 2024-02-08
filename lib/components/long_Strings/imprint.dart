
import 'package:flutter/cupertino.dart';

class ImprintText extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Contact Info",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("Agnes-Pockels-Bogen 1\n80992 München\nDeutschland",style: TextStyle(fontSize: 16)),
            const Text("Telefone: +49 (0) 89 / 2000 437 00\nE-Mail: www.livair.io",style: TextStyle(fontSize: 16)),
            const Text("Geschäftsführer: Martin Waltl, Rudolf Waltl",style: TextStyle(fontSize: 16)),
            const Text("USt-IdNr: DE360338631\nHandelsregisternummer: HRB 281464",style: TextStyle(fontSize: 16)),
            const Text("Alternative Streitbeilegung:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("Die Europäische Kommission stellt eine Plattform für die außergerichtliche Online-Streitbeilegung (OS-Plattform) bereit, die unter https://ec.europa.eu/odr zu finden ist.",style: TextStyle(fontSize: 16)),
            const Text("Wir sind seit dem 08.06.2018 Mitglied der Initiative 'FairCommerce'. Mehr Informationen dazu findest du unter www.fair-commerce.de.",style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }}