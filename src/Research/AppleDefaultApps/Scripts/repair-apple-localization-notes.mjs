#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { execFileSync } from 'node:child_process'

const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const rootDir = path.resolve(scriptDir, '..')
const translationsPath = path.join(rootDir, 'AppleDefaultApps.translations.json')

const translationsText = fs.readFileSync(translationsPath, 'utf8').replace(/\\n\s*$/u, '\n')
const translations = JSON.parse(translationsText)

const coreServiceApps = [
  {
    id: 'about-this-mac',
    bundleIdentifier: 'com.apple.AboutThisMacLauncher',
    appPath: '/System/Library/CoreServices/Applications/About This Mac.app',
    fallbackName: 'About This Mac'
  },
  {
    id: 'archive-utility',
    bundleIdentifier: 'com.apple.archiveutility',
    appPath: '/System/Library/CoreServices/Applications/Archive Utility.app',
    fallbackName: 'Archive Utility'
  },
  {
    id: 'desk-view',
    bundleIdentifier: 'com.apple.DeskCam',
    appPath: '/System/Library/CoreServices/Applications/Desk View.app',
    fallbackName: 'Desk View'
  },
  {
    id: 'directory-utility',
    bundleIdentifier: 'com.apple.DirectoryUtility',
    appPath: '/System/Library/CoreServices/Applications/Directory Utility.app',
    fallbackName: 'Directory Utility'
  },
  {
    id: 'dvd-player',
    bundleIdentifier: 'com.apple.DVDPlayer',
    appPath: '/System/Library/CoreServices/Applications/DVD Player.app',
    fallbackName: 'DVD Player'
  },
  {
    id: 'expansion-slot-utility',
    bundleIdentifier: 'com.apple.ExpansionSlotUtility',
    appPath: '/System/Library/CoreServices/Applications/Expansion Slot Utility.app',
    fallbackName: 'Expansion Slot Utility'
  },
  {
    id: 'feedback-assistant',
    bundleIdentifier: 'com.apple.appleseed.FeedbackAssistant',
    appPath: '/System/Library/CoreServices/Applications/Feedback Assistant.app',
    fallbackName: 'Feedback Assistant'
  },
  {
    id: 'folder-actions-setup',
    bundleIdentifier: 'com.apple.FolderActionsSetup',
    appPath: '/System/Library/CoreServices/Applications/Folder Actions Setup.app',
    fallbackName: 'Folder Actions Setup'
  },
  {
    id: 'ios-app-installer',
    bundleIdentifier: 'com.apple.IPAInstaller',
    appPath: '/System/Library/CoreServices/Applications/iOS App Installer.app',
    fallbackName: 'iOS App Installer'
  },
  {
    id: 'keychain-access',
    bundleIdentifier: 'com.apple.keychainaccess',
    appPath: '/System/Library/CoreServices/Applications/Keychain Access.app',
    fallbackName: 'Keychain Access'
  },
  {
    id: 'ticket-viewer',
    bundleIdentifier: 'com.apple.Ticket-Viewer',
    appPath: '/System/Library/CoreServices/Applications/Ticket Viewer.app',
    fallbackName: 'Ticket Viewer'
  },
  {
    id: 'wireless-diagnostics',
    bundleIdentifier: 'com.apple.wifi.diagnostics',
    appPath: '/System/Library/CoreServices/Applications/Wireless Diagnostics.app',
    fallbackName: 'Wireless Diagnostics'
  }
]

const coreServiceNoteIDs = coreServiceApps.map((app) => app.id)

