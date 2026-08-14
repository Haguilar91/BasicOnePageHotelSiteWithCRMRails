# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Sample PageContent for the home page
PageContent.create(
  key: 'home_hero_title',
  title: 'Hotel Mesón Hero Title',
  content: 'Hotel Mesón <span class="gradient-text">del Bosque</span>'
)

PageContent.create(
  key: 'home_hero_subtitle',
  title: 'Hotel Mesón Hero Subtitle',
  content: 'Una experiencia de lujo en el corazón histórico de Querétaro, donde la elegancia colonial se encuentra con el confort moderno'
)

PageContent.create(
  key: 'home_features_title',
  title: 'Home Features Title',
  content: 'Nuestras Habitaciones'
)

PageContent.create(
  key: 'home_features_subtitle',
  title: 'Home Features Subtitle',
  content: 'Habitaciones Premium - Diseñadas para brindarte la máxima comodidad y tranquilidad'
)

PageContent.create(
  key: 'home_activities_title',
  title: 'Home Activities Title',
  content: 'Qué hacer en Querétaro'
)

PageContent.create(
  key: 'home_activities_subtitle',
  title: 'Home Activities Subtitle',
  content: 'Restaurantes, puntos de interés y tours que hacen único tu viaje a Querétaro.'
)

PageContent.create(
  key: 'home_location_title',
  title: 'Home Location Title',
  content: 'En el Corazón de Querétaro'
)

PageContent.create(
  key: 'home_location_desc',
  title: 'Home Location Description',
  content: 'Nuestra ubicación privilegiada en el centro histórico de Querétaro te permite disfrutar de la historia, la cultura y el colonialismo en un solo lugar.'
)

PageContent.create(
  key: 'contact_email',
  title: 'Contact Email',
  content: 'info@hotelmeson.com'
)

PageContent.create(
  key: 'contact_phone',
  title: 'Contact Phone',
  content: '+52 442 212 3456'
)

PageContent.create(
  key: 'address_line',
  title: 'Address Line',
  content: 'Calle Ignacio Allende Norte 82, Centro Histórico, Querétaro, México'
)

