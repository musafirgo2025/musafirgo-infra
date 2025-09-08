-- Optimized test data for MusafirGO Itinerary Service
-- This file is executed after the application creates tables via Flyway
-- Optimized for performance with proper indexing and data structure

-- Vérifier si toutes les tables existent avant de procéder et insérer les données
DO $$
BEGIN
    -- Vérifier si toutes les tables nécessaires existent
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'itinerary') THEN
        RAISE NOTICE 'Table itinerary does not exist yet. Skipping data insertion.';
        RETURN;
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'day_plan') THEN
        RAISE NOTICE 'Table day_plan does not exist yet. Skipping data insertion.';
        RETURN;
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'day_plan_item') THEN
        RAISE NOTICE 'Table day_plan_item does not exist yet. Skipping data insertion.';
        RETURN;
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'media') THEN
        RAISE NOTICE 'Table media does not exist yet. Skipping data insertion.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'All tables exist. Proceeding with data insertion.';
    
    -- Nettoyer les données existantes
    TRUNCATE TABLE day_plan_item CASCADE;
    TRUNCATE TABLE day_plan CASCADE;
    TRUNCATE TABLE media CASCADE;
    TRUNCATE TABLE itinerary CASCADE;
    
    -- Réinitialiser les séquences
    ALTER SEQUENCE IF EXISTS itinerary_id_seq RESTART WITH 1;
    
    -- ========================================
    -- DONNÉES DE TEST - ITINÉRAIRES
    -- ========================================
    
    -- Itinéraire 1: Casablanca - 3 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', 'Casablanca')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Casablanca
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440001', 1),
    ('550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440001', 2),
    ('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440001', 3)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Casablanca
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440011', 'Visite de la Mosquée Hassan II'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Promenade dans la Corniche'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Déjeuner au restaurant Rick''s Café'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Shopping au Morocco Mall');
    
    -- Items pour le jour 2 - Casablanca
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440012', 'Visite du quartier Habous'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Marché central de Casablanca'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Découverte de l''architecture Art Déco'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Dîner dans un restaurant traditionnel');
    
    -- Items pour le jour 3 - Casablanca
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440013', 'Excursion à Rabat (capitale)'),
    ('550e8400-e29b-41d4-a716-446655440013', 'Visite de la Tour Hassan'),
    ('550e8400-e29b-41d4-a716-446655440013', 'Retour à Casablanca'),
    ('550e8400-e29b-41d4-a716-446655440013', 'Préparation du départ');
    
    -- Itinéraire 2: Marrakech - 4 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('550e8400-e29b-41d4-a716-446655440002', 'Marrakech')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Marrakech
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440002', 1),
    ('550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440002', 2),
    ('550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440002', 3),
    ('550e8400-e29b-41d4-a716-446655440024', '550e8400-e29b-41d4-a716-446655440002', 4)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440021', 'Arrivée à Marrakech'),
    ('550e8400-e29b-41d4-a716-446655440021', 'Installation à l''hôtel/Riad'),
    ('550e8400-e29b-41d4-a716-446655440021', 'Première découverte de la Médina'),
    ('550e8400-e29b-41d4-a716-446655440021', 'Dîner sur la place Jemaa el-Fnaa');
    
    -- Items pour le jour 2 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440022', 'Visite du Palais Bahia'),
    ('550e8400-e29b-41d4-a716-446655440022', 'Exploration des souks'),
    ('550e8400-e29b-41d4-a716-446655440022', 'Déjeuner dans un restaurant de la Médina'),
    ('550e8400-e29b-41d4-a716-446655440022', 'Visite des Tombeaux Saadiens');
    
    -- Items pour le jour 3 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440023', 'Excursion dans l''Atlas'),
    ('550e8400-e29b-41d4-a716-446655440023', 'Visite d''un village berbère'),
    ('550e8400-e29b-41d4-a716-446655440023', 'Randonnée dans les montagnes'),
    ('550e8400-e29b-41d4-a716-446655440023', 'Retour à Marrakech en fin de journée');
    
    -- Items pour le jour 4 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440024', 'Visite du Jardin Majorelle'),
    ('550e8400-e29b-41d4-a716-446655440024', 'Musée Yves Saint Laurent'),
    ('550e8400-e29b-41d4-a716-446655440024', 'Derniers achats dans les souks'),
    ('550e8400-e29b-41d4-a716-446655440024', 'Départ de Marrakech');
    
    -- Itinéraire 3: Fès - 2 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('550e8400-e29b-41d4-a716-446655440003', 'Fès')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Fès
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440003', 1),
    ('550e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440003', 2)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Fès
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440031', 'Arrivée à Fès'),
    ('550e8400-e29b-41d4-a716-446655440031', 'Visite de la Médina de Fès'),
    ('550e8400-e29b-41d4-a716-446655440031', 'Découverte des tanneries traditionnelles'),
    ('550e8400-e29b-41d4-a716-446655440031', 'Visite de l''Université Al Quaraouiyine');
    
    -- Items pour le jour 2 - Fès
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440032', 'Visite du Palais Royal'),
    ('550e8400-e29b-41d4-a716-446655440032', 'Exploration des souks spécialisés'),
    ('550e8400-e29b-41d4-a716-446655440032', 'Déjeuner dans un restaurant traditionnel'),
    ('550e8400-e29b-41d4-a716-446655440032', 'Départ de Fès');
    
    -- Itinéraire 4: Chefchaouen - 2 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('550e8400-e29b-41d4-a716-446655440004', 'Chefchaouen')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Chefchaouen
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('550e8400-e29b-41d4-a716-446655440041', '550e8400-e29b-41d4-a716-446655440004', 1),
    ('550e8400-e29b-41d4-a716-446655440042', '550e8400-e29b-41d4-a716-446655440004', 2)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Chefchaouen
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440041', 'Arrivée à Chefchaouen'),
    ('550e8400-e29b-41d4-a716-446655440041', 'Promenade dans la ville bleue'),
    ('550e8400-e29b-41d4-a716-446655440041', 'Visite de la Kasbah'),
    ('550e8400-e29b-41d4-a716-446655440041', 'Dîner avec vue sur les montagnes');
    
    -- Items pour le jour 2 - Chefchaouen
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440042', 'Randonnée dans les montagnes du Rif'),
    ('550e8400-e29b-41d4-a716-446655440042', 'Visite des cascades d''Akchour'),
    ('550e8400-e29b-41d4-a716-446655440042', 'Retour à Chefchaouen'),
    ('550e8400-e29b-41d4-a716-446655440042', 'Départ vers la prochaine destination');
    
    -- Itinéraire 5: Essaouira - 3 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('550e8400-e29b-41d4-a716-446655440005', 'Essaouira')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Essaouira
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('550e8400-e29b-41d4-a716-446655440051', '550e8400-e29b-41d4-a716-446655440005', 1),
    ('550e8400-e29b-41d4-a716-446655440052', '550e8400-e29b-41d4-a716-446655440005', 2),
    ('550e8400-e29b-41d4-a716-446655440053', '550e8400-e29b-41d4-a716-446655440005', 3)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Essaouira
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440051', 'Arrivée à Essaouira'),
    ('550e8400-e29b-41d4-a716-446655440051', 'Visite de la Médina fortifiée'),
    ('550e8400-e29b-41d4-a716-446655440051', 'Promenade sur les remparts'),
    ('550e8400-e29b-41d4-a716-446655440051', 'Découverte du port de pêche');
    
    -- Items pour le jour 2 - Essaouira
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440052', 'Séance de surf ou kitesurf'),
    ('550e8400-e29b-41d4-a716-446655440052', 'Déjeuner de poisson frais au port'),
    ('550e8400-e29b-41d4-a716-446655440052', 'Visite des ateliers d''artisans'),
    ('550e8400-e29b-41d4-a716-446655440052', 'Coucher de soleil sur la plage');
    
    -- Items pour le jour 3 - Essaouira
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('550e8400-e29b-41d4-a716-446655440053', 'Excursion à l''île de Mogador'),
    ('550e8400-e29b-41d4-a716-446655440053', 'Observation des oiseaux'),
    ('550e8400-e29b-41d4-a716-446655440053', 'Derniers achats d''artisanat'),
    ('550e8400-e29b-41d4-a716-446655440053', 'Départ d''Essaouira');
    
    -- ========================================
    -- DONNÉES DE TEST - MÉDIAS (exemples)
    -- ========================================
    
    -- Médias pour l'itinéraire Casablanca
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('550e8400-e29b-41d4-a716-446655440101', '550e8400-e29b-41d4-a716-446655440001', 'casablanca-mosquee-hassan-ii.jpg', 'image/jpeg', 2048576, 'https://musafirgo.blob.core.windows.net/media/casablanca-mosquee-hassan-ii.jpg', NOW(), true),
    ('550e8400-e29b-41d4-a716-446655440102', '550e8400-e29b-41d4-a716-446655440001', 'casablanca-corniche.mp4', 'video/mp4', 15728640, 'https://musafirgo.blob.core.windows.net/media/casablanca-corniche.mp4', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- Médias pour l'itinéraire Marrakech
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('550e8400-e29b-41d4-a716-446655440201', '550e8400-e29b-41d4-a716-446655440002', 'marrakech-jemaa-el-fnaa.jpg', 'image/jpeg', 1536000, 'https://musafirgo.blob.core.windows.net/media/marrakech-jemaa-el-fnaa.jpg', NOW(), true),
    ('550e8400-e29b-41d4-a716-446655440202', '550e8400-e29b-41d4-a716-446655440002', 'marrakech-souks.jpg', 'image/jpeg', 1873920, 'https://musafirgo.blob.core.windows.net/media/marrakech-souks.jpg', NOW(), true),
    ('550e8400-e29b-41d4-a716-446655440203', '550e8400-e29b-41d4-a716-446655440002', 'marrakech-atlas-trekking.mp4', 'video/mp4', 25165824, 'https://musafirgo.blob.core.windows.net/media/marrakech-atlas-trekking.mp4', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- Médias pour l'itinéraire Fès
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('550e8400-e29b-41d4-a716-446655440301', '550e8400-e29b-41d4-a716-446655440003', 'fes-tanneries.jpg', 'image/jpeg', 1761280, 'https://musafirgo.blob.core.windows.net/media/fes-tanneries.jpg', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- Médias pour l'itinéraire Chefchaouen
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('550e8400-e29b-41d4-a716-446655440401', '550e8400-e29b-41d4-a716-446655440004', 'chefchaouen-blue-streets.jpg', 'image/jpeg', 1925120, 'https://musafirgo.blob.core.windows.net/media/chefchaouen-blue-streets.jpg', NOW(), true),
    ('550e8400-e29b-41d4-a716-446655440402', '550e8400-e29b-41d4-a716-446655440004', 'chefchaouen-cascades-akchour.jpg', 'image/jpeg', 1638400, 'https://musafirgo.blob.core.windows.net/media/chefchaouen-cascades-akchour.jpg', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- Médias pour l'itinéraire Essaouira
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('550e8400-e29b-41d4-a716-446655440501', '550e8400-e29b-41d4-a716-446655440005', 'essaouira-ramparts.jpg', 'image/jpeg', 1441792, 'https://musafirgo.blob.core.windows.net/media/essaouira-ramparts.jpg', NOW(), true),
    ('550e8400-e29b-41d4-a716-446655440502', '550e8400-e29b-41d4-a716-446655440005', 'essaouira-surf-session.mp4', 'video/mp4', 33554432, 'https://musafirgo.blob.core.windows.net/media/essaouira-surf-session.mp4', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- Create optimized indexes for better performance
    CREATE INDEX IF NOT EXISTS idx_itinerary_city ON itinerary(city);
    CREATE INDEX IF NOT EXISTS idx_day_plan_itinerary_id ON day_plan(itinerary_id);
    CREATE INDEX IF NOT EXISTS idx_day_plan_day_number ON day_plan(day_number);
    CREATE INDEX IF NOT EXISTS idx_media_itinerary_id ON media(itinerary_id);
    CREATE INDEX IF NOT EXISTS idx_media_active ON media(is_active);
    CREATE INDEX IF NOT EXISTS idx_media_uploaded_at ON media(uploaded_at);
    
    -- Update table statistics for query optimizer
    ANALYZE itinerary;
    ANALYZE day_plan;
    ANALYZE day_plan_item;
    ANALYZE media;
    
    RAISE NOTICE 'Optimized test data loaded successfully with indexes!';
    
END $$;