const coreServiceNotesByLanguage = {
  'zh-Hans': [
    '查看 Mac 型号、系统版本和序列号',
    '压缩和解压 ZIP 等归档文件的系统工具',
    '配合连续互通摄像头显示桌面视角',
    '配置目录服务、LDAP 和网络账号连接',
    '播放 DVD 光盘和本地 DVD 内容',
    '查看和配置 Mac Pro 扩展槽',
    '向 Apple 提交系统反馈和诊断报告',
    '为文件夹配置自动触发的脚本动作',
    '安装 iOS App 包的系统辅助工具',
    '管理密码、证书、密钥和安全项目',
    '查看 Kerberos 票据和身份验证状态',
    '诊断 Wi-Fi 问题并生成无线报告'
  ],
  'zh-Hant': [
    '查看 Mac 型號、系統版本和序號',
    '壓縮和解壓縮 ZIP 等封存檔案',
    '配合連續互通相機顯示桌上視角',
    '設定目錄服務、LDAP 和網路帳號連線',
    '播放 DVD 光碟和本機 DVD 內容',
    '查看和設定 Mac Pro 擴充插槽',
    '向 Apple 送出系統回饋和診斷報告',
    '為檔案夾設定自動觸發的腳本動作',
    '安裝 iOS App 套件的系統輔助工具',
    '管理密碼、憑證、密鑰和安全項目',
    '查看 Kerberos 票券和驗證狀態',
    '診斷 Wi-Fi 問題並產生無線報告'
  ],
  en: [
    'Show Mac model, system version, and serial number',
    'Compress and extract ZIP and other archive files',
    'Show a desk view with Continuity Camera',
    'Configure directory services, LDAP, and network accounts',
    'Play DVD discs and local DVD content',
    'View and configure Mac Pro expansion slots',
    'Send system feedback and diagnostics to Apple',
    'Attach automatic script actions to folders',
    'Install iOS app packages with a system helper',
    'Manage passwords, certificates, keys, and secure items',
    'View Kerberos tickets and authentication status',
    'Diagnose Wi-Fi issues and create wireless reports'
  ],
  fr: [
    'Affiche le modèle du Mac, macOS et le numéro de série',
    'Compresse et extrait les fichiers ZIP et archives',
    'Affiche le bureau avec la caméra Continuité',
    'Configure services d’annuaire, LDAP et comptes réseau',
    'Lit les disques DVD et contenus DVD locaux',
    'Affiche et configure les logements Mac Pro',
    'Envoie des retours système et diagnostics à Apple',
    'Ajoute des scripts automatiques aux dossiers',
    'Installe des paquets d’apps iOS avec l’outil système',
    'Gère mots de passe, certificats, clés et éléments sûrs',
    'Affiche les tickets Kerberos et l’état d’authentification',
    'Diagnostique le Wi-Fi et crée des rapports sans fil'
  ],
  it: [
    'Mostra modello del Mac, versione di sistema e seriale',
    'Comprime ed estrae file ZIP e archivi',
    'Mostra la scrivania con Fotocamera Continuity',
    'Configura servizi directory, LDAP e account di rete',
    'Riproduce dischi DVD e contenuti DVD locali',
    'Visualizza e configura slot di espansione Mac Pro',
    'Invia feedback di sistema e diagnosi ad Apple',
    'Aggiunge azioni script automatiche alle cartelle',
    'Installa pacchetti di app iOS con lo strumento di sistema',
    'Gestisce password, certificati, chiavi ed elementi sicuri',
    'Mostra ticket Kerberos e stato di autenticazione',
    'Diagnostica il Wi-Fi e crea report wireless'
  ],
  de: [
    'Zeigt Mac-Modell, Systemversion und Seriennummer',
    'Komprimiert und entpackt ZIP-Dateien und Archive',
    'Zeigt den Schreibtisch mit der Integrationskamera',
    'Konfiguriert Verzeichnisdienste, LDAP und Netzwerkaccounts',
    'Spielt DVD-Medien und lokale DVD-Inhalte ab',
    'Zeigt und konfiguriert Mac Pro Erweiterungssteckplätze',
    'Sendet Systemfeedback und Diagnosen an Apple',
    'Verknüpft Ordner mit automatischen Skriptaktionen',
    'Installiert iOS-App-Pakete mit einem Systemhelfer',
    'Verwaltet Passwörter, Zertifikate, Schlüssel und sichere Objekte',
    'Zeigt Kerberos-Tickets und den Anmeldestatus',
    'Diagnostiziert WLAN-Probleme und erstellt Berichte'
  ],
  es: [
    'Muestra modelo del Mac, versión del sistema y número de serie',
    'Comprime y extrae ZIP y otros archivos',
    'Muestra la mesa con la cámara de Continuidad',
    'Configura servicios de directorio, LDAP y cuentas de red',
    'Reproduce discos DVD y contenido DVD local',
    'Ve y configura ranuras de expansión de Mac Pro',
    'Envía comentarios del sistema y diagnósticos a Apple',
    'Añade acciones de script automáticas a carpetas',
    'Instala paquetes de apps iOS con una ayuda del sistema',
    'Gestiona contraseñas, certificados, claves y elementos seguros',
    'Muestra tickets Kerberos y estado de autenticación',
    'Diagnostica Wi-Fi y crea informes inalámbricos'
  ],
  'pt-BR': [
    'Mostra modelo do Mac, versão do sistema e número de série',
    'Compacta e extrai ZIP e outros arquivos',
    'Mostra a mesa com a Câmera de Continuidade',
    'Configura serviços de diretório, LDAP e contas de rede',
    'Reproduz discos DVD e conteúdo DVD local',
    'Mostra e configura slots de expansão do Mac Pro',
    'Envia feedback do sistema e diagnósticos à Apple',
    'Adiciona ações de script automáticas a pastas',
    'Instala pacotes de apps iOS com ajuda do sistema',
    'Gerencia senhas, certificados, chaves e itens seguros',
    'Mostra tíquetes Kerberos e estado de autenticação',
    'Diagnostica Wi-Fi e cria relatórios sem fio'
  ],
  ko: [
    'Mac 모델, 시스템 버전, 일련번호를 확인합니다',
    'ZIP 등 압축 파일을 만들고 풉니다',
    '연속성 카메라로 책상 화면을 보여줍니다',
    '디렉토리 서비스, LDAP, 네트워크 계정을 설정합니다',
    'DVD 디스크와 로컬 DVD 콘텐츠를 재생합니다',
    'Mac Pro 확장 슬롯을 확인하고 설정합니다',
    '시스템 피드백과 진단 정보를 Apple에 보냅니다',
    '폴더에 자동 스크립트 동작을 연결합니다',
    'iOS 앱 패키지를 설치하는 시스템 도구입니다',
    '암호, 인증서, 키와 보안 항목을 관리합니다',
    'Kerberos 티켓과 인증 상태를 확인합니다',
    'Wi-Fi 문제를 진단하고 무선 보고서를 만듭니다'
  ],
  ja: [
    'Macのモデル、システムバージョン、シリアル番号を確認',
    'ZIPなどのアーカイブを圧縮・展開',
    '連係カメラでデスク上の映像を表示',
    'ディレクトリサービス、LDAP、ネットワークアカウントを設定',
    'DVDディスクやローカルDVDコンテンツを再生',
    'Mac Proの拡張スロットを確認・設定',
    'システムのフィードバックと診断をAppleへ送信',
    'フォルダに自動実行スクリプトを割り当て',
    'iOS Appパッケージをインストールするシステム補助ツール',
    'パスワード、証明書、鍵、安全項目を管理',
    'Kerberosチケットと認証状態を確認',
    'Wi-Fi問題を診断し、無線レポートを作成'
  ],
  ru: [
    'Показывает модель Mac, версию системы и серийный номер',
    'Сжимает и распаковывает ZIP и другие архивы',
    'Показывает стол через камеру Continuity',
    'Настраивает службы каталогов, LDAP и сетевые учетные записи',
    'Воспроизводит DVD-диски и локальный DVD-контент',
    'Показывает и настраивает слоты расширения Mac Pro',
    'Отправляет Apple отзывы о системе и диагностику',
    'Назначает папкам автоматические действия скриптов',
    'Устанавливает пакеты приложений iOS системным помощником',
    'Управляет паролями, сертификатами, ключами и защищенными объектами',
    'Показывает билеты Kerberos и состояние аутентификации',
    'Диагностирует Wi-Fi и создает отчеты о сети'
  ],
  'sr-Cyrl': [
    'Приказује модел Mac-а, верзију система и серијски број',
    'Компримује и распакује ZIP и друге архиве',
    'Приказује радни сто помоћу Continuity камере',
    'Подешава директоријуме, LDAP и мрежне налоге',
    'Пушта DVD дискове и локални DVD садржај',
    'Приказује и подешава Mac Pro слотове проширења',
    'Шаље Apple-у повратне информације и дијагностику',
    'Додаје аутоматске скрипт радње фасциклама',
    'Инсталира iOS пакете апликација системским алатом',
    'Управља лозинкама, сертификатима, кључевима и безбедним ставкама',
    'Приказује Kerberos тикете и стање аутентификације',
    'Дијагностикује Wi-Fi и прави бежичне извештаје'
  ],
  uk: [
    'Показує модель Mac, версію системи та серійний номер',
    'Стискає й розпаковує ZIP та інші архіви',
    'Показує стіл за допомогою камери Continuity',
    'Налаштовує служби каталогів, LDAP і мережеві обліковки',
    'Відтворює DVD-диски та локальний DVD-вміст',
    'Показує й налаштовує слоти розширення Mac Pro',
    'Надсилає Apple відгуки про систему та діагностику',
    'Додає автоматичні скрипти до папок',
    'Встановлює пакети iOS App системним помічником',
    'Керує паролями, сертифікатами, ключами та захищеними об’єктами',
    'Показує квитки Kerberos і стан автентифікації',
    'Діагностує Wi-Fi і створює бездротові звіти'
  ],
  th: [
    'ดูรุ่น Mac เวอร์ชั่นระบบ และหมายเลขประจำเครื่อง',
    'บีบอัดและแตกไฟล์ ZIP และไฟล์เก็บถาวร',
    'แสดงมุมมองโต๊ะด้วยกล้อง Continuity',
    'ตั้งค่าบริการไดเรกทอรี LDAP และบัญชีเครือข่าย',
    'เล่นแผ่น DVD และเนื้อหา DVD ในเครื่อง',
    'ดูและตั้งค่าช่องเสียบส่วนขยายของ Mac Pro',
    'ส่งคำติชมระบบและข้อมูลวินิจฉัยให้ Apple',
    'เพิ่มการทำงานสคริปต์อัตโนมัติให้โฟลเดอร์',
    'ติดตั้งแพ็กเกจแอป iOS ด้วยเครื่องมือระบบ',
    'จัดการรหัสผ่าน ใบรับรอง กุญแจ และรายการปลอดภัย',
    'ดูตั๋ว Kerberos และสถานะการตรวจสอบสิทธิ์',
    'วินิจฉัย Wi-Fi และสร้างรายงานไร้สาย'
  ],
  vi: [
    'Xem kiểu máy Mac, phiên bản hệ thống và số sê-ri',
    'Nén và giải nén ZIP cùng các tệp lưu trữ',
    'Hiển thị mặt bàn bằng Camera thông suốt',
    'Cấu hình dịch vụ thư mục, LDAP và tài khoản mạng',
    'Phát đĩa DVD và nội dung DVD cục bộ',
    'Xem và cấu hình khe mở rộng của Mac Pro',
    'Gửi phản hồi hệ thống và chẩn đoán cho Apple',
    'Gắn hành động script tự động cho thư mục',
    'Cài gói ứng dụng iOS bằng công cụ hệ thống',
    'Quản lý mật khẩu, chứng chỉ, khóa và mục bảo mật',
    'Xem vé Kerberos và trạng thái xác thực',
    'Chẩn đoán Wi-Fi và tạo báo cáo không dây'
  ],
  ar: [
    'يعرض طراز Mac وإصدار النظام والرقم التسلسلي',
    'يضغط ملفات ZIP والأرشيفات ويفكها',
    'يعرض سطح المكتب باستخدام كاميرا الاستمرارية',
    'يضبط خدمات الدليل وLDAP وحسابات الشبكة',
    'يشغل أقراص DVD والمحتوى المحلي',
    'يعرض ويضبط فتحات التوسعة في Mac Pro',
    'يرسل ملاحظات النظام والتشخيصات إلى Apple',
    'يربط المجلدات بإجراءات نصية تلقائية',
    'يثبت حزم تطبيقات iOS بأداة النظام',
    'يدير كلمات السر والشهادات والمفاتيح والعناصر الآمنة',
    'يعرض تذاكر Kerberos وحالة المصادقة',
    'يشخص مشاكل Wi-Fi وينشئ تقارير لاسلكية'
  ],
  'ar-Najdi': [
    'يعرض طراز Mac وإصدار النظام والرقم التسلسلي',
    'يضغط ملفات ZIP والأرشيفات ويفكها',
    'يعرض سطح المكتب باستخدام كاميرا الاستمرارية',
    'يضبط خدمات الدليل وLDAP وحسابات الشبكة',
    'يشغل أقراص DVD والمحتوى المحلي',
    'يعرض ويضبط فتحات التوسعة في Mac Pro',
    'يرسل ملاحظات النظام والتشخيصات إلى Apple',
    'يربط المجلدات بإجراءات نصية تلقائية',
    'يثبت حزم تطبيقات iOS بأداة النظام',
    'يدير كلمات السر والشهادات والمفاتيح والعناصر الآمنة',
    'يعرض تذاكر Kerberos وحالة المصادقة',
    'يشخص مشاكل Wi-Fi وينشئ تقارير لاسلكية'
  ],
  tr: [
    'Mac modelini, sistem sürümünü ve seri numarasını gösterir',
    'ZIP ve diğer arşiv dosyalarını sıkıştırır ve açar',
    'Süreklilik Kamerası ile masa görüntüsünü gösterir',
    'Dizin servislerini, LDAP’ı ve ağ hesaplarını ayarlar',
    'DVD disklerini ve yerel DVD içeriğini oynatır',
    'Mac Pro genişleme yuvalarını gösterir ve ayarlar',
    'Apple’a sistem geri bildirimi ve tanılama gönderir',
    'Klasörlere otomatik betik eylemleri ekler',
    'iOS uygulama paketlerini sistem aracıyla yükler',
    'Parolaları, sertifikaları, anahtarları ve güvenli öğeleri yönetir',
    'Kerberos biletlerini ve kimlik doğrulama durumunu gösterir',
    'Wi-Fi sorunlarını tanılar ve kablosuz rapor oluşturur'
  ],
  id: [
    'Menampilkan model Mac, versi sistem, dan nomor seri',
    'Mengompres dan mengekstrak ZIP serta arsip lain',
    'Menampilkan meja dengan Kamera Berkelanjutan',
    'Mengatur layanan direktori, LDAP, dan akun jaringan',
    'Memutar disk DVD dan konten DVD lokal',
    'Melihat dan mengatur slot perluasan Mac Pro',
    'Mengirim umpan balik sistem dan diagnostik ke Apple',
    'Menambahkan aksi skrip otomatis ke folder',
    'Menginstal paket app iOS dengan alat sistem',
    'Mengelola kata sandi, sertifikat, kunci, dan item aman',
    'Melihat tiket Kerberos dan status autentikasi',
    'Mendiagnosis Wi-Fi dan membuat laporan nirkabel'
  ],
  cs: [
    'Zobrazí model Macu, verzi systému a sériové číslo',
    'Komprimuje a rozbaluje ZIP a další archivy',
    'Ukáže stůl pomocí Kamery přes Kontinuitu',
    'Nastavuje adresářové služby, LDAP a síťové účty',
    'Přehrává DVD disky a místní DVD obsah',
    'Zobrazí a nastaví rozšiřující sloty Macu Pro',
    'Odesílá Apple zpětnou vazbu a diagnostiku systému',
    'Přidává složkám automatické skriptové akce',
    'Instaluje balíčky aplikací iOS systémovým nástrojem',
    'Spravuje hesla, certifikáty, klíče a zabezpečené položky',
    'Zobrazí lístky Kerberos a stav ověření',
    'Diagnostikuje Wi-Fi a vytváří bezdrátové zprávy'
  ],
  da: [
    'Viser Mac-model, systemversion og serienummer',
    'Komprimerer og udpakker ZIP og andre arkiver',
    'Viser skrivebordet med Kontinuitetskamera',
    'Indstiller bibliotekstjenester, LDAP og netværkskonti',
    'Afspiller DVD-diske og lokalt DVD-indhold',
    'Viser og indstiller udvidelsespladser i Mac Pro',
    'Sender systemfeedback og diagnostik til Apple',
    'Føjer automatiske script-handlinger til mapper',
    'Installerer iOS-app-pakker med et systemværktøj',
    'Administrerer adgangskoder, certifikater, nøgler og sikre emner',
    'Viser Kerberos-billetter og godkendelsesstatus',
    'Diagnosticerer Wi-Fi og opretter trådløse rapporter'
  ],
  nl: [
    'Toont Mac-model, systeemversie en serienummer',
    'Comprimeert en pakt ZIP en andere archieven uit',
    'Toont je bureau met Continuïteitscamera',
    'Configureert directoryservices, LDAP en netwerkaccounts',
    'Speelt dvd-schijven en lokale dvd-inhoud af',
    'Toont en configureert Mac Pro-uitbreidingssleuven',
    'Stuurt systeemfeedback en diagnose naar Apple',
    'Koppelt automatische scriptacties aan mappen',
    'Installeert iOS-app-pakketten met een systeemhulp',
    'Beheert wachtwoorden, certificaten, sleutels en beveiligde items',
    'Toont Kerberos-tickets en authenticatiestatus',
    'Diagnosticeert wifi en maakt draadloze rapporten'
  ],
  no: [
    'Viser Mac-modell, systemversjon og serienummer',
    'Komprimerer og pakker ut ZIP og andre arkiver',
    'Viser skrivebordet med Kontinuitetskamera',
    'Konfigurerer katalogtjenester, LDAP og nettverkskontoer',
    'Spiller DVD-plater og lokalt DVD-innhold',
    'Viser og konfigurerer utvidelsesplasser i Mac Pro',
    'Sender systemtilbakemelding og diagnostikk til Apple',
    'Legger automatiske skripthandlinger til mapper',
    'Installerer iOS-app-pakker med systemverktøy',
    'Administrerer passord, sertifikater, nøkler og sikre objekter',
    'Viser Kerberos-billetter og autentiseringsstatus',
    'Diagnostiserer Wi-Fi og lager trådløse rapporter'
  ],
  nn: [
    'Viser Mac-modell, systemversjon og serienummer',
    'Komprimerer og pakkar ut ZIP og andre arkiv',
    'Viser skrivebordet med Kontinuitetskamera',
    'Set opp katalogtenester, LDAP og nettverkskontoar',
    'Spelar DVD-plater og lokalt DVD-innhald',
    'Viser og set opp utvidingsplassar i Mac Pro',
    'Sender systemtilbakemelding og diagnostikk til Apple',
    'Legg automatiske skripthandlingar til mapper',
    'Installerer iOS-app-pakkar med systemverktøy',
    'Handterer passord, sertifikat, nøklar og sikre objekt',
    'Viser Kerberos-billettar og autentiseringsstatus',
    'Diagnostiserer Wi-Fi og lagar trådlause rapportar'
  ],
  nb: [
    'Viser Mac-modell, systemversjon og serienummer',
    'Komprimerer og pakker ut ZIP og andre arkiver',
    'Viser skrivebordet med Kontinuitetskamera',
    'Konfigurerer katalogtjenester, LDAP og nettverkskontoer',
    'Spiller DVD-plater og lokalt DVD-innhold',
    'Viser og konfigurerer utvidelsesplasser i Mac Pro',
    'Sender systemtilbakemelding og diagnostikk til Apple',
    'Legger automatiske skripthandlinger til mapper',
    'Installerer iOS-app-pakker med systemverktøy',
    'Administrerer passord, sertifikater, nøkler og sikre objekter',
    'Viser Kerberos-billetter og autentiseringsstatus',
    'Diagnostiserer Wi-Fi og lager trådløse rapporter'
  ],
  ms: [
    'Memaparkan model Mac, versi sistem dan nombor siri',
    'Memampatkan dan mengekstrak ZIP serta arkib lain',
    'Memaparkan meja dengan Kamera Kesinambungan',
    'Mengkonfigurasi servis direktori, LDAP dan akaun rangkaian',
    'Memainkan cakera DVD dan kandungan DVD setempat',
    'Melihat dan mengkonfigurasi slot pengembangan Mac Pro',
    'Menghantar maklum balas sistem dan diagnostik kepada Apple',
    'Menambah tindakan skrip automatik pada folder',
    'Memasang pakej app iOS dengan alat sistem',
    'Mengurus kata laluan, sijil, kunci dan item selamat',
    'Melihat tiket Kerberos dan status pengesahan',
    'Mendiagnosis Wi-Fi dan mencipta laporan wayarles'
  ],
  pl: [
    'Pokazuje model Maca, wersję systemu i numer seryjny',
    'Kompresuje i rozpakowuje ZIP oraz inne archiwa',
    'Pokazuje biurko przez Kamerę Continuity',
    'Konfiguruje usługi katalogowe, LDAP i konta sieciowe',
    'Odtwarza płyty DVD i lokalne treści DVD',
    'Pokazuje i konfiguruje gniazda rozszerzeń Mac Pro',
    'Wysyła do Apple opinie systemowe i diagnostykę',
    'Dodaje automatyczne skrypty do folderów',
    'Instaluje pakiety aplikacji iOS narzędziem systemowym',
    'Zarządza hasłami, certyfikatami, kluczami i bezpiecznymi elementami',
    'Pokazuje bilety Kerberos i stan uwierzytelnienia',
    'Diagnozuje Wi-Fi i tworzy raporty sieci bezprzewodowej'
  ],
  ro: [
    'Afișează modelul Mac, versiunea sistemului și seria',
    'Comprimă și extrage ZIP și alte arhive',
    'Afișează biroul cu Camera Continuitate',
    'Configurează servicii director, LDAP și conturi de rețea',
    'Redă discuri DVD și conținut DVD local',
    'Afișează și configurează sloturile de extensie Mac Pro',
    'Trimite feedback de sistem și diagnostice către Apple',
    'Adaugă acțiuni script automate la dosare',
    'Instalează pachete de aplicații iOS cu instrumentul sistem',
    'Gestionează parole, certificate, chei și elemente sigure',
    'Afișează tichete Kerberos și starea autentificării',
    'Diagnostichează Wi-Fi și creează rapoarte wireless'
  ],
  sv: [
    'Visar Mac-modell, systemversion och serienummer',
    'Komprimerar och packar upp ZIP och andra arkiv',
    'Visar skrivbordet med Kontinuitetskamera',
    'Konfigurerar katalogtjänster, LDAP och nätverkskonton',
    'Spelar DVD-skivor och lokalt DVD-innehåll',
    'Visar och ställer in utbyggnadsfack i Mac Pro',
    'Skickar systemfeedback och diagnostik till Apple',
    'Lägger automatiska skriptåtgärder till mappar',
    'Installerar iOS-apppaket med ett systemverktyg',
    'Hanterar lösenord, certifikat, nycklar och säkra objekt',
    'Visar Kerberos-biljetter och autentiseringsstatus',
    'Diagnostiserar Wi-Fi och skapar trådlösa rapporter'
  ]
}