PageContent.create(
  key: 'cta_title',
  title: 'CTA Title',
  content: '¡Listo para una experiencia inolvidable?'
)

  PageContent.create(
    key: 'cta_subtitle',
    title: 'CTA Subtitle',
    content: 'Reserva ahora y disfruta de las mejores tarifas de temporada'
  )

  # Global brand settings
  global_page_content = PageContent.create!(
    key: 'global',
    title: 'Global Brand Settings',
    content: 'Configure your website branding'
  )

  # Attach images to global page content
  # Logo: icon.png (256x256)
  if File.exist?(Rails.public_path.join('icon.png'))
    global_page_content.logo.attach(
      io: File.open(Rails.public_path.join('icon.png')),
      filename: 'logo.png',
      content_type: 'image/png'
    )
  end

  # Favicon: favicon.ico (16x16)
  if File.exist?(Rails.public_path.join('favicon.ico'))
    global_page_content.favicon.attach(
      io: File.open(Rails.public_path.join('favicon.ico')),
      filename: 'favicon.ico',
      content_type: 'image/x-icon'
    )
  end

  # App icon: apple-touch-icon.png (180x180)
  # Map Iframe URL
  PageContent.find_or_create_by!(key: 'map_iframe_url') do |pc|
    pc.title = 'Google Maps Iframe URL'
    pc.content = 'https://maps.google.com/maps?q=Calle+Ignacio+Allende+Norte+82,+Centro+Historico,+Queretaro,+Mexico&t=&z=16&ie=UTF8&iwloc=&output=embed'
  end

  # Default Rooms
  Room.find_or_create_by!(name: 'Habitación Standard') do |r|
    r.price = 'Desde $150'
    r.description = 'Perfecta para viajeros que buscan comodidad y tranquilidad en el corazón histórico.'
    r.features = "Cama King Size\nBalcón con vista al centro\nConexión histórica incluida\nSpa incluido"
    r.booking_url = 'https://www.booking.com'
    r.position = 1
  end

  Room.find_or_create_by!(name: 'Habitación Deluxe') do |r|
    r.price = 'Desde $250'
    r.badge = 'POPULAR'
    r.description = 'Amplia y lujosa con todos los servicios exclusivos.'
    r.features = "Cama King Size\nBañera de hidromasaje\nTerraza privada\nServicio de room service 24h\nWi-Fi de alta velocidad"
    r.booking_url = 'https://www.airbnb.com'
    r.position = 2
  end

  Room.find_or_create_by!(name: 'Suite Presidencial') do |r|
    r.price = 'Desde $400'
    r.description = 'El lujo absoluto para experiencias inolvidables.'
    r.features = "Cama King Size\nSala de estar independiente\nJacuzzi privado\nButler personal\nAcceso VIP al spa"
    r.booking_url = 'https://www.booking.com'
    r.position = 3
  end

  # Default Experiences
  Experience.find_or_create_by!(title: 'Restaurante') do |e|
    e.description = 'Gastronomía local e internacional con ingredientes frescos'
    e.icon = 'utensils'
    e.position = 1
  end

  Experience.find_or_create_by!(title: 'Piscina') do |e|
    e.description = 'Piscina al aire libre con vistas panorámicas'
    e.icon = 'swimmer'
    e.position = 2
  end

  Experience.find_or_create_by!(title: 'Gimnasio') do |e|
    e.description = 'Equipo moderno para mantener tu rutina'
    e.icon = 'dumbbell'
    e.position = 3
  end

  Experience.find_or_create_by!(title: 'Transporte') do |e|
    e.description = 'Servicio de transporte privado disponible 24/7'
    e.icon = 'car'
    e.position = 4
  end

  # Default Local Activities
  LocalActivity.find_or_create_by!(title: 'Restaurante 1810') do |activity|
    activity.category = 'Restaurantes'
    activity.description = 'Alta cocina mexicana con inspiración de recetas queretanas, ubicado junto a la Plaza de Armas.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Restaurante+1810+Quer%C3%A9taro'
    activity.position = 1
  end

  LocalActivity.find_or_create_by!(title: 'Cocina de Doña Esthela') do |activity|
    activity.category = 'Restaurantes'
    activity.description = 'Famosa por su cocina tradicional, chiles en nogada y platillos caseros.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Cocina+de+Do%C3%B1a+Esthela+Quer%C3%A9taro'
    activity.position = 2
  end

  LocalActivity.find_or_create_by!(title: 'Hacienda La Laborcilla') do |activity|
    activity.category = 'Restaurantes'
    activity.description = 'Cena elegante en una antigua hacienda con jardines y cocina de autor.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Hacienda+La+Laborcilla+Quer%C3%A9taro'
    activity.position = 3
  end

  LocalActivity.find_or_create_by!(title: 'Plaza de Armas') do |activity|
    activity.category = 'Puntos de Interés'
    activity.description = 'Ep icentro del centro histórico con su catedral, cafés y arquitectura colonial.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Plaza+de+Armas+Quer%C3%A9taro'
    activity.position = 1
  end

  LocalActivity.find_or_create_by!(title: 'Acueducto de Querétaro') do |activity|
    activity.category = 'Puntos de Interés'
    activity.description = 'Imponente acueducto de 74 arcos y símbolo de la ciudad.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Acueducto+de+Quer%C3%A9taro'
    activity.position = 2
  end

  LocalActivity.find_or_create_by!(title: 'Teatro de la República') do |activity|
    activity.category = 'Puntos de Interés'
    activity.description = 'Teatro histórico donde se firmó la Constitución de 1917.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Teatro+de+la+Rep%C3%BAblica+Quer%C3%A9taro'
    activity.position = 3
  end

  LocalActivity.find_or_create_by!(title: 'Tour Peatonal Centro Histórico') do |activity|
    activity.category = 'Tours'
    activity.description = 'Recorrido guiado por plazas, iglesias y calles coloniales del centro.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Centro+Hist%C3%B3rico+de+Quer%C3%A9taro'
    activity.position = 1
  end

  LocalActivity.find_or_create_by!(title: 'Ruta del Queso y Vino') do |activity|
    activity.category = 'Tours'
    activity.description = 'Degustación de quesos artesanales y vinos regionales en Querétaro.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Ruta+del+Queso+y+Vino+Quer%C3%A9taro'
    activity.position = 2
  end

  LocalActivity.find_or_create_by!(title: 'Viñedos La Redonda') do |activity|
    activity.category = 'Tours'
    activity.description = 'Cata de vinos y visita a una de las bodegas más reconocidas de la región.'
    activity.google_maps_url = 'https://www.google.com/maps/search/?api=1&query=Vi%C3%B1edos+La+Redonda+Quer%C3%A9taro'
    activity.position = 3
  end

  # Sample Announcements
  Announcement.create!(
    title: '🎉 ¡Temporada de Verano!',
    description: '¡20% de descuento en todas las habitaciones durante el mes de Julio!',
    start_date: Date.today,
    end_date: Date.today + 30,
    active: true
  )

  Announcement.create!(
    title: '🍷 Cena Incluida',
    description: 'Reserva para fin de semana y disfruta de una cena gourmet incluida en tu estadía.',
    start_date: Date.today - 5,
    end_date: Date.today + 14,
    active: true
  )

# db/seeds.rb

# Create a default user for Devise authentication
User.find_or_create_by!(email: "admin@hotel.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  puts "Created default user: admin@hotel.com / password123"
end

# Ensure global brand settings / page contents exist
PageContent.find_or_create_by!(key: 'global')
PageContent.find_or_create_by!(key: 'site_title') do |p|
  p.content = "Hotel Boutique"
end
PageContent.find_or_create_by!(key: 'home_welcome_title') do |p|
  p.content = "Bienvenido a su refugio de lujo"
end

# Theme presets — manageable from Avo under "Themes". Only one is ever active;
# the site reads the active one and falls back to "Dorado Colonial" if none is.
[
  {
    name: "Dorado Colonial", position: 1, active: true,
    bg_primary: "#0f172a", bg_secondary: "#1e293b", bg_tertiary: "#334155",
    accent: "#d4af37", accent_soft: "#f4e4bc", text_muted: "#9ca3af"
  },
  {
    name: "Cantera Rosa", position: 2, active: false,
    bg_primary: "#221420", bg_secondary: "#34202f", bg_tertiary: "#4a2c42",
    accent: "#dc93ac", accent_soft: "#f3d3de", text_muted: "#c3aebe"
  },
  {
    name: "Talavera Azul", position: 3, active: false,
    bg_primary: "#0c1f33", bg_secondary: "#15304c", bg_tertiary: "#1f4468",
    accent: "#5b9bd5", accent_soft: "#bfe0f5", text_muted: "#9fb8cc"
  },
  {
    name: "Cantera Terracota", position: 4, active: false,
    bg_primary: "#231810", bg_secondary: "#33231a", bg_tertiary: "#4a3324",
    accent: "#c9834f", accent_soft: "#f0cfa8", text_muted: "#c7b29e"
  }
].each do |attrs|
  Theme.find_or_create_by!(name: attrs[:name]) do |theme|
    theme.assign_attributes(attrs)
  end
end

puts "Database seeded successfully!"