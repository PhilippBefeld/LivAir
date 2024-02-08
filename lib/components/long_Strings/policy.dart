import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PolicyText extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("\nDer Verantwortliche im Sinne der Datenschutzgesetze, insbesondere der EU-Datenschutzgrundverordnung (DSGVO), ist:",style: TextStyle(fontSize: 16),),
            const Text("Martin Waltl",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("\nDeine Rechte als betroffene Person", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),),
            const Text("\nDu kannst die folgenden Rechte jederzeit über die Kontaktdaten unseres Datenschutzbeauftragten ausüben:\n",style: TextStyle(fontSize: 16),),
            const Text("\u2022 Informationen über deine bei uns gespeicherten Daten und deren Verarbeitung (Art. 15 DSGVO),",style: TextStyle(fontSize: 16),),
            const Text("\u2022 die Berichtigung unrichtiger personenbezogener Daten (Art. 16 DSGVO),",style: TextStyle(fontSize: 16),),
            const Text("\u2022 die Löschung deiner bei uns gespeicherten Daten (Art. 17 DSGVO),",style: TextStyle(fontSize: 16),),
            const Text("\u2022 Einschränkung der Datenverarbeitung, wenn wir deine Daten aufgrund von gesetzlichen Verpflichtungen noch nicht löschen dürfen (Art. 18 DSGVO),",style: TextStyle(fontSize: 16),),
            const Text("\u2022 Einspruch gegen die Verarbeitung deiner Daten durch uns (Art. 21 DSGVO) und",style: TextStyle(fontSize: 16),),
            const Text("\u2022 Datenübertragbarkeit, sofern du in die Datenverarbeitung eingewilligt hast oder einen Vertrag mit uns geschlossen hast (Art. 20 DSGVO).",style: TextStyle(fontSize: 16),),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\nWenn du uns eine Einwilligung erteilt hast, kannst du diese jederzeit mit Wirkung für die Zukunft widerrufen. Du kannst dich jederzeit bei einer Aufsichtsbehörde beschweren, z.B. bei der zuständigen Aufsichtsbehörde in dem Bundesland, in dem du wohnst, oder bei der für uns zuständigen Behörde als verantwortliche Stelle. Eine Liste der Aufsichtsbehörden (für den nicht-öffentlichen Bereich) mit Adresse findest du unter: ",style: TextStyle(fontSize: 16,color: Colors.black)),
                      TextSpan(
                          text: "https://www.bfdi.bund.de/DE/Service/Anschriften/Laender/Laender-node.html",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Color(0xff0099F0),),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://www.bfdi.bund.de/DE/Service/Anschriften/Laender/Laender-node.html");
                              await launchUrl(
                                uri,
                              );
                          }
                      ),
                    ]
                )
            ),
            const Text("\nErfassung allgemeiner Informationen, wenn du unsere Website besuchst",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),),
            const Text("\nArt und Zweck der Verarbeitung:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("\nWenn du auf unsere Website zugreifst, d.h. wenn du dich nicht registrierst oder anderweitig Informationen übermittelst, werden automatisch Informationen allgemeiner Art erfasst. Zu diesen Informationen (Server-Log-Dateien) gehören zum Beispiel die Art des Webbrowsers, das verwendete Betriebssystem, der Domainname deines Internetanbieters, deine IP-Adresse und Ähnliches.",style: TextStyle(fontSize: 16),),
            const Text("\nSie werden insbesondere für die folgenden Zwecke verarbeitet:",style: TextStyle(fontSize: 16),),
            const Text("\n\u2022 Sicherstellung einer reibungslosen Verbindung der Website,",style: TextStyle(fontSize: 16),),
            const Text("\u2022 Sicherstellung einer reibungslosen Nutzung unserer Website,",style: TextStyle(fontSize: 16),),
            const Text("\u2022 die Bewertung der Sicherheit und Stabilität des Systems",style: TextStyle(fontSize: 16),),
            const Text("\u2022 und für die Optimierung unserer Website.",style: TextStyle(fontSize: 16),),
            const Text("\nWir nutzen deine Daten nicht, um Rückschlüsse auf deine Person zu ziehen. Informationen dieser Art werden von uns ggf. anonym statistisch ausgewertet, um unseren Internetauftritt und die dahinterstehende Technik zu optimieren.",style: TextStyle(fontSize: 16),),
            const Text("\nRechtsgrundlage und berechtigtes Interesse:",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),),
            const Text("\nDie Verarbeitung erfolgt in Übereinstimmung mit Art. 6 Abs.. 1 lit. f DSGVO auf der Grundlage unseres berechtigten Interesses an der Verbesserung der Stabilität und Funktionalität unserer Website.",style: TextStyle(fontSize: 16),),
            const Text("\nBegünstigter:",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),),
            const Text("\nEmpfänger der Daten können technische Dienstleister sein, die als Auftragsverarbeiter für den Betrieb und die Wartung unserer Website fungieren.",style: TextStyle(fontSize: 16),),
            const Text("\nLagerzeit:",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),),
            const Text("\nDie Daten werden gelöscht, sobald sie für den Zweck, für den sie erhoben wurden, nicht mehr benötigt werden. Dies ist in der Regel bei Daten, die zur Bereitstellung der Website verwendet werden, der Fall, wenn die jeweilige Sitzung beendet ist.",style: TextStyle(fontSize: 16),),
            const Text("\nVorschrift obligatorisch oder erforderlich:",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),),
            const Text("\nDie Bereitstellung der vorgenannten personenbezogenen Daten ist nicht gesetzlich oder vertraglich vorgeschrieben. Ohne die IP-Adresse ist der Service und die Funktionalität unserer Website jedoch nicht gewährleistet. Darüber hinaus können einzelne Dienste und Leistungen nicht oder nur eingeschränkt zur Verfügung stehen. Aus diesem Grund ist ein Widerspruch ausgeschlossen.",style: TextStyle(fontSize: 16),),
            const Text("\nCookies",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),),
            const Text("\nWie viele andere Websites auch, verwenden wir sogenannte 'Cookies'. Cookies sind kleine Textdateien, die auf deinem Endgerät (Laptop, Tablet, Smartphone oder ähnliches) gespeichert werden, wenn du unsere Website besuchst. Du kannst einzelne Cookies oder den gesamten Cookie-Bestand löschen. Außerdem erhältst du Informationen und Anweisungen, wie du diese Cookies löschen oder ihre Speicherung im Voraus blockieren kannst. Je nach Anbieter deines Browsers findest du die nötigen Informationen unter den folgenden Links:",style: TextStyle(fontSize: 16),),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\n\u2022 Mozilla Firefox: ",style: TextStyle(fontSize: 16,color: Colors.black)),
                      TextSpan(
                          text: "https://support.mozilla.org/de/kb/cookies-loeschen-daten-von-websites-entfernen",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://support.mozilla.org/de/kb/cookies-loeschen-daten-von-websites-entfernen");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                    ]
                )
            ),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\u2022 Internet Explorer: ",style: TextStyle(fontSize: 16,color: Colors.black)),
                      TextSpan(
                          text: "https://support.microsoft.com/de-de/help/17442/windows-internet-explorer-delete-manage-cookies",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://support.microsoft.com/de-de/help/17442/windows-internet-explorer-delete-manage-cookies");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                    ]
                )
            ),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\u2022 Google Chrome: ",style: TextStyle(fontSize: 16,color: Colors.black)),
                      TextSpan(
                          text: "https://support.google.com/accounts/answer/61416?hl=de",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://support.google.com/accounts/answer/61416?hl=de");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                    ]
                )
            ),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\u2022 Opera: ",style: TextStyle(fontSize: 16,color: Colors.black)),
                      TextSpan(
                          text: "http://www.opera.com/de/help",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("http://www.opera.com/de/help");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                    ]
                )
            ),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\u2022 Safari: ",style: TextStyle(fontSize: 16,color: Colors.black)),
                      TextSpan(
                          text: "https://support.apple.com/kb/PH17191?locale=de_DE&viewlocale=de_DE",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://support.apple.com/kb/PH17191?locale=de_DE&viewlocale=de_DE");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                    ]
                )
            ),
            const Text("\nSpeicherdauer und verwendete Cookies:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("\nSofern du uns die Verwendung von Cookies durch deine Browsereinstellungen oder deine Zustimmung erlaubst, können die folgenden Cookies auf unseren Websites verwendet werden:",style: TextStyle(fontSize: 16),),
            const Text("\nTechnisch notwendige Cookies",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),),
            const Text("\nArt und Zweck der Verarbeitung:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("\nWir verwenden Cookies, um unsere Website benutzerfreundlicher zu gestalten. Einige Elemente unserer Website erfordern, dass der aufrufende Browser auch nach einem Seitenwechsel identifiziert werden kann. Der Zweck der Verwendung technisch notwendiger Cookies ist es, die Nutzung von Websites für die Nutzer/innen zu vereinfachen. Einige Funktionen unserer Website können ohne den Einsatz von Cookies nicht angeboten werden. Für diese ist es notwendig, dass der Browser auch nach einem Seitenwechsel wiedererkannt wird. Wir benötigen Cookies für die folgenden Anwendungen:",style: TextStyle(fontSize: 16),),
            const Text("\nRechtsgrundlage und berechtigtes Interesse:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("\nDie Verarbeitung erfolgt auf der Grundlage von Art. 6 (1) lit. f DSGVO auf der Grundlage unseres berechtigten Interesses an einer nutzerfreundlichen Gestaltung unserer Website.",style: TextStyle(fontSize: 16),),
            const Text("\nEmpfänger:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),),
            const Text("\nEmpfänger der Daten können technische Dienstleister sein, die als Auftragsverarbeiter für den Betrieb und die Wartung unserer Website fungieren.",style: TextStyle(fontSize: 16),),
            const Text("\nVorschrift obligatorisch oder erforderlich:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),),
            const Text("\nDie Bereitstellung der vorgenannten personenbezogenen Daten ist nicht gesetzlich oder vertraglich vorgeschrieben. Ohne diese Daten ist der Service und die Funktionalität unserer Website jedoch nicht gewährleistet. Außerdem können einzelne Dienste und Leistungen nicht oder nur eingeschränkt verfügbar sein.",style: TextStyle(fontSize: 16),),
            const Text("\nEinspruch",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),),
            const Text("\nBitte lies die Informationen über dein Widerspruchsrecht nach Art. 21 DSGVO unten.",style: TextStyle(fontSize: 16),),
            const Text("\nKontakt-Formular",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),),
            const Text("\nArt und Zweck der Verarbeitung:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),),
            const Text("\nDie von dir eingegebenen Daten werden zum Zweck der individuellen Kommunikation mit dir gespeichert. Zu diesem Zweck ist es notwendig, eine gültige E-Mail-Adresse und deinen Namen anzugeben. Dieser wird für die Zuordnung der Anfrage und die anschließende Beantwortung derselben verwendet. Die Angabe von weiteren Daten ist freiwillig.",style: TextStyle(fontSize: 16)),
            const Text("\nRechtsgrundlage:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text("\nDie Verarbeitung der in das Kontaktformular eingegebenen Daten erfolgt auf Grundlage eines berechtigten Interesses (Art. 6 Abs. 1 lit. f DSGVO). Durch die Bereitstellung des Kontaktformulars möchten wir dir eine unkomplizierte Kontaktaufnahme mit uns ermöglichen. Die von dir gemachten Angaben werden zum Zweck der Bearbeitung der Anfrage und für mögliche Anschlussfragen gespeichert. Wenn du uns kontaktierst, um ein Angebot anzufordern, werden die im Kontaktformular eingegebenen Daten zur Durchführung vorvertraglicher Maßnahmen verarbeitet (Art. 6 Abs. 1 lit. b DSGVO).",style: TextStyle(fontSize: 16)),
            const Text("\nEmpfänger:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text("\nEmpfänger der Daten sind ggf. Auftragsverarbeiter.",style: TextStyle(fontSize: 16)),
            const Text("\nDauer der Lagerung:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text("\nDie Daten werden spätestens 6 Monate nach der Bearbeitung der Anfrage gelöscht. Wenn ein Vertragsverhältnis besteht, unterliegen wir den gesetzlichen Aufbewahrungsfristen nach dem Handelsgesetzbuch (HGB) und löschen deine Daten nach Ablauf dieser Fristen.",style: TextStyle(fontSize: 16)),
            const Text("\nVorschrift obligatorisch oder erforderlich:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text("\nDie Angabe deiner persönlichen Daten ist freiwillig. Wir können deine Anfrage jedoch nur bearbeiten, wenn du uns deinen Namen, deine E-Mail-Adresse und den Grund für deine Anfrage mitteilst.",style: TextStyle(fontSize: 16)),
            const Text("\nVerwendung von Google Analytics",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\nWenn du deine Zustimmung gegeben hast, benutzt diese Website Google Analytics, einen Webanalysedienst der Google LLC, 1600 Amphitheatre Parkway, Mountain View, CA 94043 USA (im Folgenden: 'Google'). Google Analytics verwendet sog. 'Cookies', Textdateien, die auf deinem Computer gespeichert werden, um die Nutzung der Website zu analysieren. Die von dem Cookie erzeugten Informationen über deine Nutzung dieser Website werden normalerweise an einen Google-Server in den USA übertragen und dort gespeichert. Aufgrund der Aktivierung der IP-Anonymisierung auf diesen Webseiten wird deine IP-Adresse von Google jedoch innerhalb von Mitgliedstaaten der Europäischen Union oder in anderen Vertragsstaaten des Abkommens über den Europäischen Wirtschaftsraum zuvor gekürzt. Nur in Ausnahmefällen wird die volle IP-Adresse an einen Server von Google in den USA übertragen und dort gekürzt. Die von deinem Browser im Rahmen von Google Analytics übermittelte IP-Adresse wird nicht mit anderen Daten von Google zusammengeführt. Weitere Informationen zu Nutzungsbedingungen und Datenschutz findest du unter ",style: TextStyle(fontSize: 16,color: Colors.black)),
                      TextSpan(
                          text: "https://www.google.com/analytics/terms/de.html",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://www.google.com/analytics/terms/de.html");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                      const TextSpan(text: " und unter ",style: TextStyle(fontSize: 16,color: Colors.black,),),
                      TextSpan(
                          text: "https://policies.google.com/?hl=de",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://policies.google.com/?hl=de");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                      const TextSpan(text: ". Im Auftrag des Betreibers dieser Website wird Google diese Informationen benutzen, um deine Nutzung der Website auszuwerten, um Reports über die Websiteaktivitäten zusammenzustellen und um weitere mit der Websitenutzung und der Internetnutzung verbundene Dienstleistungen gegenüber dem Websitebetreiber zu erbringen. Die von uns gesendeten und mit Cookies, Benutzerkennungen (z. B. User-ID) oder Werbe-IDs verknüpften Daten werden automatisch nach 14 Monaten gelöscht. Die Löschung von Daten, deren Aufbewahrungsfrist erreicht ist, erfolgt automatisch einmal im Monat.",style: TextStyle(fontSize: 16,color: Colors.black,),),
                    ]
                )
            ),
            const Text("\nRücknahme der Zustimmung:",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\nDu kannst das Tracking durch Google Analytics auf unserer Website verhindern. Dadurch wird ein Opt-out-Cookie auf deinem Gerät installiert. Dadurch wird die Erfassung durch Google Analytics für diese Website und für diesen Browser in Zukunft verhindert, solange das Cookie in deinem Browser installiert bleibt. Du kannst die Speicherung von Cookies auch verhindern, indem du die entsprechenden Einstellungen in deiner Browsersoftware vornimmst; beachte jedoch, dass du in diesem Fall möglicherweise nicht die volle Funktionalität dieser Website nutzen kannst. Du kannst außerdem die Erfassung der durch das Cookie erzeugten und auf deine Nutzung der Website bezogenen Daten (einschließlich deiner IP-Adresse) an Google sowie die Verarbeitung dieser Daten durch Google verhindern, indem du das unter dem folgenden Link verfügbare Browser-Plugin herunterlädst und installierst: ",style: TextStyle(fontSize: 16,color: Colors.black,)),
                      TextSpan(
                          text: "Browser Add On zum Deaktivieren von Google Analytics.",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://tools.google.com/dlpage/gaoptout?hl=de");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                    ]
                )
            ),
            const Text("\nVerwendung von Schriftbibliotheken (Google Web Fonts)",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\nUm unsere Inhalte browserübergreifend korrekt und grafisch ansprechend darzustellen, verwenden wir auf dieser Website 'Google Web Fonts' der Google LLC (1600 Amphitheatre Parkway, Mountain View, CA 94043, USA; im Folgenden 'Google') zur Darstellung von Schriftarten. Weitere Informationen über Google Web Fonts findest du unter ",style: TextStyle(fontSize: 16,color: Colors.black,)),
                      TextSpan(
                          text: "https://developers.google.com/fonts/faq",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://developers.google.com/fonts/faq");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                      const TextSpan(text: " und in den Datenschutzbestimmungen von Google: ",style: TextStyle(fontSize: 16,color: Colors.black,)),
                      TextSpan(
                          text: "https://www.google.com/policies/privacy/",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://www.google.com/policies/privacy/");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                      const TextSpan(text: ".",style: TextStyle(fontSize: 16)),
                    ]
                )
            ),
            const Text("\nNutzung von Google Maps",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\nAuf dieser Website nutzen wir das Angebot von Google Maps. Google Maps wird von Google LLC, 1600 Amphitheatre Parkway, Mountain View, CA 94043, USA (im Folgenden 'Google') betrieben. Dadurch können wir interaktive Karten direkt auf der Website anzeigen und du kannst die Kartenfunktion bequem nutzen. Weitere Informationen zur Datenverarbeitung durch Google findest du in den Datenschutzbestimmungen von Google: ",style: TextStyle(fontSize: 16,color: Colors.black,)),
                      TextSpan(
                          text: "https://policies.google.com/privacy",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://policies.google.com/privacy");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                      const TextSpan(text: ". Dort kannst du auch deine persönlichen Datenschutzeinstellungen im Datenschutz-Center ändern. Eine ausführliche Anleitung zur Verwaltung deiner eigenen Daten in Verbindung mit Google-Produkten findest du hier: ",style: TextStyle(fontSize: 16,color: Colors.black,)),
                      TextSpan(
                          text: "https://www.dataliberation.org",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://www.dataliberation.org");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                      const TextSpan(text: " Durch den Besuch der Website erhält Google die Information, dass du die entsprechende Unterseite unserer Website aufgerufen hast. Dies geschieht unabhängig davon, ob Google ein Benutzerkonto bereitstellt, über das du eingeloggt bist, oder ob kein Benutzerkonto existiert. Wenn du bei Google eingeloggt bist, werden deine Daten direkt deinem Konto zugeordnet. Wenn du die Zuordnung in deinem Profil bei Google nicht wünschst, musst du dich bei Google abmelden, bevor du die Schaltfläche aktivierst. Google speichert deine Daten als Nutzungsprofile und nutzt sie für Zwecke der Werbung, Marktforschung und/oder bedarfsgerechten Gestaltung seiner Websites. Eine solche Auswertung erfolgt insbesondere (auch für nicht eingeloggte Nutzer/innen) zur Bereitstellung bedarfsgerechter Werbung und um andere Nutzer/innen des sozialen Netzwerks über deine Aktivitäten auf unserer Website zu informieren. Du hast das Recht, der Erstellung dieser Nutzerprofile zu widersprechen, wobei du dich zur Ausübung dessen an Google wenden musst.",style: TextStyle(fontSize: 16, color: Colors.black)),
                    ]
                )
            ),
            const Text("\nWiderruf der Zustimmung:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text("\nEine Option für ein einfaches Opt-out oder die Blockierung der Datenübertragung wird vom Anbieter derzeit nicht angeboten. Wenn du das Tracking deiner Aktivitäten auf unserer Website verhindern möchtest, widerrufe bitte deine Zustimmung für die entsprechende Cookie-Kategorie oder alle technisch nicht notwendigen Cookies und Datenübertragungen im Cookie-Einwilligungstool. In diesem Fall kann es jedoch sein, dass du unsere Website nicht oder nur eingeschränkt nutzen kannst.",style: TextStyle(fontSize: 16)),
            const Text("\nEingebettete YouTube-Videos",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            RichText(
                text: TextSpan(
                    children: [
                      const TextSpan(text: "\nAuf unserer Website betten wir YouTube-Videos ein. Der Betreiber der entsprechenden Plugins ist YouTube, LLC, 901 Cherry Ave, San Bruno, CA 94066, USA (im Folgenden 'YouTube'). YouTube, LLC ist eine Tochtergesellschaft von Google LLC, 1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA (im Folgenden 'Google'). Wenn du eine Seite mit dem YouTube-Plugin besuchst, wird eine Verbindung zu den YouTube-Servern hergestellt. Dabei wird YouTube mitgeteilt, welche Seiten du besuchst. Wenn du in deinem YouTube-Konto angemeldet bist, kann YouTube dein Surfverhalten dir persönlich zuordnen. Du kannst dies verhindern, indem du dich vorher aus deinem YouTube-Konto ausloggst. Wenn ein YouTube-Video gestartet wird, setzt der Anbieter Cookies ein, die Informationen über das Nutzerverhalten sammeln. Weitere Informationen zu Zweck und Umfang der Datenerhebung und ihrer Verarbeitung durch YouTube findest du in der Datenschutzerklärung des Anbieters. Dort findest du auch weitere Informationen über deine diesbezüglichen Rechte und Einstellungsmöglichkeiten zum Schutz deiner Privatsphäre (",style: TextStyle(fontSize: 16,color: Colors.black,)),
                      TextSpan(
                          text: "https://policies.google.com/privacy",
                          style: const TextStyle(fontSize: 16,decoration: TextDecoration.underline,color: Colors.black,),
                          recognizer: TapGestureRecognizer()..onTap = () async {
                            final uri = Uri.parse("https://policies.google.com/privacy");
                            await launchUrl(
                              uri,
                            );
                          }
                      ),
                      const TextSpan(text: ").",style: TextStyle(fontSize: 16,color: Colors.black,)),
                    ]
                )
            ),
            const Text("\nWiderruf der Zustimmung:",style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Text("\nDer Anbieter bietet derzeit keine Option für ein einfaches Opt-out oder die Blockierung der Datenübertragung. Wenn du verhindern möchtest, dass deine Aktivitäten auf unserer Website nachverfolgt werden, widerrufe bitte deine Zustimmung für die entsprechende Cookie-Kategorie oder alle technisch nicht notwendigen Cookies und Datenübertragungen im Cookie-Einwilligungstool. In diesem Fall kann es allerdings sein, dass du unsere Website nicht oder nur eingeschränkt nutzen kannst.",style: TextStyle(fontSize: 16)),
            const Text("\nSSL-Verschlüsselung",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Text("\nUm die Sicherheit deiner Daten bei der Übertragung zu schützen, verwenden wir modernste Verschlüsselungsmethoden (z. B. SSL) über HTTPS.",style: TextStyle(fontSize: 16)),
            const Text("\nInformationen über dein Widerspruchsrecht nach Art. 21 DSGVO",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Text("\nRecht auf Einspruch im Einzelfall",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700)),
            const Text("\nDu hast das Recht, aus Gründen, die sich aus deiner besonderen Situation ergeben, jederzeit gegen die Verarbeitung dich betreffender personenbezogener Daten, die auf der Grundlage von Art. 6 Abs. 1 Buchstabe f DSGVO (Datenverarbeitung auf der Grundlage einer Interessenabwägung) erfolgt; dies gilt auch für ein auf diese Bestimmung gestütztes Profiling im Sinne von Art. 4 Nr. 4 DSGVO. Wenn du widersprichst, werden wir deine personenbezogenen Daten nicht mehr verarbeiten, es sei denn, wir können zwingende schutzwürdige Gründe für die Verarbeitung nachweisen, die deine Interessen, Rechte und Freiheiten überwiegen, oder die Verarbeitung dient der Geltendmachung, Ausübung oder Verteidigung von Rechtsansprüchen.",style: TextStyle(fontSize: 16,color: Colors.black,)),
            const Text("\nEmpfänger eines Einspruchs",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700)),
            const Text("\nLivAir GmbH\nAgnes-Pockels-Bogen 1\n80992 München\nDeutschland",style: TextStyle(fontSize: 16)),
            const Text("\nÄnderung unserer Datenschutzrichtlinie",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Text("\nWir behalten uns das Recht vor, diese Datenschutzerklärung anzupassen, um sicherzustellen, dass sie stets den aktuellen rechtlichen Anforderungen entspricht, oder um Änderungen an unseren Dienstleistungen in der Datenschutzerklärung umzusetzen, z. B. bei der Einführung neuer Dienstleistungen. Die neue Datenschutzrichtlinie gilt dann für deinen nächsten Besuch.",style: TextStyle(fontSize: 16)),
            const Text("\nFragen an den Datenschutzbeauftragten",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Text("\nWenn du Fragen zum Datenschutz hast, schreibe uns bitte eine E-Mail oder wende dich direkt an die Person, die in unserer Organisation für den Datenschutz verantwortlich ist: Martin Waltl",style: TextStyle(fontSize: 16)),

          ],
        ),
      ),
    );
  }}