const curatedNotes = {
  en: {
    finder: 'Manage files, folders, disks, and connected devices on Mac',
    safari: 'Fast, private Apple browser with strong battery efficiency',
    mail: 'Manage multiple email accounts in one system mail client',
    messages: 'Send and reply to iMessage and SMS from the Mac',
    facetime: 'Audio and video calls across the Apple ecosystem',
    calendar: 'Organize schedules and see your time on a clear calendar',
    notes: 'Capture text, images, lists, and quick notes fast',
    reminders: 'Track to-dos and small daily tasks with reminders',
    photos: 'Manage, edit, and sync the system photo library',
    music: 'Play local music and streaming tracks on Mac',
    terminal: 'Command-line entry point for precise Mac control',
    'activity-monitor': 'See CPU, memory, energy, and heavy processes at a glance',
    'airport-utility': 'Manage AirPort and Time Capsule network devices',
    'app-store': 'Official Mac store for apps, updates, and subscriptions',
    apps: 'Lightweight system entry for opening installed apps',
    'audio-midi-setup': 'Configure audio devices and MIDI routing',
    automator: 'Build Mac automation workflows without writing code',
    'bluetooth-file-exchange': 'Send and receive files over Bluetooth when needed',
    books: 'Read and manage ebooks on Mac',
    'boot-camp-assistant': 'Official guide for installing Windows on Intel Macs',
    calculator: 'Calculator with unit conversion and programmer mode',
    chess: 'Built-in chess game for short breaks and practice',
    clock: 'Alarms, timers, stopwatch, and world clocks in one place',
    'colorsync-utility': 'View and repair color profiles for display and print',
    console: 'Inspect system logs when diagnosing problems',
    contacts: 'Contact hub used by Mail, Messages, and FaceTime',
    dictionary: 'Offline dictionary and thesaurus for writing and lookup',
    'digital-color-meter': 'Pick exact colors from the screen',
    'disk-utility': 'Manage disks, partitions, formatting, and First Aid',
    'find-my': 'Locate devices, items, and a lost Mac',
    'font-book': 'Install, preview, and manage fonts',
    freeform: 'Infinite whiteboard for brainstorming, sketches, and loose ideas',
    games: 'Apple games hub for Apple Arcade and playable content',
    grapher: 'Plot equations and visualize math',
    home: 'Control smart home lights, climate, and accessories',
    'image-capture': 'Import images from cameras and scanners',
    'image-playground': 'Create images with Apple Intelligence for quick drafts',
    imovie: 'Simple video editing for home movies and light projects',
    'iphone-mirroring': 'Control iPhone directly from the Mac',
    journal: 'Record daily moments into a private timeline',
    keynote: 'Create polished Apple-style presentations',
    magnifier: 'Enlarge screen details for reading and inspection',
    maps: 'Check routes, explore cities, and send destinations to iPhone',
    'migration-assistant': 'Move data from an old Mac to a new one',
    'mission-control': 'See all windows and desktops when things get crowded',
    news: 'Read selected Apple News stories and media',
    numbers: 'Apple spreadsheet app for clean, lightweight reports',
    pages: 'Apple word processor for documents and page layout',
    passwords: 'Manage passwords, verification codes, and passkeys',
    phone: 'Make and answer phone calls on Mac through iPhone',
    'photo-booth': 'Take camera selfies and test fun effects',
    podcasts: 'Listen to podcasts for commutes, study, and downtime',
    preview: 'View images, annotate PDFs, and make quick edits',
    'print-center': 'View and manage print queues and stalled print jobs',
    'quicktime-player': 'Play media and record screen or audio',
    'screen-sharing': 'Remotely control another Mac to help or troubleshoot',
    screenshot: 'Capture screenshots and screen recordings',
    'script-editor': 'Write and run AppleScript automation',
    'sf-symbols': "Browse Apple's symbol library for native interfaces",
    shortcuts: 'Combine actions into quick one-tap workflows',
    siri: 'Voice assistant for search, app launch, and system control',
    stickies: 'Desktop sticky notes for temporary reminders',
    stocks: 'Track stocks and market movement in a compact panel',
    'system-information': 'View detailed hardware, software, and device information',
    'system-settings': 'Central place for Mac settings and system options',
    textedit: 'Simple text editor for TXT and RTF files',
    'time-machine': 'System backup tool for restoring files later',
    tips: 'Apple tips for discovering useful macOS features',
    tv: 'Play and manage movies and TV content',
    'voice-memos': 'Quickly record ideas, meetings, and interviews',
    'voiceover-utility': 'Manage VoiceOver screen-reader accessibility settings',
    weather: 'Check weather forecasts before heading out',
    xcode: 'Apple developer tools for iOS and macOS apps',
    garageband: 'Easy Apple music creation for recording and arranging',
    'final-cut-pro': 'Pro Apple video editing for cuts, color, and export',
    'logic-pro': 'Pro Apple music production for recording, arranging, and mixing',
    testflight: 'Install and test beta versions of Apple apps'
  },
  fr: {
    finder: 'Gère fichiers, dossiers, disques et appareils connectés au Mac',
    safari: 'Navigateur Apple rapide, privé et économe en batterie',
    mail: 'Gère plusieurs comptes e-mail dans le client Mail système',
    messages: 'Envoyez et répondez aux iMessage et SMS depuis le Mac',
    facetime: "Appels audio et vidéo dans l'écosystème Apple",
    calendar: 'Organise les rendez-vous et rend le temps plus lisible',
    notes: 'Capture vite textes, images, listes et notes rapides',
    reminders: 'Suit les tâches et petits rappels du quotidien',
    photos: 'Gère, retouche et synchronise la photothèque système',
    music: 'Lit la musique locale et en streaming sur Mac',
    terminal: 'Entrée ligne de commande pour contrôler finement le Mac',
    'activity-monitor': 'Affiche CPU, mémoire, énergie et processus lourds',
    'airport-utility': 'Gère les appareils réseau AirPort et Time Capsule',
    'app-store': 'Boutique Mac officielle pour apps, mises à jour et abonnements',
    apps: 'Entrée système légère pour ouvrir les apps installées',
    'audio-midi-setup': 'Configure les périphériques audio et le routage MIDI',
    automator: 'Crée des automatisations Mac sans écrire de code',
    'bluetooth-file-exchange': 'Envoie et reçoit des fichiers par Bluetooth',
    books: 'Lit et organise les livres numériques sur Mac',
    'boot-camp-assistant': 'Guide officiel pour installer Windows sur Mac Intel',
    calculator: 'Calculatrice avec conversions et mode programmeur',
    chess: "Jeu d'échecs intégré pour pauses courtes et entraînement",
    clock: 'Alarmes, minuteurs, chronomètre et horloges mondiales',
    'colorsync-utility': 'Affiche et répare les profils couleur pour écran et impression',
    console: 'Consulte les journaux système pour diagnostiquer les problèmes',
    contacts: 'Carnet central utilisé par Mail, Messages et FaceTime',
    dictionary: 'Dictionnaire hors ligne pour ecrire et chercher',
    'digital-color-meter': "Prélève précisément les couleurs à l'écran",
    'disk-utility': 'Gère disques, partitions, formatage et premiers secours',
    'find-my': 'Localise appareils, objets et Mac égaré',
    'font-book': 'Installe, prévisualise et gère les polices',
    freeform: 'Tableau blanc infini pour idées, croquis et brainstorming',
    games: 'Hub de jeux Apple pour Apple Arcade et contenus jouables',
    grapher: 'Trace des équations et visualise les mathématiques',
    home: 'Contrôle lumières, climat et accessoires connectés',
    'image-capture': 'Importe des images depuis appareils photo et scanners',
    'image-playground': 'Crée des images avec Apple Intelligence pour brouillons rapides',
    imovie: 'Montage vidéo simple pour films de famille et projets légers',
    'iphone-mirroring': "Contrôle l'iPhone directement depuis le Mac",
    journal: 'Note les moments du quotidien dans une timeline privée',
    keynote: 'Crée des présentations Apple soignées',
    magnifier: "Agrandit les détails de l'écran pour lire et vérifier",
    maps: "Consulte itinéraires, villes et envoie des destinations à l'iPhone",
    'migration-assistant': "Déplace les données d'un ancien Mac vers un nouveau",
    'mission-control': "Affiche fenêtres et bureaux quand l'espace devient chargé",
    news: 'Lit des articles et médias sélectionnés par Apple News',
    numbers: 'Tableur Apple pour rapports légers et propres',
    pages: 'Traitement de texte Apple pour documents et mise en page',
    passwords: "Gère mots de passe, codes de vérification et clés d'accès",
    phone: "Passe et reçoit des appels Mac via l'iPhone",
    'photo-booth': 'Prend des selfies caméra et teste des effets amusants',
    podcasts: 'Écoute des podcasts pour trajets, études et pauses',
    preview: 'Affiche images, annote PDF et fait des retouches rapides',
    'print-center': "Affiche et gère files d'impression et tâches bloquées",
    'quicktime-player': "Lit des médias et enregistre écran ou audio",
    'screen-sharing': 'Contrôle un autre Mac à distance pour aider ou dépanner',
    screenshot: "Capture images et enregistrements de l'écran",
    'script-editor': 'Écrit et lance des automatisations AppleScript',
    'sf-symbols': 'Parcourt les symboles Apple pour interfaces natives',
    shortcuts: 'Combine des actions en workflows rapides',
    siri: "Assistant vocal pour recherche, ouverture d'apps et réglages",
    stickies: 'Post-it de bureau pour rappels temporaires',
    stocks: 'Suit les actions et marchés dans un panneau compact',
    'system-information': 'Affiche les détails matériel, logiciel et appareils',
    'system-settings': 'Centre des réglages Mac et options système',
    textedit: 'Éditeur simple pour fichiers TXT et RTF',
    'time-machine': 'Sauvegarde système pour restaurer des fichiers plus tard',
    tips: 'Astuces Apple pour découvrir des fonctions macOS utiles',
    tv: 'Lit et gère films et contenus TV',
    'voice-memos': 'Enregistre vite idées, réunions et interviews',
    'voiceover-utility': "Gère les réglages d'accessibilité VoiceOver",
    weather: 'Consulte la météo avant de sortir',
    xcode: 'Outils Apple pour développer des apps iOS et macOS',
    garageband: 'Création musicale Apple simple pour enregistrer et arranger',
    'final-cut-pro': 'Montage video pro Apple pour coupe, couleur et export',
    'logic-pro': 'Production musicale pro Apple pour enregistrer, arranger et mixer',
    testflight: 'Installe et teste les versions bêta des apps Apple'
  },
  ja: {
    finder: 'Macのファイル、フォルダ、ディスク、接続デバイスを管理',
    safari: '高速で省電力、プライバシー重視のApple公式ブラウザ',
    mail: '複数のメールアカウントをまとめて管理する標準メールアプリ',
    messages: 'MacからiMessageやSMSをすばやく送受信',
    facetime: 'Appleデバイス間の音声通話とビデオ通話',
    calendar: '予定を整理し、時間を見やすく管理',
    notes: 'テキスト、画像、リストをすばやく残せる標準メモ',
    reminders: '日々のToDoや小さな用事を忘れず管理',
    photos: '写真ライブラリの管理、編集、同期の入口',
    music: 'Macでローカル音楽やストリーミングを再生',
    terminal: 'コマンド入力でMacを細かく操作',
    'activity-monitor': 'CPU、メモリ、電力、重いプロセスを一覧確認',
    'airport-utility': 'AirPortやTime Capsuleを管理するネットワークツール',
    'app-store': 'Macアプリ、アップデート、サブスクを探す公式ストア',
    apps: 'インストール済みアプリをすばやく開くシステム入口',
    'audio-midi-setup': 'オーディオ機器とMIDIルーティングを設定',
    automator: 'コードなしでMacの自動化ワークフローを作成',
    'bluetooth-file-exchange': '必要なときにBluetoothでファイルを送受信',
    books: 'Macで電子書籍を読んで管理',
    'boot-camp-assistant': 'Intel MacにWindowsを入れる公式ガイド',
    calculator: '単位換算やプログラマーモードも備えた計算機',
    chess: 'Mac内蔵のチェスゲーム。短い休憩や練習に便利',
    clock: 'アラーム、タイマー、ストップウォッチ、世界時計を一括管理',
    'colorsync-utility': '画面と印刷の色差に使うカラープロファイル管理',
    console: '問題調査に使うシステムログ表示ツール',
    contacts: 'メール、メッセージ、FaceTimeで使う連絡先の中心',
    dictionary: 'オフライン辞書と類語辞典で言葉をすばやく確認',
    'digital-color-meter': '画面上の色を正確に取得するツール',
    'disk-utility': 'ディスク、パーティション、フォーマット、First Aidを管理',
    'find-my': 'デバイス、持ち物、なくしたMacを探す',
    'font-book': 'フォントのインストール、プレビュー、管理',
    freeform: 'アイデア、スケッチ、ブレストに使える無限ホワイトボード',
    games: 'Apple Arcadeなどのゲームをまとめて管理',
    grapher: '方程式をグラフ化し、数学を視覚化',
    home: '照明、空調、スマートホーム機器を操作',
    'image-capture': 'カメラやスキャナから画像を取り込む',
    'image-playground': 'Apple Intelligenceで画像案をすばやく作成',
    imovie: '家庭動画や軽い作品向けのシンプルな動画編集',
    'iphone-mirroring': 'MacからiPhoneを直接操作',
    journal: '日々の出来事を自分だけのタイムラインに記録',
    keynote: 'Appleらしい美しいプレゼンを作成',
    magnifier: '画面の細部を拡大して読み取りや確認を補助',
    maps: '経路や街を確認し、目的地をiPhoneへ送信',
    'migration-assistant': '古いMacのデータを新しいMacへ移行',
    'mission-control': '混み合ったウインドウとデスクトップを一覧表示',
    news: 'Apple Newsの記事やメディアを読む',
    numbers: '軽いレポート作成に向いたAppleの表計算アプリ',
    pages: '文書作成とレイアウトに使うAppleのワープロ',
    passwords: 'パスワード、確認コード、パスキーをまとめて管理',
    phone: 'iPhone経由でMacから電話を発着信',
    'photo-booth': 'カメラの自撮りや楽しいエフェクトを試す',
    podcasts: '通勤、勉強、休憩にポッドキャストを再生',
    preview: '画像表示、PDF注釈、簡単な編集に使える標準ツール',
    'print-center': '印刷キューや止まった印刷ジョブを管理',
    'quicktime-player': 'メディア再生、画面収録、音声録音に対応',
    'screen-sharing': '別のMacを遠隔操作して支援や確認を行う',
    screenshot: 'スクリーンショットと画面収録を開始',
    'script-editor': 'AppleScriptを書いて実行する自動化ツール',
    'sf-symbols': 'ネイティブUI用のApple公式シンボルを閲覧',
    shortcuts: '複数の操作をすばやいワークフローにまとめる',
    siri: '検索、アプリ起動、システム操作に使う音声アシスタント',
    stickies: '一時的なメモをデスクトップに貼れる付箋',
    stocks: '株価と市場の動きを小さなパネルで確認',
    'system-information': 'ハードウェア、ソフトウェア、デバイス情報を詳しく表示',
    'system-settings': 'Macの設定とシステム項目をまとめて管理',
    textedit: 'TXTやRTFをすばやく開けるシンプルなテキストエディタ',
    'time-machine': '後でファイルを戻せるシステムバックアップ',
    tips: 'macOSの便利な機能を見つけるApple公式ヒント',
    tv: '映画やテレビ番組の再生と管理',
    'voice-memos': 'アイデア、会議、インタビューをすばやく録音',
    'voiceover-utility': 'VoiceOverなど読み上げ支援の設定を管理',
    weather: '外出前に天気予報を確認',
    xcode: 'iOSやmacOSアプリ開発向けのApple公式ツール',
    garageband: '録音や編曲を始めやすいAppleの音楽制作アプリ',
    'final-cut-pro': 'カット、カラー、書き出しに強いAppleのプロ動画編集',
    'logic-pro': '録音、編曲、ミックスに強いAppleのプロ音楽制作',
    testflight: 'Appleアプリのベータ版をインストールして試用'
  },
  ko: {
    terminal: '명령줄 입력 창으로 Mac을 세밀하게 제어합니다'
  }
}

