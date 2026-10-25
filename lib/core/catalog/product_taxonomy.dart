class ProductCategory {
  const ProductCategory(this.id, this.name, this.subcategories);
  final String id;
  final String name;
  final List<ProductSubcategory> subcategories;
}

class ProductSubcategory {
  const ProductSubcategory(this.id, this.name);
  final String id;
  final String name;
}

/// The storefront and the seller form use the exact same fixed taxonomy.
/// Sellers select it; they never type arbitrary categories.
const productTaxonomy = <ProductCategory>[
  ProductCategory('cat_electronics', 'Électronique', [
    ProductSubcategory('sub_phones', 'Téléphones & accessoires'),
    ProductSubcategory('sub_computers', 'Informatique'),
    ProductSubcategory('sub_tv_audio', 'TV, audio & vidéo'),
    ProductSubcategory('sub_gaming', 'Gaming'),
    ProductSubcategory('sub_cameras', 'Photo & caméras'),
    ProductSubcategory('sub_appliances', 'Électroménager'),
  ]),
  ProductCategory('cat_fashion', 'Mode', [
    ProductSubcategory('sub_women', 'Femme'),
    ProductSubcategory('sub_men', 'Homme'),
    ProductSubcategory('sub_kids_fashion', 'Enfant'),
    ProductSubcategory('sub_shoes', 'Chaussures'),
    ProductSubcategory('sub_bags', 'Sacs & maroquinerie'),
    ProductSubcategory('sub_jewelry', 'Bijoux & montres'),
  ]),
  ProductCategory('cat_beauty', 'Beauté & santé', [
    ProductSubcategory('sub_skincare', 'Soin de la peau'),
    ProductSubcategory('sub_makeup', 'Maquillage'),
    ProductSubcategory('sub_fragrance', 'Parfums'),
    ProductSubcategory('sub_hair', 'Cheveux'),
    ProductSubcategory('sub_wellness', 'Bien-être'),
    ProductSubcategory('sub_personal_care', 'Hygiène'),
  ]),
  ProductCategory('cat_home', 'Maison & jardin', [
    ProductSubcategory('sub_furniture', 'Meubles'),
    ProductSubcategory('sub_decor', 'Décoration'),
    ProductSubcategory('sub_kitchen', 'Cuisine'),
    ProductSubcategory('sub_bedding', 'Linge de maison'),
    ProductSubcategory('sub_garden', 'Jardin'),
    ProductSubcategory('sub_tools', 'Bricolage & outils'),
  ]),
  ProductCategory('cat_sports', 'Sport & loisirs', [
    ProductSubcategory('sub_fitness', 'Fitness'),
    ProductSubcategory('sub_outdoor', 'Plein air'),
    ProductSubcategory('sub_team_sports', 'Sports collectifs'),
    ProductSubcategory('sub_cycling', 'Vélo'),
    ProductSubcategory('sub_swim', 'Natation'),
    ProductSubcategory('sub_hobbies', 'Loisirs créatifs'),
  ]),
  ProductCategory('cat_grocery', 'Alimentation', [
    ProductSubcategory('sub_food', 'Épicerie'),
    ProductSubcategory('sub_drinks', 'Boissons'),
    ProductSubcategory('sub_fresh', 'Frais'),
    ProductSubcategory('sub_baby_food', 'Bébé'),
    ProductSubcategory('sub_pet_food', 'Animaux'),
    ProductSubcategory('sub_local', 'Produits locaux'),
  ]),
  ProductCategory('cat_auto', 'Auto & moto', [
    ProductSubcategory('sub_auto_parts', 'Pièces auto'),
    ProductSubcategory('sub_moto_parts', 'Pièces moto'),
    ProductSubcategory('sub_tires', 'Pneus'),
    ProductSubcategory('sub_car_care', 'Entretien'),
    ProductSubcategory('sub_accessories', 'Accessoires'),
    ProductSubcategory('sub_navigation', 'Navigation'),
  ]),
  ProductCategory('cat_baby', 'Bébé & enfant', [
    ProductSubcategory('sub_toys', 'Jouets'),
    ProductSubcategory('sub_baby_gear', 'Puériculture'),
    ProductSubcategory('sub_school', 'Fournitures scolaires'),
    ProductSubcategory('sub_kids_room', 'Chambre enfant'),
    ProductSubcategory('sub_games', 'Jeux & puzzles'),
  ]),
  ProductCategory('cat_pets', 'Animaux', [
    ProductSubcategory('sub_dogs', 'Chiens'),
    ProductSubcategory('sub_cats', 'Chats'),
    ProductSubcategory('sub_birds', 'Oiseaux'),
    ProductSubcategory('sub_aquarium', 'Aquarium'),
    ProductSubcategory('sub_pet_accessories', 'Accessoires'),
  ]),
  ProductCategory('cat_books', 'Livres & médias', [
    ProductSubcategory('sub_books', 'Livres'),
    ProductSubcategory('sub_stationery', 'Papeterie'),
    ProductSubcategory('sub_music', 'Musique'),
    ProductSubcategory('sub_movies', 'Films & séries'),
    ProductSubcategory('sub_collectibles', 'Collections'),
  ]),
  ProductCategory('cat_office', 'Bureau & professionnel', [
    ProductSubcategory('sub_office', 'Fournitures bureau'),
    ProductSubcategory('sub_printing', 'Impression'),
    ProductSubcategory('sub_business_tech', 'Tech professionnelle'),
    ProductSubcategory('sub_security', 'Sécurité'),
    ProductSubcategory('sub_packaging', 'Emballage'),
  ]),
  ProductCategory('cat_digital', 'Produits numériques', [
    ProductSubcategory('sub_software', 'Logiciels'),
    ProductSubcategory('sub_courses', 'Formations'),
    ProductSubcategory('sub_templates', 'Templates'),
    ProductSubcategory('sub_design_assets', 'Assets créatifs'),
    ProductSubcategory('sub_gift_cards', 'Cartes cadeaux'),
  ]),
];
