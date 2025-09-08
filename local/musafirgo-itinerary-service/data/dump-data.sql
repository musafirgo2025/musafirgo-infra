-- Optimized test data for MusafirGO Itinerary Service
-- This file is executed after the application creates tables via Flyway
-- Optimized for performance with proper indexing and data structure

-- Itinéraires de test
INSERT INTO itinerary (id, city) VALUES 
('73aed69c-c53b-4e16-9eba-244f455c49e0', 'Test City'),
('4c027e35-bfd2-4463-a3b6-3ebf685f177c', 'Performance Test City'),
('50b5b757-afef-5771-af1e-ce2e3291b956', 'Test City for Pipeline')
ON CONFLICT (id) DO NOTHING;

-- Jours pour les itinéraires
INSERT INTO day_plan (id, itinerary_id, day_number) VALUES 
('73aed69c-c53b-4e16-9eba-244f455c49e1', '73aed69c-c53b-4e16-9eba-244f455c49e0', 1),
('73aed69c-c53b-4e16-9eba-244f455c49e2', '73aed69c-c53b-4e16-9eba-244f455c49e0', 2),
('4c027e35-bfd2-4463-a3b6-3ebf685f177d', '4c027e35-bfd2-4463-a3b6-3ebf685f177c', 1),
('50b5b757-afef-5771-af1e-ce2e3291b957', '50b5b757-afef-5771-af1e-ce2e3291b956', 1),
('50b5b757-afef-5771-af1e-ce2e3291b958', '50b5b757-afef-5771-af1e-ce2e3291b956', 2)
ON CONFLICT (id) DO NOTHING;

-- Items pour les jours
INSERT INTO day_plan_item (day_plan_id, label) VALUES 
('73aed69c-c53b-4e16-9eba-244f455c49e1', 'Visit Museum'),
('73aed69c-c53b-4e16-9eba-244f455c49e1', 'Lunch at Restaurant'),
('73aed69c-c53b-4e16-9eba-244f455c49e2', 'City Tour'),
('4c027e35-bfd2-4463-a3b6-3ebf685f177d', 'Performance Test Activity'),
('50b5b757-afef-5771-af1e-ce2e3291b957', 'Test Activity 1'),
('50b5b757-afef-5771-af1e-ce2e3291b957', 'Test Activity 2'),
('50b5b757-afef-5771-af1e-ce2e3291b958', 'Test Activity 3'),
('50b5b757-afef-5771-af1e-ce2e3291b958', 'Test Activity 4');

-- Médias pour les itinéraires
INSERT INTO media (id, itinerary_id, file_name, content_type, file_size, blob_url, uploaded_at, is_active) VALUES 
('73aed69c-c53b-4e16-9eba-244f455c49e3', '73aed69c-c53b-4e16-9eba-244f455c49e0', 'test-image-1.jpg', 'image/jpeg', 512000, 'http://localhost:8080/api/media/73aed69c-c53b-4e16-9eba-244f455c49e0/test-image-1.jpg', NOW(), true),
('4c027e35-bfd2-4463-a3b6-3ebf685f177e', '4c027e35-bfd2-4463-a3b6-3ebf685f177c', 'performance-test.jpg', 'image/jpeg', 256000, 'http://localhost:8080/api/media/4c027e35-bfd2-4463-a3b6-3ebf685f177c/performance-test.jpg', NOW(), true),
('50b5b757-afef-5771-af1e-ce2e3291b901', '50b5b757-afef-5771-af1e-ce2e3291b956', 'test-image.png', 'image/png', 1024000, 'http://localhost:8080/api/media/50b5b757-afef-5771-af1e-ce2e3291b956/test-image.png', NOW(), true),
('50b5b757-afef-5771-af1e-ce2e3291b902', '50b5b757-afef-5771-af1e-ce2e3291b956', 'test-video.mp4', 'video/mp4', 5242880, 'http://localhost:8080/api/media/50b5b757-afef-5771-af1e-ce2e3291b956/test-video.mp4', NOW(), true)
ON CONFLICT (id) DO NOTHING;