const latinDanglingWords = new Set([
  'a', 'an', 'and', 'as', 'at', 'by', 'for', 'from', 'in', 'of', 'on', 'or', 'the', 'to',
  'und', 'oder', 'zu', 'fur', 'für', 'von', 'der', 'die', 'das', 'ein', 'eine',
  'et', 'ou', 'de', 'des', 'du', 'la', 'le', 'les', 'pour', 'avec', 'dans',
  'y', 'o', 'el', 'los', 'las', 'del', 'para', 'con', 'en',
  'e', 'di', 'dei', 'della', 'per', 'con',
  'ou', 'do', 'dos', 'das', 'com',
  'i', 'oraz', 'do', 'dla', 'z', 'w',
  'si', 'sau', 'cu', 'din', 'pentru',
  've', 'veya', 'ile', 'icin', 'için',
  'dan', 'atau', 'untuk', 'dengan',
  'og', 'eller', 'til', 'med',
  'en', 'of', 'voor', 'met'
])

const cyrillicDanglingWords = new Set(['и', 'или', 'в', 'во', 'на', 'для', 'с', 'со', 'к', 'у', 'та', 'або', 'і'])

function lengthOf(value) {
  return Array.from(value).length
}

function trimCodePoints(value, max) {
  return Array.from(value).slice(0, max).join('')
}

