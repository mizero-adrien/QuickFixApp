import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('fr'), Locale('rw')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppLocalizationsProvider>();
    assert(provider != null, 'No AppLocalizationsProvider found in context');
    return provider!.localizations;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'QuickFix',
      'login': 'Login',
      'signup': 'Sign Up',
      'emailHint': 'e.g. john@gmail.com',
      'passwordHint': 'Enter your password',
      'loginButton': 'Login',
      'signupButton': 'Create Account',
      'forgotPassword': 'Forgot password?',
      'dontHaveAccount': 'Don\'t have an account?',
      'alreadyHaveAccount': 'Already have an account?',
      'home': 'Home',
      'profile': 'Profile',
      'search': 'Search',
      'jobs': 'My Jobs',
      'postAJob': 'Post a Job',
      'goodMorning': 'Good morning, {name}!',
      'findTrustedArtisans': 'Find trusted artisans in Kigali.',
      'gasaboKigali': 'Gasabo, Kigali',
      'searchHint': 'Search for a plumber, electrician...',
      'all': 'All',
      'availableNearYou': 'Available Near You',
      'seeAll': 'See All',
      'topRatedThisWeek': 'Top Rated This Week',
      'availableNow': 'Available Now',
      'unavailable': 'Unavailable',
      'startingFrom': 'Starting from',
      'bookNow': 'Book Now',
      'reviews': 'Reviews',
      'totalReviews': '{count} total',
      'postJobScreenTitle': 'Post a Job',
      'describeJobHint': 'Describe your job and artisans will send you their best quotes.',
      'serviceType': 'Service Type',
      'selectServiceCategory': 'Select a service category',
      'jobTitle': 'Job Title',
      'jobTitleHint': 'e.g. Burst pipe in kitchen',
      'locationAddress': 'Location / Address',
      'locationHint': 'e.g. KG 15 Ave, Gasabo',
      'preferredDate': 'Preferred Date',
      'selectDate': 'Select a date',
      'budget': 'Your Budget (RWF)',
      'budgetHint': 'e.g. 10000',
      'phoneNumber': 'Phone Number',
      'phoneHint': 'e.g. 0788123456',
      'jobDescription': 'Job Description',
      'jobDescriptionHint': 'Describe the problem in detail...',
      'postJobRequest': 'Post Job Request',
      'backToHome': 'Back to Home',
      'profileTitle': 'Profile',
      'language': 'Language',
      'english': 'English',
      'french': 'French',
      'kinyarwanda': 'Kinyarwanda',
      'selectLanguage': 'Select Language',
      'noArtisansFound': 'No artisans found for this category.',
      'homeScreenTitle': 'QuickFix',
      'artisanDashboard': 'Artisan Dashboard',
      'categories': 'Categories',
      'categoryPlumber': 'Plumber',
      'categoryElectrician': 'Electrician',
      'categoryCarpenter': 'Carpenter',
      'categoryPainter': 'Painter',
      'categoryCleaning': 'Cleaning',
      'categoryMasonry': 'Masonry',
      'categoryOther': 'Other',
      'loginTitle': 'Welcome back',
      'signupTitle': 'Create your account',
      'nameHint': 'e.g. Jean Pierre Habimana',
      'phoneHintSignup': 'e.g. 781234567',
      'passwordRules': 'At least 6 characters',
      'confirmPasswordHint': 'Re-enter your password',
      'confirmPassword': 'Confirm Password',
      'bookings': 'Bookings',
      'description': 'Description',
      'availableSoon': 'Available soon',
      'verification': 'Verified artisan',
      'yearsExperience': 'Years of experience',
      'experienceHint': 'e.g. 5',
      'priceHint': 'e.g. 5000',
      'detailsHint': 'Tell homeowners about your skills and availability',
      'submit': 'Submit',
      'loginError': 'Please enter a valid email and password',
      'emailRequired': 'Please enter your email',
      'passwordRequired': 'Please enter your password',
      'jobTitleRequired': 'Please enter a job title',
      'jobTitleLength': 'Title must be at least 5 characters',
      'locationRequired': 'Please enter your location',
      'locationLength': 'Please enter a more detailed address',
      'dateRequired': 'Please select a preferred date',
      'budgetRequired': 'Please enter your budget',
      'budgetInvalid': 'Please enter a valid amount in RWF',
      'budgetMin': 'Minimum budget is 1,000 RWF',
      'phoneRequired': 'Please enter your phone number',
      'phoneDigits': 'Phone number must be 9 digits',
      'descriptionRequired': 'Please describe the job',
      'descriptionLength': 'Description must be at least 20 characters',
      'serviceRequired': 'Please select a service type',
      'verificationDialog': 'Job Posted! Artisans near you will start sending bids shortly.',
    },
    'fr': {
      'appTitle': 'QuickFix',
      'login': 'Connexion',
      'signup': 'Inscription',
      'emailHint': 'ex. john@gmail.com',
      'passwordHint': 'Entrez votre mot de passe',
      'loginButton': 'Se connecter',
      'signupButton': 'Créer un compte',
      'forgotPassword': 'Mot de passe oublié ?',
      'dontHaveAccount': 'Vous n\'avez pas de compte ?',
      'alreadyHaveAccount': 'Vous avez déjà un compte ?',
      'home': 'Accueil',
      'profile': 'Profil',
      'search': 'Recherche',
      'jobs': 'Mes travaux',
      'postAJob': 'Publier un travail',
      'goodMorning': 'Bonjour, {name} !',
      'findTrustedArtisans': 'Trouvez des artisans de confiance à Kigali.',
      'gasaboKigali': 'Gasabo, Kigali',
      'searchHint': 'Recherchez un plombier, électricien...',
      'all': 'Tous',
      'availableNearYou': 'Disponibles près de chez vous',
      'seeAll': 'Voir tout',
      'topRatedThisWeek': 'Les mieux notés cette semaine',
      'availableNow': 'Disponible maintenant',
      'unavailable': 'Indisponible',
      'startingFrom': 'À partir de',
      'bookNow': 'Réserver',
      'reviews': 'Avis',
      'totalReviews': '{count} au total',
      'postJobScreenTitle': 'Publier un travail',
      'describeJobHint': 'Décrivez votre travail et des artisans vous enverront leurs meilleures offres.',
      'serviceType': 'Type de service',
      'selectServiceCategory': 'Sélectionnez une catégorie de service',
      'jobTitle': 'Titre du travail',
      'jobTitleHint': 'ex. Tuyau fissuré dans la cuisine',
      'locationAddress': 'Emplacement / Adresse',
      'locationHint': 'ex. KG 15 Ave, Gasabo',
      'preferredDate': 'Date préférée',
      'selectDate': 'Sélectionnez une date',
      'budget': 'Votre budget (RWF)',
      'budgetHint': 'ex. 10000',
      'phoneNumber': 'Numéro de téléphone',
      'phoneHint': 'ex. 0788123456',
      'jobDescription': 'Description du travail',
      'jobDescriptionHint': 'Décrivez le problème en détail...',
      'postJobRequest': 'Publier la demande',
      'backToHome': 'Retour à l\'accueil',
      'profileTitle': 'Profil',
      'language': 'Langue',
      'english': 'Anglais',
      'french': 'Français',
      'kinyarwanda': 'Kinyarwanda',
      'selectLanguage': 'Choisir la langue',
      'noArtisansFound': 'Aucun artisan trouvé pour cette catégorie.',
      'homeScreenTitle': 'QuickFix',
      'artisanDashboard': 'Tableau de bord artisan',
      'categories': 'Catégories',
      'categoryPlumber': 'Plombier',
      'categoryElectrician': 'Électricien',
      'categoryCarpenter': 'Menuisier',
      'categoryPainter': 'Peintre',
      'categoryCleaning': 'Nettoyage',
      'categoryMasonry': 'Maçonnerie',
      'categoryOther': 'Autre',
      'loginTitle': 'Bienvenue',
      'signupTitle': 'Créez votre compte',
      'nameHint': 'ex. Jean Pierre Habimana',
      'phoneHintSignup': 'ex. 781234567',
      'passwordRules': 'Au moins 6 caractères',
      'confirmPasswordHint': 'Resaisissez votre mot de passe',
      'confirmPassword': 'Confirmez le mot de passe',
      'bookings': 'Réservations',
      'description': 'Description',
      'availableSoon': 'Disponible bientôt',
      'verification': 'Artisan vérifié',
      'yearsExperience': 'Années d\'expérience',
      'experienceHint': 'ex. 5',
      'priceHint': 'ex. 5000',
      'detailsHint': 'Parlez aux propriétaires de vos compétences et de votre disponibilité',
      'submit': 'Soumettre',
      'loginError': 'Veuillez entrer un email et un mot de passe valides',
      'emailRequired': 'Veuillez entrer votre email',
      'passwordRequired': 'Veuillez entrer votre mot de passe',
      'jobTitleRequired': 'Veuillez entrer un titre',
      'jobTitleLength': 'Le titre doit comporter au moins 5 caractères',
      'locationRequired': 'Veuillez entrer votre emplacement',
      'locationLength': 'Veuillez entrer une adresse plus détaillée',
      'dateRequired': 'Veuillez sélectionner une date préférée',
      'budgetRequired': 'Veuillez entrer votre budget',
      'budgetInvalid': 'Veuillez entrer un montant valide en RWF',
      'budgetMin': 'Le budget minimum est de 1 000 RWF',
      'phoneRequired': 'Veuillez entrer votre numéro de téléphone',
      'phoneDigits': 'Le numéro doit comporter 9 chiffres',
      'descriptionRequired': 'Veuillez décrire le travail',
      'descriptionLength': 'La description doit comporter au moins 20 caractères',
      'serviceRequired': 'Veuillez sélectionner un type de service',
      'verificationDialog': 'Travail publié ! Les artisans près de chez vous commenceront bientôt à envoyer des offres.',
    },
    'rw': {
      'appTitle': 'QuickFix',
      'login': 'Injira',
      'signup': 'Iyandikishe',
      'emailHint': 'urug. john@gmail.com',
      'passwordHint': 'Injiza ijambo ryibanga ryawe',
      'loginButton': 'Injira',
      'signupButton': 'Iyandikishe',
      'forgotPassword': 'Wibagiwe ijambo ryibanga?',
      'dontHaveAccount': 'Nta konti ufite?',
      'alreadyHaveAccount': 'Usanzwe ufite konti?',
      'home': 'Ahabanza',
      'profile': 'Umwirondoro',
      'search': 'Shakisha',
      'jobs': 'Imirimo yanjye',
      'postAJob': 'Ohereza akazi',
      'goodMorning': 'Mwaramutse, {name} !',
      'findTrustedArtisans': 'Shaka abakozi bizewe i Kigali.',
      'gasaboKigali': 'Gasabo, Kigali',
      'searchHint': 'Shakisha plumber, electronicien...',
      'all': 'Byose',
      'availableNearYou': 'Baboneka hafi yawe',
      'seeAll': 'Reba byose',
      'topRatedThisWeek': 'Bashyizwe hejuru muri iki cyumweru',
      'availableNow': 'Biboneka ubu',
      'unavailable': 'Ntaboneka',
      'startingFrom': 'Bitangiriye kuri',
      'bookNow': 'Tegura',
      'reviews': 'Ibyo abakiriya bavuga',
      'totalReviews': '{count} byose',
      'postJobScreenTitle': 'Ohereza akazi',
      'describeJobHint': 'Sobanura akazi kawe maze abakozi bazohereze ibiciro byiza.',
      'serviceType': 'Ubwoko bwakazi',
      'selectServiceCategory': 'Hitamo icyiciro cyakazi',
      'jobTitle': 'Umutwe wakazi',
      'jobTitleHint': 'urug. Umuyoboro waguye mu gikoni',
      'locationAddress': 'Aho akazi giherereye / Aderesi',
      'locationHint': 'urug. KG 15 Ave, Gasabo',
      'preferredDate': 'Itariki ushaka',
      'selectDate': 'Hitamo itariki',
      'budget': 'Ingengo y’imari yawe (RWF)',
      'budgetHint': 'urug. 10000',
      'phoneNumber': 'Nimero ya telefone',
      'phoneHint': 'urug. 0788123456',
      'jobDescription': 'Ibisobanuro byakazi',
      'jobDescriptionHint': 'Sobanura ikibazo mu buryo burambuye...',
      'postJobRequest': 'Ohereza icyifuzo cyakazi',
      'backToHome': 'Subira ku rubuga rwibanze',
      'profileTitle': 'Umwirondoro',
      'language': 'Ururimi',
      'english': 'Icyongereza',
      'french': 'Igifaransa',
      'kinyarwanda': 'Ikinyarwanda',
      'selectLanguage': 'Hitamo ururimi',
      'noArtisansFound': 'Nta mukozi wabonetse kuri iki cyiciro.',
      'homeScreenTitle': 'QuickFix',
      'artisanDashboard': 'Akayunguruzo k’umukozi',
      'categories': 'Ibyiciro',
      'categoryPlumber': 'Plumber',
      'categoryElectrician': 'Elektrisheni',
      'categoryCarpenter': 'Umubaji',
      'categoryPainter': 'Umubaji',
      'categoryCleaning': 'Isuku',
      'categoryMasonry': 'Guhinga',
      'categoryOther': 'Ibindi',
      'loginTitle': 'Murakaza neza',
      'signupTitle': 'Hanga konti yawe',
      'nameHint': 'urug. Jean Pierre Habimana',
      'phoneHintSignup': 'urug. 781234567',
      'passwordRules': 'Nibura inyuguti 6',
      'confirmPasswordHint': 'Andika ijambo ryibanga ryawe kabiri',
      'confirmPassword': 'Emeza ijambo ryibanga',
      'bookings': 'Ibitumizwa',
      'description': 'Ibisobanuro',
      'availableSoon': 'Bizaboneka vuba',
      'verification': 'Umukozi wemejwe',
      'yearsExperience': 'Imyaka y’uburambe',
      'experienceHint': 'urug. 5',
      'priceHint': 'urug. 5000',
      'detailsHint': 'Sobanura ubumenyi bwawe n’igihe uboneka',
      'submit': 'Ohereza',
      'loginError': 'Injiza email na password byemewe',
      'emailRequired': 'Injiza email yawe',
      'passwordRequired': 'Injiza ijambo ryibanga',
      'jobTitleRequired': 'Injiza umutwe wakazi',
      'jobTitleLength': 'Umutwe ugomba kugira nibura inyuguti 5',
      'locationRequired': 'Injiza aho uri',
      'locationLength': 'Tanga aderesi irambuye',
      'dateRequired': 'Hitamo itariki',
      'budgetRequired': 'Injiza ingengo y’imari',
      'budgetInvalid': 'Injiza amafaranga yemewe muri RWF',
      'budgetMin': 'Ingengo y’imari ntoya ni 1,000 RWF',
      'phoneRequired': 'Injiza nimero ya telefone',
      'phoneDigits': 'Nimero igomba kugira inyuguti 9',
      'descriptionRequired': 'Sobanura akazi',
      'descriptionLength': 'Ibisobanuro bigomba kugira nibura inyuguti 20',
      'serviceRequired': 'Hitamo ubwoko bwakazi',
      'verificationDialog': 'Akazi koherejwe! Abakozi hafi yawe bazohereza ibiciro vuba.',
    },
  };

  String _translate(String key, [Map<String, String>? args]) {
    final languageCode = locale.languageCode;
    final value = _localizedValues[languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
    if (args == null || args.isEmpty) {
      return value;
    }
    var result = value;
    args.forEach((argKey, argValue) {
      result = result.replaceAll('{$argKey}', argValue);
    });
    return result;
  }

  String get appTitle => _translate('appTitle');
  String get login => _translate('login');
  String get signup => _translate('signup');
  String get emailHint => _translate('emailHint');
  String get passwordHint => _translate('passwordHint');
  String get loginButton => _translate('loginButton');
  String get signupButton => _translate('signupButton');
  String get forgotPassword => _translate('forgotPassword');
  String get dontHaveAccount => _translate('dontHaveAccount');
  String get alreadyHaveAccount => _translate('alreadyHaveAccount');
  String get home => _translate('home');
  String get profile => _translate('profile');
  String get search => _translate('search');
  String get jobs => _translate('jobs');
  String get postAJob => _translate('postAJob');
  String goodMorning(String name) => _translate('goodMorning', {'name': name});
  String get findTrustedArtisans => _translate('findTrustedArtisans');
  String get gasaboKigali => _translate('gasaboKigali');
  String get searchHint => _translate('searchHint');
  String get all => _translate('all');
  String get availableNearYou => _translate('availableNearYou');
  String get seeAll => _translate('seeAll');
  String get topRatedThisWeek => _translate('topRatedThisWeek');
  String get availableNow => _translate('availableNow');
  String get unavailable => _translate('unavailable');
  String get startingFrom => _translate('startingFrom');
  String get bookNow => _translate('bookNow');
  String get reviews => _translate('reviews');
  String totalReviews(int count) => _translate('totalReviews', {'count': count.toString()});
  String get postJobScreenTitle => _translate('postJobScreenTitle');
  String get describeJobHint => _translate('describeJobHint');
  String get serviceType => _translate('serviceType');
  String get selectServiceCategory => _translate('selectServiceCategory');
  String get jobTitle => _translate('jobTitle');
  String get jobTitleHint => _translate('jobTitleHint');
  String get locationAddress => _translate('locationAddress');
  String get locationHint => _translate('locationHint');
  String get preferredDate => _translate('preferredDate');
  String get selectDate => _translate('selectDate');
  String get budget => _translate('budget');
  String get budgetHint => _translate('budgetHint');
  String get phoneNumber => _translate('phoneNumber');
  String get phoneHint => _translate('phoneHint');
  String get jobDescription => _translate('jobDescription');
  String get jobDescriptionHint => _translate('jobDescriptionHint');
  String get postJobRequest => _translate('postJobRequest');
  String get backToHome => _translate('backToHome');
  String get profileTitle => _translate('profileTitle');
  String get language => _translate('language');
  String get english => _translate('english');
  String get french => _translate('french');
  String get kinyarwanda => _translate('kinyarwanda');
  String get selectLanguage => _translate('selectLanguage');
  String get homeScreenTitle => _translate('homeScreenTitle');
  String get artisanDashboard => _translate('artisanDashboard');
  String get categories => _translate('categories');
  String category(String key) => _translate('category${key[0].toUpperCase()}${key.substring(1)}');
  String get loginTitle => _translate('loginTitle');
  String get signupTitle => _translate('signupTitle');
  String get nameHint => _translate('nameHint');
  String get phoneHintSignup => _translate('phoneHintSignup');
  String get passwordRules => _translate('passwordRules');
  String get confirmPasswordHint => _translate('confirmPasswordHint');
  String get confirmPassword => _translate('confirmPassword');
  String get bookings => _translate('bookings');
  String get description => _translate('description');
  String get availableSoon => _translate('availableSoon');
  String get verification => _translate('verification');
  String get yearsExperience => _translate('yearsExperience');
  String get experienceHint => _translate('experienceHint');
  String get priceHint => _translate('priceHint');
  String get detailsHint => _translate('detailsHint');
  String get submit => _translate('submit');
  String get loginError => _translate('loginError');
  String get emailRequired => _translate('emailRequired');
  String get passwordRequired => _translate('passwordRequired');
  String get jobTitleRequired => _translate('jobTitleRequired');
  String get jobTitleLength => _translate('jobTitleLength');
  String get locationRequired => _translate('locationRequired');
  String get locationLength => _translate('locationLength');
  String get dateRequired => _translate('dateRequired');
  String get budgetRequired => _translate('budgetRequired');
  String get budgetInvalid => _translate('budgetInvalid');
  String get budgetMin => _translate('budgetMin');
  String get phoneRequired => _translate('phoneRequired');
  String get phoneDigits => _translate('phoneDigits');
  String get descriptionRequired => _translate('descriptionRequired');
  String get descriptionLength => _translate('descriptionLength');
  String get serviceRequired => _translate('serviceRequired');
  String get verificationDialog => _translate('verificationDialog');
  String get noArtisansFound => _translate('noArtisansFound');

  static String languageName(String code) {
    switch (code) {
      case 'fr':
        return 'fr';
      case 'rw':
        return 'rw';
      default:
        return 'en';
    }
  }
}

class AppLocalizationsProvider extends InheritedWidget {
  final AppLocalizations localizations;

  const AppLocalizationsProvider({super.key, required this.localizations, required super.child});

  @override
  bool updateShouldNotify(AppLocalizationsProvider oldWidget) => localizations.locale != oldWidget.localizations.locale;
}

class LocaleProvider {
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  static void changeLocale(Locale newLocale) {
    locale.value = newLocale;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future<AppLocalizations>.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
