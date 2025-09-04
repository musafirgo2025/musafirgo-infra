-- Optimized test data for MusafirGO Itinerary Service
-- This file is executed after the application creates tables via Flyway
-- Optimized for performance with proper indexing and data structure

-- VÃ©rifier si toutes les tables existent avant de procÃ©der et insÃ©rer les donnÃ©es
DO $$
BEGIN
    -- VÃ©rifier si toutes les tables nÃ©cessaires existent
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
    
    -- Nettoyer les donnÃ©es existantes
    TRUNCATE TABLE day_plan_item CASCADE;
    TRUNCATE TABLE day_plan CASCADE;
    TRUNCATE TABLE media CASCADE;
    TRUNCATE TABLE itinerary CASCADE;
    
    -- RÃ©initialiser les sÃ©quences
    ALTER SEQUENCE IF EXISTS itinerary_id_seq RESTART WITH 1;
    
    -- ========================================
    -- DONNÃ‰ES DE TEST - ITINÃ‰RAIRES
    -- UUIDs prÃ©dÃ©finis pour la pipeline de tests
    -- ========================================
    
    -- ItinÃ©raire 1: Casablanca - 3 jours
    -- UUID: 11111111-1111-1111-1111-111111111111 (pour tests GET/PUT/DELETE)
    INSERT INTO itinerary (id, city) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Casablanca')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Casablanca
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('11111111-1111-1111-1111-111111111011', '11111111-1111-1111-1111-111111111111', 1),
    ('11111111-1111-1111-1111-111111111012', '11111111-1111-1111-1111-111111111111', 2),
    ('11111111-1111-1111-1111-111111111013', '11111111-1111-1111-1111-111111111111', 3)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Casablanca
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('11111111-1111-1111-1111-111111111011', 'Visite de la MosquÃ©e Hassan II'),
    ('11111111-1111-1111-1111-111111111011', 'Promenade dans la Corniche'),
    ('11111111-1111-1111-1111-111111111011', 'DÃ©jeuner au restaurant Rick''s CafÃ©'),
    ('11111111-1111-1111-1111-111111111011', 'Shopping au Morocco Mall');
    
    -- Items pour le jour 2 - Casablanca
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('11111111-1111-1111-1111-111111111012', 'Visite du quartier Habous'),
    ('11111111-1111-1111-1111-111111111012', 'MarchÃ© central de Casablanca'),
    ('11111111-1111-1111-1111-111111111012', 'DÃ©couverte de l''architecture Art DÃ©co'),
    ('11111111-1111-1111-1111-111111111012', 'DÃ®ner dans un restaurant traditionnel');
    
    -- Items pour le jour 3 - Casablanca
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('11111111-1111-1111-1111-111111111013', 'Excursion Ã  Rabat (capitale)'),
    ('11111111-1111-1111-1111-111111111013', 'Visite de la Tour Hassan'),
    ('11111111-1111-1111-1111-111111111013', 'Retour Ã  Casablanca'),
    ('11111111-1111-1111-1111-111111111013', 'PrÃ©paration du dÃ©part');
    
    -- ItinÃ©raire 2: Marrakech - 4 jours
    -- UUID: 22222222-2222-2222-2222-222222222222 (pour tests GET/PUT/DELETE)
    INSERT INTO itinerary (id, city) VALUES 
    ('22222222-2222-2222-2222-222222222222', 'Marrakech')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Marrakech
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('22222222-2222-2222-2222-222222222021', '22222222-2222-2222-2222-222222222222', 1),
    ('22222222-2222-2222-2222-222222222022', '22222222-2222-2222-2222-222222222222', 2),
    ('22222222-2222-2222-2222-222222222023', '22222222-2222-2222-2222-222222222222', 3),
    ('22222222-2222-2222-2222-222222222024', '22222222-2222-2222-2222-222222222222', 4)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('22222222-2222-2222-2222-222222222021', 'ArrivÃ©e Ã  Marrakech'),
    ('22222222-2222-2222-2222-222222222021', 'Installation Ã  l''hÃ´tel/Riad'),
    ('22222222-2222-2222-2222-222222222021', 'PremiÃ¨re dÃ©couverte de la MÃ©dina'),
    ('22222222-2222-2222-2222-222222222021', 'DÃ®ner sur la place Jemaa el-Fnaa');
    
    -- Items pour le jour 2 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('22222222-2222-2222-2222-222222222022', 'Visite du Palais Bahia'),
    ('22222222-2222-2222-2222-222222222022', 'Exploration des souks'),
    ('22222222-2222-2222-2222-222222222022', 'DÃ©jeuner dans un restaurant de la MÃ©dina'),
    ('22222222-2222-2222-2222-222222222022', 'Visite des Tombeaux Saadiens');
    
    -- Items pour le jour 3 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('22222222-2222-2222-2222-222222222023', 'Excursion dans l''Atlas'),
    ('22222222-2222-2222-2222-222222222023', 'Visite d''un village berbÃ¨re'),
    ('22222222-2222-2222-2222-222222222023', 'RandonnÃ©e dans les montagnes'),
    ('22222222-2222-2222-2222-222222222023', 'Retour Ã  Marrakech en fin de journÃ©e');
    
    -- Items pour le jour 4 - Marrakech
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('22222222-2222-2222-2222-222222222024', 'Visite du Jardin Majorelle'),
    ('22222222-2222-2222-2222-222222222024', 'MusÃ©e Yves Saint Laurent'),
    ('22222222-2222-2222-2222-222222222024', 'Derniers achats dans les souks'),
    ('22222222-2222-2222-2222-222222222024', 'DÃ©part de Marrakech');
    
    -- ItinÃ©raire 3: FÃ¨s - 2 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('33333333-3333-3333-3333-333333333333', 'FÃ¨s')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour FÃ¨s
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('33333333-3333-3333-3333-333333333031', '33333333-3333-3333-3333-333333333333', 1),
    ('33333333-3333-3333-3333-333333333032', '33333333-3333-3333-3333-333333333333', 2)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - FÃ¨s
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('33333333-3333-3333-3333-333333333031', 'ArrivÃ©e Ã  FÃ¨s'),
    ('33333333-3333-3333-3333-333333333031', 'Visite de la MÃ©dina de FÃ¨s'),
    ('33333333-3333-3333-3333-333333333031', 'DÃ©couverte des tanneries traditionnelles'),
    ('33333333-3333-3333-3333-333333333031', 'Visite de l''UniversitÃ© Al Quaraouiyine');
    
    -- Items pour le jour 2 - FÃ¨s
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('33333333-3333-3333-3333-333333333032', 'Visite du Palais Royal'),
    ('33333333-3333-3333-3333-333333333032', 'Exploration des souks spÃ©cialisÃ©s'),
    ('33333333-3333-3333-3333-333333333032', 'DÃ©jeuner dans un restaurant traditionnel'),
    ('33333333-3333-3333-3333-333333333032', 'DÃ©part de FÃ¨s');
    
    -- ItinÃ©raire 4: Chefchaouen - 2 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('44444444-4444-4444-4444-444444444444', 'Chefchaouen')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Chefchaouen
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('44444444-4444-4444-4444-444444444041', '44444444-4444-4444-4444-444444444444', 1),
    ('44444444-4444-4444-4444-444444444042', '44444444-4444-4444-4444-444444444444', 2)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Chefchaouen
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('44444444-4444-4444-4444-444444444041', 'ArrivÃ©e Ã  Chefchaouen'),
    ('44444444-4444-4444-4444-444444444041', 'Promenade dans la ville bleue'),
    ('44444444-4444-4444-4444-444444444041', 'Visite de la Kasbah'),
    ('44444444-4444-4444-4444-444444444041', 'DÃ®ner avec vue sur les montagnes');
    
    -- Items pour le jour 2 - Chefchaouen
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('44444444-4444-4444-4444-444444444042', 'RandonnÃ©e dans les montagnes du Rif'),
    ('44444444-4444-4444-4444-444444444042', 'Visite des cascades d''Akchour'),
    ('44444444-4444-4444-4444-444444444042', 'Retour Ã  Chefchaouen'),
    ('44444444-4444-4444-4444-444444444042', 'DÃ©part vers la prochaine destination');
    
    -- ItinÃ©raire 5: Essaouira - 3 jours
    INSERT INTO itinerary (id, city) VALUES 
    ('55555555-5555-5555-5555-555555555555', 'Essaouira')
    ON CONFLICT (id) DO NOTHING;
    
    -- Jours pour Essaouira
    INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
    ('55555555-5555-5555-5555-555555555051', '55555555-5555-5555-5555-555555555555', 1),
    ('55555555-5555-5555-5555-555555555052', '55555555-5555-5555-5555-555555555555', 2),
    ('55555555-5555-5555-5555-555555555053', '55555555-5555-5555-5555-555555555555', 3)
    ON CONFLICT (id) DO NOTHING;
    
    -- Items pour le jour 1 - Essaouira
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('55555555-5555-5555-5555-555555555051', 'ArrivÃ©e Ã  Essaouira'),
    ('55555555-5555-5555-5555-555555555051', 'Visite de la MÃ©dina fortifiÃ©e'),
    ('55555555-5555-5555-5555-555555555051', 'Promenade sur les remparts'),
    ('55555555-5555-5555-5555-555555555051', 'DÃ©couverte du port de pÃªche');
    
    -- Items pour le jour 2 - Essaouira
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('55555555-5555-5555-5555-555555555052', 'SÃ©ance de surf ou kitesurf'),
    ('55555555-5555-5555-5555-555555555052', 'DÃ©jeuner de poisson frais au port'),
    ('55555555-5555-5555-5555-555555555052', 'Visite des ateliers d''artisans'),
    ('55555555-5555-5555-5555-555555555052', 'Coucher de soleil sur la plage');
    
    -- Items pour le jour 3 - Essaouira
    INSERT INTO day_plan_item (day_plan_id, label) VALUES 
    ('55555555-5555-5555-5555-555555555053', 'Excursion Ã  l''Ã®le de Mogador'),
    ('55555555-5555-5555-5555-555555555053', 'Observation des oiseaux'),
    ('55555555-5555-5555-5555-555555555053', 'Derniers achats d''artisanat'),
    ('55555555-5555-5555-5555-555555555053', 'DÃ©part d''Essaouira');
    
    -- ========================================
    -- DONNÃ‰ES DE TEST - MÃ‰DIAS (exemples)
    -- ========================================
    
    -- MÃ©dias pour l'itinÃ©raire Casablanca
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('11111111-1111-1111-1111-111111111101', '11111111-1111-1111-1111-111111111111', 'casablanca-mosquee-hassan-ii.jpg', 'image/jpeg', 2048576, 'https://musafirgo.blob.core.windows.net/media/casablanca-mosquee-hassan-ii.jpg', NOW(), true),
    ('11111111-1111-1111-1111-111111111102', '11111111-1111-1111-1111-111111111111', 'casablanca-corniche.mp4', 'video/mp4', 15728640, 'https://musafirgo.blob.core.windows.net/media/casablanca-corniche.mp4', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- MÃ©dias pour l'itinÃ©raire Marrakech
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('22222222-2222-2222-2222-222222222201', '22222222-2222-2222-2222-222222222222', 'marrakech-jemaa-el-fnaa.jpg', 'image/jpeg', 1536000, 'https://musafirgo.blob.core.windows.net/media/marrakech-jemaa-el-fnaa.jpg', NOW(), true),
    ('22222222-2222-2222-2222-222222222202', '22222222-2222-2222-2222-222222222222', 'marrakech-souks.jpg', 'image/jpeg', 1873920, 'https://musafirgo.blob.core.windows.net/media/marrakech-souks.jpg', NOW(), true),
    ('22222222-2222-2222-2222-222222222203', '22222222-2222-2222-2222-222222222222', 'marrakech-atlas-trekking.mp4', 'video/mp4', 25165824, 'https://musafirgo.blob.core.windows.net/media/marrakech-atlas-trekking.mp4', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- MÃ©dias pour l'itinÃ©raire FÃ¨s
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('33333333-3333-3333-3333-333333333301', '33333333-3333-3333-3333-333333333333', 'fes-tanneries.jpg', 'image/jpeg', 1761280, 'https://musafirgo.blob.core.windows.net/media/fes-tanneries.jpg', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- MÃ©dias pour l'itinÃ©raire Chefchaouen
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('44444444-4444-4444-4444-444444444401', '44444444-4444-4444-4444-444444444444', 'chefchaouen-blue-streets.jpg', 'image/jpeg', 1925120, 'https://musafirgo.blob.core.windows.net/media/chefchaouen-blue-streets.jpg', NOW(), true),
    ('44444444-4444-4444-4444-444444444402', '44444444-4444-4444-4444-444444444444', 'chefchaouen-cascades-akchour.jpg', 'image/jpeg', 1638400, 'https://musafirgo.blob.core.windows.net/media/chefchaouen-cascades-akchour.jpg', NOW(), true)
    ON CONFLICT (id) DO NOTHING;
    
    -- MÃ©dias pour l'itinÃ©raire Essaouira
    INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
    ('55555555-5555-5555-5555-555555555501', '55555555-5555-5555-5555-555555555555', 'essaouira-ramparts.jpg', 'image/jpeg', 1441792, 'https://musafirgo.blob.core.windows.net/media/essaouira-ramparts.jpg', NOW(), true),
    ('55555555-5555-5555-5555-555555555502', '55555555-5555-5555-5555-555555555555', 'essaouira-surf-session.mp4', 'video/mp4', 33554432, 'https://musafirgo.blob.core.windows.net/media/essaouira-surf-session.mp4', NOW(), true)
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