function stripDanglingWords(value) {
  let result = value.trim().replace(/[\\s,;:，、。.!?！？؛؟]+$/u, '')
  for (let i = 0; i < 3; i += 1) {
    const parts = result.split(/\\s+/u)
    if (parts.length < 2) break
    const last = parts[parts.length - 1].toLocaleLowerCase('und').replace(/[.,;:!?]+$/u, '')
    if (!latinDanglingWords.has(last) && !cyrillicDanglingWords.has(last)) break
    parts.pop()
    result = parts.join(' ')
  }
  return result.trim()
}

function repairLikelyClippedNote(note, lang) {
  if (lengthOf(note) < 78) return note

  const normalized = note.replace(/\\s+/gu, ' ').trim()
  const maxSoftLength = 72
  const bounded = trimCodePoints(normalized, maxSoftLength)
  const cutCandidates = []

  for (const marker of ['. ', '! ', '? ', '。', '！', '？', '; ', '；', ': ', '：', ', ', '，', '、']) {
    const index = bounded.lastIndexOf(marker)
    if (index >= 24) {
      cutCandidates.push(index + (marker.trim().length === 0 ? 0 : marker.length))
    }
  }

  let repaired
  if (cutCandidates.length > 0) {
    repaired = bounded.slice(0, Math.max(...cutCandidates))
  } else {
    const lastSpace = bounded.lastIndexOf(' ')
    repaired = lastSpace >= 24 ? bounded.slice(0, lastSpace) : bounded
  }

  repaired = stripDanglingWords(repaired)

  if (!/[。.!?！？؟]$/u.test(repaired) && !['zh-Hans', 'zh-Hant', 'ja', 'ko', 'th'].includes(lang)) {
    repaired += '.'
  }

  return repaired
}

