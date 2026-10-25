import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  // Common
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get store => _localizedValues[locale.languageCode]!['store']!;
  String get cart => _localizedValues[locale.languageCode]!['cart']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;
  String get wishlist => _localizedValues[locale.languageCode]!['wishlist']!;
  String get orders => _localizedValues[locale.languageCode]!['orders']!;
  String get notifications => _localizedValues[locale.languageCode]!['notifications']!;
  String get addToCart => _localizedValues[locale.languageCode]!['addToCart']!;
  String get checkout => _localizedValues[locale.languageCode]!['checkout']!;
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get editProfile => _localizedValues[locale.languageCode]!['editProfile']!;
  String get createStore => _localizedValues[locale.languageCode]!['createStore']!;
  String get addProduct => _localizedValues[locale.languageCode]!['addProduct']!;
  String get darkMode => _localizedValues[locale.languageCode]!['darkMode']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get reviews => _localizedValues[locale.languageCode]!['reviews']!;
  String get orderHistory => _localizedValues[locale.languageCode]!['orderHistory']!;
  String get emptyCart => _localizedValues[locale.languageCode]!['emptyCart']!;
  String get freeShipping => _localizedValues[locale.languageCode]!['freeShipping']!;
  String get total => _localizedValues[locale.languageCode]!['total']!;
  String get apply => _localizedValues[locale.languageCode]!['apply']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get confirm => _localizedValues[locale.languageCode]!['confirm']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get noData => _localizedValues[locale.languageCode]!['noData']!;
  String get connectWithGoogle => _localizedValues[locale.languageCode]!['connectWithGoogle']!;
  String get connectYourWorld => _localizedValues[locale.languageCode]!['connectYourWorld']!;
  String get share => _localizedValues[locale.languageCode]!['share']!;
  String get appearance => _localizedValues[locale.languageCode]!['appearance']!;
  String get account => _localizedValues[locale.languageCode]!['account']!;
  String get others => _localizedValues[locale.languageCode]!['others']!;
  String get security => _localizedValues[locale.languageCode]!['security']!;
  String get helpSupport => _localizedValues[locale.languageCode]!['helpSupport']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get follow => _localizedValues[locale.languageCode]!['follow']!;
  String get followers => _localizedValues[locale.languageCode]!['followers']!;
  String get all => _localizedValues[locale.languageCode]!['all']!;
  String get promos => _localizedValues[locale.languageCode]!['promos']!;
  String get bestSellers => _localizedValues[locale.languageCode]!['bestSellers']!;
  String get deleted => _localizedValues[locale.languageCode]!['deleted']!;
  String get following => _localizedValues[locale.languageCode]!['following']!;
  String get noProducts => _localizedValues[locale.languageCode]!['noProducts']!;
  String get noPromos => _localizedValues[locale.languageCode]!['noPromos']!;
  String get goodQuality => _localizedValues[locale.languageCode]!['goodQuality']!;
  String get information => _localizedValues[locale.languageCode]!['information']!;
  String get location => _localizedValues[locale.languageCode]!['location']!;
  String get website => _localizedValues[locale.languageCode]!['website']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get phone => _localizedValues[locale.languageCode]!['phone']!;
  String get languages => _localizedValues[locale.languageCode]!['languages']!;
  String get shops => _localizedValues[locale.languageCode]!['shops']!;
  String get products => _localizedValues[locale.languageCode]!['products']!;

  // Home Screen
  String get suggestedForYou => _localizedValues[locale.languageCode]!['suggestedForYou']!;
  String get popularProducts => _localizedValues[locale.languageCode]!['popularProducts']!;
  String get newArrivals => _localizedValues[locale.languageCode]!['newArrivals']!;
  String get flashSale => _localizedValues[locale.languageCode]!['flashSale']!;
  String get seeAll => _localizedValues[locale.languageCode]!['seeAll']!;
  String get viewMore => _localizedValues[locale.languageCode]!['viewMore']!;
  String get stories => _localizedValues[locale.languageCode]!['stories']!;

  // Store Screen
  String get allCategories => _localizedValues[locale.languageCode]!['allCategories']!;
  String get popularShops => _localizedValues[locale.languageCode]!['popularShops']!;
  String get todayDeals => _localizedValues[locale.languageCode]!['todayDeals']!;
  String get searchStores => _localizedValues[locale.languageCode]!['searchStores']!;
  String get searchProducts => _localizedValues[locale.languageCode]!['searchProducts']!;

  // Product Detail
  String get color => _localizedValues[locale.languageCode]!['color']!;
  String get size => _localizedValues[locale.languageCode]!['size']!;
  String get description => _localizedValues[locale.languageCode]!['description']!;
  String get sizeGuide => _localizedValues[locale.languageCode]!['sizeGuide']!;
  String get buyNow => _localizedValues[locale.languageCode]!['buyNow']!;
  String get quantity => _localizedValues[locale.languageCode]!['quantity']!;
  String get inStock => _localizedValues[locale.languageCode]!['inStock']!;
  String get outOfStock => _localizedValues[locale.languageCode]!['outOfStock']!;

  // Cart
  String get myCart => _localizedValues[locale.languageCode]!['myCart']!;
  String get nameRequired => _localizedValues[locale.languageCode]!['nameRequired']!;
  String get freeShippingBanner => _localizedValues[locale.languageCode]!['freeShippingBanner']!;
  String get subtotal => _localizedValues[locale.languageCode]!['subtotal']!;
  String get shipping => _localizedValues[locale.languageCode]!['shipping']!;
  String get promoCode => _localizedValues[locale.languageCode]!['promoCode']!;
  String get applyPromo => _localizedValues[locale.languageCode]!['applyPromo']!;
  String get placeOrder => _localizedValues[locale.languageCode]!['placeOrder']!;
  String get emptyCartMessage => _localizedValues[locale.languageCode]!['emptyCartMessage']!;
  String get continueShopping => _localizedValues[locale.languageCode]!['continueShopping']!;

  // Profile
  String get myProfile => _localizedValues[locale.languageCode]!['myProfile']!;
  String get myStores => _localizedValues[locale.languageCode]!['myStores']!;
  String get myOrders => _localizedValues[locale.languageCode]!['myOrders']!;
  String get myWishlist => _localizedValues[locale.languageCode]!['myWishlist']!;
  String get noStoresYet => _localizedValues[locale.languageCode]!['noStoresYet']!;
  String get subscriptions => _localizedValues[locale.languageCode]!['subscriptions']!;
  String get receivedReviews => _localizedValues[locale.languageCode]!['receivedReviews']!;
  String get portfolio => _localizedValues[locale.languageCode]!['portfolio']!;
  String get activity => _localizedValues[locale.languageCode]!['activity']!;
  String get aboutTab => _localizedValues[locale.languageCode]!['aboutTab']!;
  String get noProjects => _localizedValues[locale.languageCode]!['noProjects']!;
  String get addProject => _localizedValues[locale.languageCode]!['addProject']!;
  String get linksAndNetworks => _localizedValues[locale.languageCode]!['linksAndNetworks']!;
  String get recentActivity => _localizedValues[locale.languageCode]!['recentActivity']!;
  String get interactionsHere => _localizedValues[locale.languageCode]!['interactionsHere']!;
  String get aboutMe => _localizedValues[locale.languageCode]!['aboutMe']!;
  String get noBio => _localizedValues[locale.languageCode]!['noBio']!;
  String get memberSince => _localizedValues[locale.languageCode]!['memberSince']!;
  String get country => _localizedValues[locale.languageCode]!['country']!;
  String get coordAndNetworks => _localizedValues[locale.languageCode]!['coordAndNetworks']!;
  String get shareMyProfile => _localizedValues[locale.languageCode]!['shareMyProfile']!;
  String get shareProfileDesc => _localizedValues[locale.languageCode]!['shareProfileDesc']!;
  String get shareProfile => _localizedValues[locale.languageCode]!['shareProfile']!;
  String get myLinkyPage => _localizedValues[locale.languageCode]!['myLinkyPage']!;
  String get previewMyPublicPage => _localizedValues[locale.languageCode]!['previewMyPublicPage']!;
  String get noBioYet => _localizedValues[locale.languageCode]!['noBioYet']!;

  // Checkout
  String get shippingAddress => _localizedValues[locale.languageCode]!['shippingAddress']!;
  String get paymentMethod => _localizedValues[locale.languageCode]!['paymentMethod']!;
  String get orderSummary => _localizedValues[locale.languageCode]!['orderSummary']!;
  String get confirmOrder => _localizedValues[locale.languageCode]!['confirmOrder']!;
  String get cashOnDelivery => _localizedValues[locale.languageCode]!['cashOnDelivery']!;

  // Notifications
  String get allNotifications => _localizedValues[locale.languageCode]!['allNotifications']!;
  String get mentions => _localizedValues[locale.languageCode]!['mentions']!;
  String get promotions => _localizedValues[locale.languageCode]!['promotions']!;
  String get orderUpdates => _localizedValues[locale.languageCode]!['orderUpdates']!;
  String get markAllRead => _localizedValues[locale.languageCode]!['markAllRead']!;
  String get noNotifications => _localizedValues[locale.languageCode]!['noNotifications']!;
  String get notificationsEmptySubtitle => _localizedValues[locale.languageCode]!['notificationsEmptySubtitle']!;

  // Reviews
  String get writeReview => _localizedValues[locale.languageCode]!['writeReview']!;
  String get rating => _localizedValues[locale.languageCode]!['rating']!;
  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get comment => _localizedValues[locale.languageCode]!['comment']!;
  String get submitReview => _localizedValues[locale.languageCode]!['submitReview']!;
  String get noReviewsYet => _localizedValues[locale.languageCode]!['noReviewsYet']!;

  // Common actions
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get back => _localizedValues[locale.languageCode]!['back']!;
  String get next => _localizedValues[locale.languageCode]!['next']!;
  String get done => _localizedValues[locale.languageCode]!['done']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get filter => _localizedValues[locale.languageCode]!['filter']!;
  String get sort => _localizedValues[locale.languageCode]!['sort']!;

  // AliExpress Import
  String get importAliExpress => _localizedValues[locale.languageCode]!['importAliExpress']!;
  String get importFromAliExpress => _localizedValues[locale.languageCode]!['importFromAliExpress']!;
  String get importSubtitle => _localizedValues[locale.languageCode]!['importSubtitle']!;
  String get importAndPreview => _localizedValues[locale.languageCode]!['importAndPreview']!;
  String get publish => _localizedValues[locale.languageCode]!['publish']!;
  String get selectCategory => _localizedValues[locale.languageCode]!['selectCategory']!;
  String get selectSubcategory => _localizedValues[locale.languageCode]!['selectSubcategory']!;
  String get category => _localizedValues[locale.languageCode]!['category']!;

  // Admin & Management (new keys)
  String get activeCodes => _localizedValues[locale.languageCode]!['activeCodes']!;
  String get activeLabel => _localizedValues[locale.languageCode]!['activeLabel']!;
  String get activateStoreFor => _localizedValues[locale.languageCode]!['activateStoreFor']!;
  String get addColor => _localizedValues[locale.languageCode]!['addColor']!;
  String get addSize => _localizedValues[locale.languageCode]!['addSize']!;
  String get adminPanel => _localizedValues[locale.languageCode]!['adminPanel']!;
  String get allCodesCopied => _localizedValues[locale.languageCode]!['allCodesCopied']!;
  String get blocked => _localizedValues[locale.languageCode]!['blocked']!;
  String get brandColorDesc => _localizedValues[locale.languageCode]!['brandColorDesc']!;
  String get brandColorTitle => _localizedValues[locale.languageCode]!['brandColorTitle']!;
  String get brandColorUpdated => _localizedValues[locale.languageCode]!['brandColorUpdated']!;
  String get bulletList => _localizedValues[locale.languageCode]!['bulletList']!;
  String get cancelled => _localizedValues[locale.languageCode]!['cancelled']!;
  String get centerAlign => _localizedValues[locale.languageCode]!['centerAlign']!;
  String get codeCopied => _localizedValues[locale.languageCode]!['codeCopied']!;
  String get codeDeleted => _localizedValues[locale.languageCode]!['codeDeleted']!;
  String get codeFormat => _localizedValues[locale.languageCode]!['codeFormat']!;
  String get closeWindow => _localizedValues[locale.languageCode]!['closeWindow']!;
  String get codesGenerated => _localizedValues[locale.languageCode]!['codesGenerated']!;
  String get codesTab => _localizedValues[locale.languageCode]!['codesTab']!;
  String get codesTotal => _localizedValues[locale.languageCode]!['codesTotal']!;
  String get colors => _localizedValues[locale.languageCode]!['colors']!;
  String get confirmDelete => _localizedValues[locale.languageCode]!['confirmDelete']!;
  String get confirmDeleteStory => _localizedValues[locale.languageCode]!['confirmDeleteStory']!;
  String get confirmed => _localizedValues[locale.languageCode]!['confirmed']!;
  String get copy => _localizedValues[locale.languageCode]!['copy']!;
  String get copyAll => _localizedValues[locale.languageCode]!['copyAll']!;
  String get copyCode => _localizedValues[locale.languageCode]!['copyCode']!;
  String get createProduct => _localizedValues[locale.languageCode]!['createProduct']!;
  String get createdBy => _localizedValues[locale.languageCode]!['createdBy']!;
  String get creationError => _localizedValues[locale.languageCode]!['creationError']!;
  String get customizeColor => _localizedValues[locale.languageCode]!['customizeColor']!;
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get date => _localizedValues[locale.languageCode]!['date']!;
  String get dateMustBeFuture => _localizedValues[locale.languageCode]!['dateMustBeFuture']!;
  String get days => _localizedValues[locale.languageCode]!['days']!;
  String get dayUnit => _localizedValues[locale.languageCode]!['dayUnit']!;
  String get deleteCode => _localizedValues[locale.languageCode]!['deleteCode']!;
  String get deleteConfirm => _localizedValues[locale.languageCode]!['deleteConfirm']!;
  String get delivered => _localizedValues[locale.languageCode]!['delivered']!;
  String get descriptionType => _localizedValues[locale.languageCode]!['descriptionType']!;
  String get disable => _localizedValues[locale.languageCode]!['disable']!;
  String get durationDays => _localizedValues[locale.languageCode]!['durationDays']!;
  String get enable => _localizedValues[locale.languageCode]!['enable']!;
  String get expiredCodes => _localizedValues[locale.languageCode]!['expiredCodes']!;
  String get expiredBlocksStore => _localizedValues[locale.languageCode]!['expiredBlocksStore']!;
  String get expiredLabel => _localizedValues[locale.languageCode]!['expiredLabel']!;
  String get expirationDate => _localizedValues[locale.languageCode]!['expirationDate']!;
  String get filterActive => _localizedValues[locale.languageCode]!['filterActive']!;
  String get filterAll => _localizedValues[locale.languageCode]!['filterAll']!;
  String get filterExpired => _localizedValues[locale.languageCode]!['filterExpired']!;
  String get filterUsed => _localizedValues[locale.languageCode]!['filterUsed']!;
  String get expiresAt => _localizedValues[locale.languageCode]!['expiresAt']!;
  String get expiresOn => _localizedValues[locale.languageCode]!['expiresOn']!;
  String get framed => _localizedValues[locale.languageCode]!['framed']!;
  String get free => _localizedValues[locale.languageCode]!['free']!;
  String get generate => _localizedValues[locale.languageCode]!['generate']!;
  String get generateCodes => _localizedValues[locale.languageCode]!['generateCodes']!;
  String get generateCombinations => _localizedValues[locale.languageCode]!['generateCombinations']!;
  String get generatedCombinations => _localizedValues[locale.languageCode]!['generatedCombinations']!;
  String get generating => _localizedValues[locale.languageCode]!['generating']!;
  String get hourUnit => _localizedValues[locale.languageCode]!['hourUnit']!;
  String get inactive => _localizedValues[locale.languageCode]!['inactive']!;
  String get items => _localizedValues[locale.languageCode]!['items']!;
  String get itemsCount => _localizedValues[locale.languageCode]!['itemsCount']!;
  String get justNow => _localizedValues[locale.languageCode]!['justNow']!;
  String get leftAlign => _localizedValues[locale.languageCode]!['leftAlign']!;
  String get loadingError => _localizedValues[locale.languageCode]!['loadingError']!;
  String get loginSuccess => _localizedValues[locale.languageCode]!['loginSuccess']!;
  String get lowStockWarning => _localizedValues[locale.languageCode]!['lowStockWarning']!;
  String get manageTeam => _localizedValues[locale.languageCode]!['manageTeam']!;
  String get minUnit => _localizedValues[locale.languageCode]!['minUnit']!;
  String get modificationError => _localizedValues[locale.languageCode]!['modificationError']!;
  String get newStory => _localizedValues[locale.languageCode]!['newStory']!;
  String get noCodes => _localizedValues[locale.languageCode]!['noCodes']!;
  String get noName => _localizedValues[locale.languageCode]!['noName']!;
  String get noStores => _localizedValues[locale.languageCode]!['noStores']!;
  String get noUsers => _localizedValues[locale.languageCode]!['noUsers']!;
  String get notVerified => _localizedValues[locale.languageCode]!['notVerified']!;
  String get numberOfCodes => _localizedValues[locale.languageCode]!['numberOfCodes']!;
  String get numberOfDays => _localizedValues[locale.languageCode]!['numberOfDays']!;
  String get openingCamera => _localizedValues[locale.languageCode]!['openingCamera']!;
  String get orChooseDate => _localizedValues[locale.languageCode]!['orChooseDate']!;
  String get orderNumber => _localizedValues[locale.languageCode]!['orderNumber']!;
  String get orderNumberLabel => _localizedValues[locale.languageCode]!['orderNumberLabel']!;
  String get ordersAppearHere => _localizedValues[locale.languageCode]!['ordersAppearHere']!;
  String get overview => _localizedValues[locale.languageCode]!['overview']!;
  String get pending => _localizedValues[locale.languageCode]!['pending']!;
  String get position => _localizedValues[locale.languageCode]!['position']!;
  String get preparing => _localizedValues[locale.languageCode]!['preparing']!;
  String get priceLabel => _localizedValues[locale.languageCode]!['priceLabel']!;
  String get priceRequired => _localizedValues[locale.languageCode]!['priceRequired']!;
  String get priceStock => _localizedValues[locale.languageCode]!['priceStock']!;
  String get productCreated => _localizedValues[locale.languageCode]!['productCreated']!;
  String get productName => _localizedValues[locale.languageCode]!['productName']!;
  String get productPhotos => _localizedValues[locale.languageCode]!['productPhotos']!;
  String get productsCount => _localizedValues[locale.languageCode]!['productsCount']!;
  String get productsTab => _localizedValues[locale.languageCode]!['productsTab']!;
  String get promoPrice => _localizedValues[locale.languageCode]!['promoPrice']!;
  String get renew => _localizedValues[locale.languageCode]!['renew']!;
  String get renewStore => _localizedValues[locale.languageCode]!['renewStore']!;
  String get renewedWithCode => _localizedValues[locale.languageCode]!['renewedWithCode']!;
  String get removeVerification => _localizedValues[locale.languageCode]!['removeVerification']!;
  String get revenue => _localizedValues[locale.languageCode]!['revenue']!;
  String get rightAlign => _localizedValues[locale.languageCode]!['rightAlign']!;
  String get searchStore => _localizedValues[locale.languageCode]!['searchStore']!;
  String get searchUser => _localizedValues[locale.languageCode]!['searchUser']!;
  String get sessionError => _localizedValues[locale.languageCode]!['sessionError']!;
  String get shipped => _localizedValues[locale.languageCode]!['shipped']!;
  String get sizes => _localizedValues[locale.languageCode]!['sizes']!;
  String get soldCount => _localizedValues[locale.languageCode]!['soldCount']!;
  String get status => _localizedValues[locale.languageCode]!['status']!;
  String get stockLabel => _localizedValues[locale.languageCode]!['stockLabel']!;
  String get storeManagement => _localizedValues[locale.languageCode]!['storeManagement']!;
  String get storesCount => _localizedValues[locale.languageCode]!['storesCount']!;
  String get storesTab => _localizedValues[locale.languageCode]!['storesTab']!;
  String get storyDeleted => _localizedValues[locale.languageCode]!['storyDeleted']!;
  String get storyHistory => _localizedValues[locale.languageCode]!['storyHistory']!;
  String get storyReshared => _localizedValues[locale.languageCode]!['storyReshared']!;
  String get summary => _localizedValues[locale.languageCode]!['summary']!;
  String get tags => _localizedValues[locale.languageCode]!['tags']!;
  String get termsAndPrivacy => _localizedValues[locale.languageCode]!['termsAndPrivacy']!;
  String get tokenNotFound => _localizedValues[locale.languageCode]!['tokenNotFound']!;
  String get textDisplay => _localizedValues[locale.languageCode]!['textDisplay']!;
  String get timeoutError => _localizedValues[locale.languageCode]!['timeoutError']!;
  String get totalCodes => _localizedValues[locale.languageCode]!['totalCodes']!;
  String get usedCodes => _localizedValues[locale.languageCode]!['usedCodes']!;
  String get usedLabel => _localizedValues[locale.languageCode]!['usedLabel']!;
  String get usersCount => _localizedValues[locale.languageCode]!['usersCount']!;
  String get usersTab => _localizedValues[locale.languageCode]!['usersTab']!;
  String get validFor => _localizedValues[locale.languageCode]!['validFor']!;
  String get variants => _localizedValues[locale.languageCode]!['variants']!;
  String get verified => _localizedValues[locale.languageCode]!['verified']!;
  String get verifyStore => _localizedValues[locale.languageCode]!['verifyStore']!;
  String get view => _localizedValues[locale.languageCode]!['view']!;
  String get viewsCount => _localizedValues[locale.languageCode]!['viewsCount']!;
  String get weekUnit => _localizedValues[locale.languageCode]!['weekUnit']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'home': 'Accueil',
      'store': 'Boutique',
      'cart': 'Panier',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'search': 'Rechercher',
      'wishlist': 'Favoris',
      'orders': 'Commandes',
      'notifications': 'Notifications',
      'addToCart': 'Ajouter au panier',
      'checkout': 'Passer la commande',
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'editProfile': 'Modifier le profil',
      'createStore': 'Créer une boutique',
      'addProduct': 'Ajouter un produit',
      'darkMode': 'Mode sombre',
      'language': 'Langue',
      'reviews': 'Avis',
      'orderHistory': 'Historique des commandes',
      'emptyCart': 'Votre panier est vide',
      'freeShipping': 'Livraison gratuite',
      'total': 'Total',
      'apply': 'Appliquer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'retry': 'Réessayer',
      'noData': 'Aucune donnée',
      'connectWithGoogle': 'Continuer avec Google',
      'connectYourWorld': 'Connect your world',
      'share': 'Partager',
      'appearance': 'Apparence',
      'account': 'Compte',
      'others': 'Autres',
      'security': 'Sécurité',
      'helpSupport': 'Aide & Support',
      'about': 'À propos',
      'follow': 'Suivre',
      'followers': 'Abonnés',
      'all': 'Tout',
      'promos': 'Promos',
      'bestSellers': 'Best-sellers',
      'deleted': 'Supprimé',
      'following': 'Abonné',
      'noProducts': 'Aucun produit',
      'noPromos': 'Aucune promo en cours',
      'goodQuality': 'Bonne qualité, je recommande !',
      'information': 'Informations',
      'location': 'Localisation',
      'website': 'Site web',
      'email': 'Email',
      'phone': 'Téléphone',
      'languages': 'Langues',
      'shops': 'Boutiques',
      'products': 'Produits',
      // Home Screen
      'suggestedForYou': 'Suggéré pour vous',
      'popularProducts': 'Produits populaires',
      'newArrivals': 'Nouveautés',
      'flashSale': 'Vente flash',
      'seeAll': 'Voir tout',
      'viewMore': 'Voir plus',
      'stories': 'Stories',
      // Store Screen
      'allCategories': 'Toutes les catégories',
      'popularShops': 'Boutiques populaires',
      'todayDeals': 'Offres du jour',
      'searchStores': 'Rechercher des boutiques',
      'searchProducts': 'Rechercher des produits',
      // Product Detail
      'color': 'Couleur',
      'size': 'Taille',
      'description': 'Description',
      'sizeGuide': 'Guide des tailles',
      'buyNow': 'Acheter maintenant',
      'quantity': 'Quantité',
      'inStock': 'En stock',
      'outOfStock': 'Rupture de stock',
      // Cart
      'myCart': 'Mon Panier',
      'freeShippingBanner': 'Félicitations ! Vous avez la livraison gratuite',
      'subtotal': 'Sous-total',
      'shipping': 'Livraison',
      'promoCode': 'Code promo',
      'applyPromo': 'Appliquer',
      'placeOrder': 'Passer la commande',
      'emptyCartMessage': 'Votre panier est vide',
      'continueShopping': 'Continuer les achats',
      // Profile
      'myProfile': 'Mon profil',
      'myStores': 'Mes boutiques',
      'myOrders': 'Mes commandes',
      'myWishlist': 'Mes favoris',
      'noStoresYet': 'Aucune boutique pour le moment',
      'subscriptions': 'Abonnements',
      'receivedReviews': 'Avis reçus',
      'portfolio': 'Portfolio',
      'activity': 'Activité',
      'aboutTab': 'À propos',
      'noProjects': 'Aucun projet',
      'addProject': 'Ajouter un projet',
      'linksAndNetworks': 'Liens & réseaux',
      'recentActivity': 'Activité récente',
      'interactionsHere': 'Vos interactions apparaîtront ici',
      'aboutMe': 'À propos de moi',
      'noBio': 'Aucune biographie pour le moment.',
      'memberSince': 'Membre depuis',
      'country': 'Pays',
      'coordAndNetworks': 'Coordonnées & réseaux',
      'shareMyProfile': 'Partager mon profil',
      'shareProfileDesc': 'Partage ton profil Linky avec tes amis, clients ou partenaires.',
      'shareProfile': 'Partager le profil',
      'myLinkyPage': 'Ma page Linky',
      'previewMyPublicPage': 'Aperçu de ma page publique',
      'noBioYet': 'Aucune biographie pour le moment',
      // Checkout
      'shippingAddress': 'Adresse de livraison',
      'paymentMethod': 'Mode de paiement',
      'orderSummary': 'Récapitulatif',
      'confirmOrder': 'Confirmer la commande',
      'cashOnDelivery': 'Paiement à la livraison',
      // Notifications
      'allNotifications': 'Toutes les notifications',
      'mentions': 'Mentions',
      'promotions': 'Promotions',
      'orderUpdates': 'Mises à jour de commande',
      'markAllRead': 'Tout marquer lu',
      'noNotifications': 'Aucune notification',
      'notificationsEmptySubtitle': 'Vous serez notifié des mises à jour importantes',
      // Reviews
      'writeReview': 'Écrire un avis',
      'rating': 'Note',
      'title': 'Titre',
      'comment': 'Commentaire',
      'submitReview': 'Publier',
      'noReviewsYet': 'Aucun avis pour le moment',
      // Common actions
      'edit': 'Modifier',
      'close': 'Fermer',
      'closeWindow': 'Vous pouvez fermer cette fenêtre.',
      'back': 'Retour',
      'next': 'Suivant',
      'done': 'Terminé',
      'yes': 'Oui',
      'no': 'Non',
      'ok': 'OK',
      'success': 'Succès',
      'filter': 'Filtrer',
      'sort': 'Trier',
      'importAliExpress': 'Importer AliExpress',
      'importFromAliExpress': 'Importer depuis AliExpress',
      'importSubtitle': 'Copiez-collez le lien du produit AliExpress pour l\'importer',
      'importAndPreview': 'Importer & Aperçu',
      'publish': 'Publier',
      'selectCategory': 'Sélectionner la catégorie',
      'selectSubcategory': 'Sélectionner la sous-catégorie',
      'category': 'Catégorie',
      // Admin & Management
      'activeCodes': 'Codes actifs',
      'activeLabel': 'Actif',
      'activateStoreFor': 'Activer la boutique pendant:',
      'addColor': 'Ajouter une couleur',
      'addSize': 'Ajouter une taille',
      'adminPanel': 'Admin Panel',
      'allCodesCopied': 'Tous les codes copiés !',
      'blocked': 'Bloqué',
      'brandColorDesc': 'Elle sera visible sur votre page, vos boutons et vos promotions.',
      'brandColorTitle': 'Couleur principale de la boutique',
      'brandColorUpdated': 'Couleur de boutique mise à jour',
      'bulletList': 'Liste à puces',
      'cancelled': 'Annulée',
      'centerAlign': 'Centre',
      'codeCopied': '{code} copié !',
      'codeDeleted': 'Code supprimé',
      'codeFormat': 'Format: LINKY-XXXXXXXXXX (10 caractères aléatoires)',
      'codesGenerated': '{count} codes générés',
      'codesTab': 'Codes',
      'codesTotal': '{count} codes au total',
      'colors': 'Couleurs',
      'confirmDelete': 'Confirmer la suppression',
      'confirmDeleteStory': 'Voulez-vous vraiment supprimer cette story de l\'historique ?',
      'confirmed': 'Confirmée',
      'copy': 'Copier',
      'copyAll': 'Tout copier',
      'copyCode': 'Copier le code',
      'createProduct': 'Créer le produit',
      'createdBy': 'Créé par',
      'creationError': 'Erreur lors de la création',
      'customizeColor': 'Personnaliser la couleur',
      'dashboard': 'Dashboard',
      'date': 'Date',
      'dateMustBeFuture': 'La date doit être dans le futur',
      'days': 'jours',
      'dayUnit': 'j',
      'deleteCode': 'Supprimer le code',
      'deleteConfirm': 'Supprimer {code} ?',
      'delivered': 'Livrée',
      'descriptionType': 'Type de description',
      'disable': 'Désactiver',
      'durationDays': 'Durée en jours',
      'enable': 'Activer',
      'expiredCodes': 'Codes expirés',
      'expiredBlocksStore': 'Si expire → boutique bloquée',
      'expiredLabel': 'Expiré',
      'expirationDate': "Date d'expiration",
      'expiresAt': 'Expire: {date}',
      'filterActive': 'Actifs',
      'filterAll': 'Tous',
      'filterExpired': 'Expirés',
      'filterUsed': 'Utilisés',
      'expiresOn': 'Expire le {date}',
      'framed': 'Encadré',
      'free': 'Gratuite',
      'generate': 'Générer',
      'generateCodes': 'Générer des codes',
      'generateCombinations': 'Générer les combinaisons',
      'generatedCombinations': 'Combinaisons générées',
      'generating': 'Génération...',
      'hourUnit': 'h',
      'inactive': 'Inactif',
      'items': 'Articles',
      'itemsCount': '{count} articles',
      'justNow': 'à l\'instant',
      'leftAlign': 'Gauche',
      'loadingError': 'Erreur lors du chargement',
      'loginSuccess': 'Connexion réussie !',
      'lowStockWarning': '{count} produit(s) ont un stock faible',
      'manageTeam': 'Gérer l\'équipe',
      'minUnit': 'min',
      'modificationError': 'Modification impossible',
      'nameRequired': 'Nom requis',
      'newStory': 'Nouvelle Story',
      'noCodes': 'Aucun code',
      'noName': 'Sans nom',
      'noStores': 'Aucune boutique',
      'noUsers': 'Aucun utilisateur',
      'notVerified': 'Non vérifié',
      'numberOfCodes': 'Nombre de codes',
      'numberOfDays': 'Nombre de jours',
      'openingCamera': 'Ouverture de la caméra...',
      'orChooseDate': 'Ou choisir la date',
      'orderNumber': 'Commande #{number}',
      'orderNumberLabel': 'Numéro',
      'ordersAppearHere': 'Vos commandes apparaîtront ici',
      'overview': 'Vue d\'ensemble',
      'pending': 'En attente',
      'position': 'Position',
      'preparing': 'Préparation',
      'priceLabel': 'Prix (DA)',
      'priceRequired': 'Prix requis',
      'priceStock': 'Prix & Stock',
      'productCreated': 'Produit créé avec succès !',
      'productName': 'Nom du produit',
      'productPhotos': 'Photos du produit',
      'productsCount': '{count} produits',
      'productsTab': 'Produits',
      'promoPrice': 'Prix promo (DA)',
      'renew': 'Renouveler',
      'renewStore': 'Renouveler {name}',
      'renewedWithCode': 'Renouvelé ! Nouveau code: {code}',
      'removeVerification': 'Retirer vérification',
      'revenue': 'CA',
      'rightAlign': 'Droite',
      'searchStore': 'Rechercher une boutique...',
      'searchUser': 'Rechercher un utilisateur...',
      'sessionError': 'Impossible de vérifier la session',
      'shipped': 'Expédiée',
      'sizes': 'Tailles',
      'soldCount': '{count} vendus',
      'status': 'Statut',
      'stockLabel': 'Stock',
      'storeManagement': 'Gestion du Store',
      'storesCount': '{count} boutiques',
      'storesTab': 'Boutiques',
      'storyDeleted': 'Story supprimée',
      'storyHistory': 'Historique des Stories',
      'storyReshared': 'Story repartagée avec succès !',
      'summary': 'Résumé',
      'tags': 'Tags',
      'termsAndPrivacy': 'En continuant, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité',
      'textDisplay': 'Texte',
      'timeoutError': 'Délai dépassé. Réessayez.',
      'tokenNotFound': 'Firebase token introuvable',
      'totalCodes': 'Total codes',
      'usedCodes': 'Codes utilisés',
      'usedLabel': 'Utilisé',
      'usersCount': '{count} utilisateurs',
      'usersTab': 'Utilisateurs',
      'validFor': 'Valide {duration}',
      'variants': 'Variantes',
      'verified': 'Vérifié',
      'verifyStore': 'Vérifier',
      'view': 'Voir',
      'viewsCount': '{count} vues',
      'weekUnit': 'sem',
    },
    'en': {
      'home': 'Home',
      'store': 'Store',
      'cart': 'Cart',
      'profile': 'Profile',
      'settings': 'Settings',
      'search': 'Search',
      'wishlist': 'Wishlist',
      'orders': 'Orders',
      'notifications': 'Notifications',
      'addToCart': 'Add to cart',
      'checkout': 'Checkout',
      'login': 'Login',
      'logout': 'Logout',
      'editProfile': 'Edit profile',
      'createStore': 'Create store',
      'addProduct': 'Add product',
      'darkMode': 'Dark mode',
      'language': 'Language',
      'reviews': 'Reviews',
      'orderHistory': 'Order history',
      'emptyCart': 'Your cart is empty',
      'freeShipping': 'Free shipping',
      'total': 'Total',
      'apply': 'Apply',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'noData': 'No data',
      'connectWithGoogle': 'Continue with Google',
      'connectYourWorld': 'Connect your world',
      'share': 'Share',
      'appearance': 'Appearance',
      'account': 'Account',
      'others': 'Others',
      'security': 'Security',
      'helpSupport': 'Help & Support',
      'about': 'About',
      'follow': 'Follow',
      'followers': 'Followers',
      'all': 'All',
      'promos': 'Promos',
      'bestSellers': 'Best sellers',
      'deleted': 'Deleted',
      'following': 'Following',
      'noProducts': 'No products',
      'noPromos': 'No promos available',
      'goodQuality': 'Great quality, I recommend!',
      'information': 'Information',
      'location': 'Location',
      'website': 'Website',
      'email': 'Email',
      'phone': 'Phone',
      'languages': 'Languages',
      'shops': 'Shops',
      'products': 'Products',
      // Home Screen
      'suggestedForYou': 'Suggested for you',
      'popularProducts': 'Popular products',
      'newArrivals': 'New arrivals',
      'flashSale': 'Flash sale',
      'seeAll': 'See all',
      'viewMore': 'View more',
      'stories': 'Stories',
      // Store Screen
      'allCategories': 'All categories',
      'popularShops': 'Popular shops',
      'todayDeals': 'Today deals',
      'searchStores': 'Search stores',
      'searchProducts': 'Search products',
      // Product Detail
      'color': 'Color',
      'size': 'Size',
      'description': 'Description',
      'sizeGuide': 'Size guide',
      'buyNow': 'Buy now',
      'quantity': 'Quantity',
      'inStock': 'In stock',
      'outOfStock': 'Out of stock',
      // Cart
      'myCart': 'My Cart',
      'freeShippingBanner': 'Congratulations! You have free shipping',
      'subtotal': 'Subtotal',
      'shipping': 'Shipping',
      'promoCode': 'Promo code',
      'applyPromo': 'Apply',
      'placeOrder': 'Place order',
      'emptyCartMessage': 'Your cart is empty',
      'continueShopping': 'Continue shopping',
      // Profile
      'myProfile': 'My profile',
      'myStores': 'My stores',
      'myOrders': 'My orders',
      'myWishlist': 'My wishlist',
      'noStoresYet': 'No stores yet',
      'subscriptions': 'Subscriptions',
      'receivedReviews': 'Reviews received',
      'portfolio': 'Portfolio',
      'activity': 'Activity',
      'aboutTab': 'About',
      'noProjects': 'No projects',
      'addProject': 'Add a project',
      'linksAndNetworks': 'Links & networks',
      'recentActivity': 'Recent activity',
      'interactionsHere': 'Your interactions will appear here',
      'aboutMe': 'About me',
      'noBio': 'No biography for now.',
      'memberSince': 'Member since',
      'country': 'Country',
      'coordAndNetworks': 'Contact & networks',
      'shareMyProfile': 'Share my profile',
      'shareProfileDesc': 'Share your Linky profile with friends, clients or partners.',
      'shareProfile': 'Share profile',
      'myLinkyPage': 'My Linky page',
      'previewMyPublicPage': 'Preview my public page',
      'noBioYet': 'No biography for now',
      // Checkout
      'shippingAddress': 'Shipping address',
      'paymentMethod': 'Payment method',
      'orderSummary': 'Order summary',
      'confirmOrder': 'Confirm order',
      'cashOnDelivery': 'Cash on delivery',
      // Notifications
      'allNotifications': 'All notifications',
      'mentions': 'Mentions',
      'promotions': 'Promotions',
      'orderUpdates': 'Order updates',
      'markAllRead': 'Mark all read',
      'noNotifications': 'No notifications',
      'notificationsEmptySubtitle': 'You will be notified of important updates',
      // Reviews
      'writeReview': 'Write a review',
      'rating': 'Rating',
      'title': 'Title',
      'comment': 'Comment',
      'submitReview': 'Submit review',
      'noReviewsYet': 'No reviews yet',
      // Common actions
      'edit': 'Edit',
      'close': 'Close',
      'closeWindow': 'You can close this window.',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'success': 'Success',
      'filter': 'Filter',
      'sort': 'Sort',
      'importAliExpress': 'Import AliExpress',
      'importFromAliExpress': 'Import from AliExpress',
      'importSubtitle': 'Paste an AliExpress product link to import it',
      'importAndPreview': 'Import & Preview',
      'publish': 'Publish',
      'selectCategory': 'Select category',
      'selectSubcategory': 'Select subcategory',
      'category': 'Category',
      // Admin & Management
      'activeCodes': 'Active codes',
      'activeLabel': 'Active',
      'activateStoreFor': 'Activate the store for:',
      'addColor': 'Add a color',
      'addSize': 'Add a size',
      'adminPanel': 'Admin Panel',
      'allCodesCopied': 'All codes copied!',
      'blocked': 'Blocked',
      'brandColorDesc': 'It will be visible on your page, buttons and promotions.',
      'brandColorTitle': 'Main brand color',
      'brandColorUpdated': 'Brand color updated',
      'bulletList': 'Bullet list',
      'cancelled': 'Cancelled',
      'centerAlign': 'Center',
      'codeCopied': '{code} copied!',
      'codeDeleted': 'Code deleted',
      'codeFormat': 'Format: LINKY-XXXXXXXXXX (10 random characters)',
      'codesGenerated': '{count} codes generated',
      'codesTab': 'Codes',
      'codesTotal': '{count} codes total',
      'colors': 'Colors',
      'confirmDelete': 'Confirm deletion',
      'confirmDeleteStory': 'Are you sure you want to delete this story?',
      'confirmed': 'Confirmed',
      'copy': 'Copy',
      'copyAll': 'Copy all',
      'copyCode': 'Copy code',
      'createProduct': 'Create product',
      'createdBy': 'Created by',
      'creationError': 'Error during creation',
      'customizeColor': 'Customize color',
      'dashboard': 'Dashboard',
      'date': 'Date',
      'dateMustBeFuture': 'The date must be in the future',
      'days': 'days',
      'dayUnit': 'd',
      'deleteCode': 'Delete code',
      'deleteConfirm': 'Delete {code}?',
      'delivered': 'Delivered',
      'descriptionType': 'Description type',
      'disable': 'Disable',
      'durationDays': 'Duration in days',
      'enable': 'Enable',
      'expiredCodes': 'Expired codes',
      'expiredBlocksStore': 'If expired → store blocked',
      'expiredLabel': 'Expired',
      'expirationDate': 'Expiration date',
      'expiresAt': 'Expires: {date}',
      'filterActive': 'Active',
      'filterAll': 'All',
      'filterExpired': 'Expired',
      'filterUsed': 'Used',
      'expiresOn': 'Expires on {date}',
      'framed': 'Framed',
      'free': 'Free',
      'generate': 'Generate',
      'generateCodes': 'Generate codes',
      'generateCombinations': 'Generate combinations',
      'generatedCombinations': 'Generated combinations',
      'generating': 'Generating...',
      'hourUnit': 'h',
      'inactive': 'Inactive',
      'items': 'Items',
      'itemsCount': '{count} items',
      'justNow': 'Just now',
      'leftAlign': 'Left',
      'loadingError': 'Error loading data',
      'loginSuccess': 'Login successful!',
      'lowStockWarning': '{count} product(s) have low stock',
      'manageTeam': 'Manage team',
      'minUnit': 'min',
      'modificationError': 'Unable to modify',
      'nameRequired': 'Name required',
      'newStory': 'New Story',
      'noCodes': 'No codes',
      'noName': 'No name',
      'noStores': 'No stores',
      'noUsers': 'No users',
      'notVerified': 'Not verified',
      'numberOfCodes': 'Number of codes',
      'numberOfDays': 'Number of days',
      'openingCamera': 'Opening camera...',
      'orChooseDate': 'Or choose date',
      'orderNumber': 'Order #{number}',
      'orderNumberLabel': 'Number',
      'ordersAppearHere': 'Your orders will appear here',
      'overview': 'Overview',
      'pending': 'Pending',
      'position': 'Position',
      'preparing': 'Preparing',
      'priceLabel': 'Price (DZD)',
      'priceRequired': 'Price required',
      'priceStock': 'Price & Stock',
      'productCreated': 'Product created successfully!',
      'productName': 'Product name',
      'productPhotos': 'Product photos',
      'productsCount': '{count} products',
      'productsTab': 'Products',
      'promoPrice': 'Promo price (DZD)',
      'renew': 'Renew',
      'renewStore': 'Renew {name}',
      'renewedWithCode': 'Renewed! New code: {code}',
      'removeVerification': 'Remove verification',
      'revenue': 'Revenue',
      'rightAlign': 'Right',
      'searchStore': 'Search store...',
      'searchUser': 'Search user...',
      'sessionError': 'Unable to verify session',
      'shipped': 'Shipped',
      'sizes': 'Sizes',
      'soldCount': '{count} sold',
      'status': 'Status',
      'stockLabel': 'Stock',
      'storeManagement': 'Store Management',
      'storesCount': '{count} stores',
      'storesTab': 'Stores',
      'storyDeleted': 'Story deleted',
      'storyHistory': 'Story history',
      'storyReshared': 'Story republished successfully!',
      'summary': 'Summary',
      'tags': 'Tags',
      'termsAndPrivacy': 'By continuing, you accept our Terms of Service and Privacy Policy',
      'textDisplay': 'Text',
      'timeoutError': 'Timeout. Please try again.',
      'tokenNotFound': 'Firebase token not found',
      'totalCodes': 'Total codes',
      'usedCodes': 'Used codes',
      'usedLabel': 'Used',
      'usersCount': '{count} users',
      'usersTab': 'Users',
      'validFor': 'Valid {duration}',
      'variants': 'Variants',
      'verified': 'Verified',
      'verifyStore': 'Verify',
      'view': 'View',
      'viewsCount': '{count} views',
      'weekUnit': 'w',
    },
    'ar': {
      'home': 'الرئيسية',
      'store': 'المتجر',
      'cart': 'السلة',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'search': 'بحث',
      'wishlist': 'المفضلة',
      'orders': 'الطلبات',
      'notifications': 'الإشعارات',
      'addToCart': 'أضف إلى السلة',
      'checkout': 'إتمام الشراء',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'editProfile': 'تعديل الملف الشخصي',
      'createStore': 'إنشاء متجر',
      'addProduct': 'إضافة منتج',
      'darkMode': 'الوضع الداكن',
      'language': 'اللغة',
      'reviews': 'التقييمات',
      'orderHistory': 'سجل الطلبات',
      'emptyCart': 'سلتك فارغة',
      'freeShipping': 'شحن مجاني',
      'total': 'المجموع',
      'apply': 'تطبيق',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'save': 'حفظ',
      'delete': 'حذف',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',
      'noData': 'لا توجد بيانات',
      'connectWithGoogle': 'المتابعة مع جوجل',
      'connectYourWorld': 'Connect your world',
      'share': 'مشاركة',
      'appearance': 'المظهر',
      'account': 'الحساب',
      'others': 'أخرى',
      'security': 'الأمان',
      'helpSupport': 'المساعدة والدعم',
      'about': 'حول',
      'follow': 'متابعة',
      'followers': 'المتابعون',
      'all': 'الكل',
      'promos': 'عروض',
      'bestSellers': 'الأكثر مبيعاً',
      'deleted': 'تم الحذف',
      'following': 'متابَع',
      'noProducts': 'لا توجد منتجات',
      'noPromos': 'لا توجد عروض حالياً',
      'goodQuality': 'جودة ممتازة، أنصح بالشراء!',
      'information': 'معلومات',
      'location': 'الموقع',
      'website': 'الموقع الإلكتروني',
      'email': 'البريد الإلكتروني',
      'phone': 'الهاتف',
      'languages': 'اللغات',
      'shops': 'المتاجر',
      'products': 'المنتجات',
      // Home Screen
      'suggestedForYou': 'مقترح لك',
      'popularProducts': 'المنتجات الشائعة',
      'newArrivals': 'وصل حديثاً',
      'flashSale': 'تخفيضات سريعة',
      'seeAll': 'عرض الكل',
      'viewMore': 'عرض المزيد',
      'stories': 'القصص',
      // Store Screen
      'allCategories': 'جميع الفئات',
      'popularShops': 'المتاجر الشائعة',
      'todayDeals': 'عروض اليوم',
      'searchStores': 'البحث عن متاجر',
      'searchProducts': 'البحث عن منتجات',
      // Product Detail
      'color': 'اللون',
      'size': 'المقاس',
      'description': 'الوصف',
      'sizeGuide': 'دليل المقاسات',
      'buyNow': 'اشتر الآن',
      'quantity': 'الكمية',
      'inStock': 'متوفر',
      'outOfStock': 'غير متوفر',
      // Cart
      'myCart': 'سلتي',
      'freeShippingBanner': 'تهانينا! لديك شحن مجاني',
      'subtotal': 'المجموع الفرعي',
      'shipping': 'الشحن',
      'promoCode': 'رمز الترويج',
      'applyPromo': 'تطبيق',
      'placeOrder': 'إتمام الطلب',
      'emptyCartMessage': 'سلتك فارغة',
      'continueShopping': 'متابعة التسوق',
      // Profile
      'myProfile': 'ملفي الشخصي',
      'myStores': 'متاجري',
      'myOrders': 'طلباتي',
      'myWishlist': 'مفضلاتي',
      'noStoresYet': 'لا توجد متاجر بعد',
      'subscriptions': 'المتابعون',
      'receivedReviews': 'التقييمات المستلمة',
      'portfolio': 'الأعمال',
      'activity': 'النشاط',
      'aboutTab': 'حول',
      'noProjects': 'لا توجد مشاريع',
      'addProject': 'إضافة مشروع',
      'linksAndNetworks': 'الروابط والشبكات',
      'recentActivity': 'النشاط الأخير',
      'interactionsHere': 'ستظهر تفاعلاتك هنا',
      'aboutMe': 'نبذة عني',
      'noBio': 'لا توجد سيرة ذاتية حتى الآن.',
      'memberSince': 'عضو منذ',
      'country': 'البلد',
      'coordAndNetworks': 'المعلومات والشبكات',
      'shareMyProfile': 'مشاركة ملفي الشخصي',
      'shareProfileDesc': 'شارك ملفك الشخصي على Linky مع أصدقائك أو عملائك أو شركائك.',
      'shareProfile': 'مشاركة الملف الشخصي',
      'myLinkyPage': 'صفحتي على Linky',
      'previewMyPublicPage': 'معاينة صفحتي العامة',
      'noBioYet': 'لا توجد سيرة ذاتية حتى الآن',
      // Checkout
      'shippingAddress': 'عنوان الشحن',
      'paymentMethod': 'طريقة الدفع',
      'orderSummary': 'ملخص الطلب',
      'confirmOrder': 'تأكيد الطلب',
      'cashOnDelivery': 'الدفع عند الاستلام',
      // Notifications
      'allNotifications': 'جميع الإشعارات',
      'mentions': 'الإشارات',
      'promotions': 'العروض الترويجية',
      'orderUpdates': 'تحديثات الطلب',
      'markAllRead': 'تعليم الكل كمقروء',
      'noNotifications': 'لا توجد إشعارات',
      'notificationsEmptySubtitle': 'سيتم إعلامك بالتحديثات المهمة',
      // Reviews
      'writeReview': 'كتابة تقييم',
      'rating': 'التقييم',
      'title': 'العنوان',
      'comment': 'التعليق',
      'submitReview': 'إرسال التقييم',
      'noReviewsYet': 'لا توجد تقييمات بعد',
      // Common actions
      'edit': 'تعديل',
      'close': 'إغلاق',
      'closeWindow': 'يمكنك إغلاق هذه النافذة.',
      'back': 'رجوع',
      'next': 'التالي',
      'done': 'تم',
      'yes': 'نعم',
      'no': 'لا',
      'ok': 'حسناً',
      'success': 'نجاح',
      'filter': 'تصفية',
      'sort': 'ترتيب',
      'importAliExpress': 'استيراد من AliExpress',
      'importFromAliExpress': 'استيراد من AliExpress',
      'importSubtitle': 'الصق رابط المنتج من AliExpress للاستيراد',
      'importAndPreview': 'استيراد ومعاينة',
      'publish': 'نشر',
      'selectCategory': 'اختر الفئة',
      'selectSubcategory': 'اختر الفئة الفرعية',
      'category': 'الفئة',
      // Admin & Management
      'activeCodes': 'الرموز النشطة',
      'activeLabel': 'نشط',
      'activateStoreFor': 'تفعيل المتجر لمدة:',
      'addColor': 'إضافة لون',
      'addSize': 'إضافة مقاس',
      'adminPanel': 'لوحة الإدارة',
      'allCodesCopied': 'تم نسخ جميع الرموز!',
      'blocked': 'محظور',
      'brandColorDesc': 'سيكون مرئياً على صفحتك وأزرارك وعروضك الترويجية.',
      'brandColorTitle': 'اللون الرئيسي للعلامة التجارية',
      'brandColorUpdated': 'تم تحديث لون العلامة التجارية',
      'bulletList': 'قائمة نقطية',
      'cancelled': 'ملغية',
      'centerAlign': 'وسط',
      'codeCopied': 'تم نسخ {code}!',
      'codeDeleted': 'تم حذف الرمز',
      'codeFormat': 'التنسيق: LINKY-XXXXXXXXXX (10 أحرف عشوائية)',
      'codesGenerated': 'تم توليد {count} رمز',
      'codesTab': 'الرموز',
      'codesTotal': 'إجمالي {count} رمز',
      'colors': 'الألوان',
      'confirmDelete': 'تأكيد الحذف',
      'confirmDeleteStory': 'هل أنت متأكد أنك تريد حذف هذه القصة؟',
      'confirmed': 'مؤكدة',
      'copy': 'نسخ',
      'copyAll': 'نسخ الكل',
      'copyCode': 'نسخ الرمز',
      'createProduct': 'إنشاء المنتج',
      'createdBy': 'تم الإنشاء بواسطة',
      'creationError': 'خطأ أثناء الإنشاء',
      'customizeColor': 'تخصيص اللون',
      'dashboard': 'لوحة المعلومات',
      'date': 'التاريخ',
      'dateMustBeFuture': 'يجب أن يكون التاريخ في المستقبل',
      'days': 'أيام',
      'dayUnit': 'ي',
      'deleteCode': 'حذف الرمز',
      'deleteConfirm': 'حذف {code}؟',
      'delivered': 'تم التوصيل',
      'descriptionType': 'نوع الوصف',
      'disable': 'تعطيل',
      'durationDays': 'المدة بالأيام',
      'enable': 'تفعيل',
      'expiredCodes': 'الرموز منتهية الصلاحية',
      'expiredBlocksStore': 'عند انتهاء الصلاحية → يتم حظر المتجر',
      'expiredLabel': 'منتهي',
      'expirationDate': 'تاريخ الانتهاء',
      'expiresAt': 'ينتهي: {date}',
      'filterActive': 'نشطة',
      'filterAll': 'الكل',
      'filterExpired': 'منتهية',
      'filterUsed': 'مستخدمة',
      'expiresOn': 'ينتهي في {date}',
      'framed': 'مؤطر',
      'free': 'مجاني',
      'generate': 'توليد',
      'generateCodes': 'توليد الرموز',
      'generateCombinations': 'توليد التوليفات',
      'generatedCombinations': 'التوليفات المولدة',
      'generating': 'جاري التوليد...',
      'hourUnit': 'س',
      'inactive': 'غير نشط',
      'items': 'المواد',
      'itemsCount': '{count} مادة',
      'justNow': 'الآن',
      'leftAlign': 'يسار',
      'loadingError': 'خطأ أثناء التحميل',
      'loginSuccess': 'تم تسجيل الدخول بنجاح!',
      'lowStockWarning': '{count} منتج لديه مخزون منخفض',
      'manageTeam': 'إدارة الفريق',
      'minUnit': 'د',
      'modificationError': 'تعذر التعديل',
      'nameRequired': 'الاسم مطلوب',
      'newStory': 'قصة جديدة',
      'noCodes': 'لا توجد رموز',
      'noName': 'بدون اسم',
      'noStores': 'لا توجد متاجر',
      'noUsers': 'لا يوجد مستخدمون',
      'notVerified': 'غير موثق',
      'numberOfCodes': 'عدد الرموز',
      'numberOfDays': 'عدد الأيام',
      'openingCamera': 'جاري فتح الكاميرا...',
      'orChooseDate': 'أو اختر التاريخ',
      'orderNumber': 'طلب #{number}',
      'orderNumberLabel': 'الرقم',
      'ordersAppearHere': 'ستظهر طلباتك هنا',
      'overview': 'نظرة عامة',
      'pending': 'قيد الانتظار',
      'position': 'الموضع',
      'preparing': 'قيد التحضير',
      'priceLabel': 'السعر (د.ج)',
      'priceRequired': 'السعر مطلوب',
      'priceStock': 'السعر والمخزون',
      'productCreated': 'تم إنشاء المنتج بنجاح!',
      'productName': 'اسم المنتج',
      'productPhotos': 'صور المنتج',
      'productsCount': '{count} منتج',
      'productsTab': 'المنتجات',
      'promoPrice': 'سعر التخفيض (د.ج)',
      'renew': 'تجديد',
      'renewStore': 'تجديد {name}',
      'renewedWithCode': 'تم التجديد! الرمز الجديد: {code}',
      'removeVerification': 'إزالة التوثيق',
      'revenue': 'الإيرادات',
      'rightAlign': 'يمين',
      'searchStore': 'البحث عن متجر...',
      'searchUser': 'البحث عن مستخدم...',
      'sessionError': 'تعذر التحقق من الجلسة',
      'shipped': 'تم الشحن',
      'sizes': 'المقاسات',
      'soldCount': 'تم بيع {count}',
      'status': 'الحالة',
      'stockLabel': 'المخزون',
      'storeManagement': 'إدارة المتجر',
      'storesCount': '{count} متجر',
      'storesTab': 'المتاجر',
      'storyDeleted': 'تم حذف القصة',
      'storyHistory': 'تاريخ القصص',
      'storyReshared': 'تم إعادة نشر القصة بنجاح!',
      'summary': 'الملخص',
      'tags': 'العلامات',
      'termsAndPrivacy': 'بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بنا',
      'textDisplay': 'نص',
      'timeoutError': 'انتهت المهلة. حاول مرة أخرى.',
      'tokenNotFound': 'رمز Firebase غير موجود',
      'totalCodes': 'إجمالي الرموز',
      'usedCodes': 'الرموز المستخدمة',
      'usedLabel': 'مستخدم',
      'usersCount': '{count} مستخدم',
      'usersTab': 'المستخدمون',
      'validFor': 'صالح لمدة {duration}',
      'variants': 'المتغيرات',
      'verified': 'موثق',
      'verifyStore': 'توثيق',
      'view': 'عرض',
      'viewsCount': '{count} مشاهدة',
      'weekUnit': 'أ',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