function loctableKeysForLanguage(language) {
  switch (language) {
    case 'zh-Hans':
      return ['zh_CN', 'zh_Hans', 'zh']
    case 'zh-Hant':
      return ['zh_TW', 'zh_HK', 'zh_Hant', 'zh']
    case 'pt-BR':
      return ['pt_BR', 'pt']
    case 'sr-Cyrl':
      return ['sr_Cyrl', 'sr']
    case 'ar-Najdi':
      return ['ar']
    case 'nn':
      return ['nn', 'no', 'nb']
    case 'nb':
      return ['nb', 'no']
    case 'no':
      return ['no', 'nb']
    default:
      return [language, language.replaceAll('-', '_'), language.split('-')[0]]
  }
}

function loadLoctable(appPath) {
  const loctablePath = path.join(appPath, 'Contents', 'Resources', 'InfoPlist.loctable')
  if (!fs.existsSync(loctablePath)) return {}
  try {
    const raw = execFileSync('/usr/bin/plutil', ['-convert', 'json', '-o', '-', loctablePath], {
      encoding: 'utf8',
      maxBuffer: 2 * 1024 * 1024
    })
    return JSON.parse(raw)
  } catch {
    return {}
  }
}

function officialDisplayName(app, language) {
  const table = loadLoctable(app.appPath)
  for (const key of loctableKeysForLanguage(language)) {
    const localized = table[key]
    if (!localized || typeof localized !== 'object') continue
    const displayName = normalizedNonEmpty(localized.CFBundleDisplayName)
      ?? normalizedNonEmpty(localized.CFBundleName)
    if (displayName) return displayName
  }
  return app.fallbackName
}

function normalizedNonEmpty(value) {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
}

function ensureCoreServiceTranslations() {
  let displayNameCount = 0
  let noteCount = 0
  const supportedLanguages = translations.supportedLanguages ?? []
  for (const language of supportedLanguages) {
    const displayTarget = translations.displayNamesByLanguage[language]
      ?? (translations.displayNamesByLanguage[language] = {})
    const noteTarget = translations.notesByLanguage[language]
      ?? (translations.notesByLanguage[language] = {})
    const notes = coreServiceNotesByLanguage[language]
    if (!notes || notes.length !== coreServiceNoteIDs.length) {
      throw new Error(`Missing CoreServices notes for language: ${language}`)
    }

    for (const [index, id] of coreServiceNoteIDs.entries()) {
      const app = coreServiceApps[index]
      const displayName = officialDisplayName(app, language)
      const note = notes[index]
      if (lengthOf(note) > translations.noteLimit) {
        throw new Error(`CoreServices note exceeds limit for ${language}/${id}: ${lengthOf(note)}`)
      }
      if (displayTarget[id] !== displayName) {
        displayTarget[id] = displayName
        displayNameCount += 1
      }
      if (noteTarget[id] !== note) {
        noteTarget[id] = note
        noteCount += 1
      }
    }
  }
  return { displayNameCount, noteCount }
}

const coreServiceUpdate = ensureCoreServiceTranslations()

let replacementCount = 0
for (const [language, notes] of Object.entries(curatedNotes)) {
  const target = translations.notesByLanguage[language]
  if (!target) {
    throw new Error(`Missing language in translations: ${language}`)
  }
  for (const [id, note] of Object.entries(notes)) {
    if (!(id in target)) {
      throw new Error(`Missing note id for ${language}: ${id}`)
    }
    if (lengthOf(note) > translations.noteLimit) {
      throw new Error(`Curated note exceeds limit for ${language}/${id}: ${lengthOf(note)}`)
    }
    if (target[id] !== note) {
      target[id] = note
      replacementCount += 1
    }
  }
}

let clippedRepairCount = 0
for (const [language, notes] of Object.entries(translations.notesByLanguage)) {
  for (const [id, note] of Object.entries(notes)) {
    const repaired = repairLikelyClippedNote(note, language)
    if (repaired !== note) {
      if (lengthOf(repaired) > translations.noteLimit) {
        throw new Error(`Repaired note exceeds limit for ${language}/${id}: ${lengthOf(repaired)}`)
      }
      notes[id] = repaired
      clippedRepairCount += 1
    }
  }
}

translations.generatedAt = new Date().toISOString()
fs.writeFileSync(translationsPath, `${JSON.stringify(translations, null, 2)}\n`)

console.log(`Updated ${translationsPath}`)
console.log(`CoreServices display names updated: ${coreServiceUpdate.displayNameCount}`)
console.log(`CoreServices notes updated: ${coreServiceUpdate.noteCount}`)
console.log(`Curated replacements: ${replacementCount}`)
console.log(`Clipped-note repairs: ${clippedRepairCount}`)
