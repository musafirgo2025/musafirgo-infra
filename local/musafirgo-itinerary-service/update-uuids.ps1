# Script pour mettre à jour tous les UUIDs dans le dump-data.sql
# UUIDs prédéfinis pour la pipeline de tests

Write-Host "Mise à jour des UUIDs dans dump-data.sql..." -ForegroundColor Green

$dumpDataFile = "data/dump-data.sql"
$content = Get-Content $dumpDataFile -Raw

# Mapping des anciens UUIDs vers les nouveaux UUIDs prédéfinis
$uuidMappings = @{
    # Itinéraires
    '550e8400-e29b-41d4-a716-446655440001' = '11111111-1111-1111-1111-111111111111'  # Casablanca
    '550e8400-e29b-41d4-a716-446655440002' = '22222222-2222-2222-2222-222222222222'  # Marrakech
    '550e8400-e29b-41d4-a716-446655440003' = '33333333-3333-3333-3333-333333333333'  # Fès
    '550e8400-e29b-41d4-a716-446655440004' = '44444444-4444-4444-4444-444444444444'  # Chefchaouen
    '550e8400-e29b-41d4-a716-446655440005' = '55555555-5555-5555-5555-555555555555'  # Essaouira
    
    # Day Plans - Casablanca
    '550e8400-e29b-41d4-a716-446655440011' = '11111111-1111-1111-1111-111111111011'  # Casablanca Jour 1
    '550e8400-e29b-41d4-a716-446655440012' = '11111111-1111-1111-1111-111111111012'  # Casablanca Jour 2
    '550e8400-e29b-41d4-a716-446655440013' = '11111111-1111-1111-1111-111111111013'  # Casablanca Jour 3
    
    # Day Plans - Marrakech
    '550e8400-e29b-41d4-a716-446655440021' = '22222222-2222-2222-2222-222222222021'  # Marrakech Jour 1
    '550e8400-e29b-41d4-a716-446655440022' = '22222222-2222-2222-2222-222222222022'  # Marrakech Jour 2
    '550e8400-e29b-41d4-a716-446655440023' = '22222222-2222-2222-2222-222222222023'  # Marrakech Jour 3
    '550e8400-e29b-41d4-a716-446655440024' = '22222222-2222-2222-2222-222222222024'  # Marrakech Jour 4
    
    # Day Plans - Fès
    '550e8400-e29b-41d4-a716-446655440031' = '33333333-3333-3333-3333-333333333031'  # Fès Jour 1
    '550e8400-e29b-41d4-a716-446655440032' = '33333333-3333-3333-3333-333333333032'  # Fès Jour 2
    
    # Day Plans - Chefchaouen
    '550e8400-e29b-41d4-a716-446655440041' = '44444444-4444-4444-4444-444444444041'  # Chefchaouen Jour 1
    '550e8400-e29b-41d4-a716-446655440042' = '44444444-4444-4444-4444-444444444042'  # Chefchaouen Jour 2
    
    # Day Plans - Essaouira
    '550e8400-e29b-41d4-a716-446655440051' = '55555555-5555-5555-5555-555555555051'  # Essaouira Jour 1
    '550e8400-e29b-41d4-a716-446655440052' = '55555555-5555-5555-5555-555555555052'  # Essaouira Jour 2
    '550e8400-e29b-41d4-a716-446655440053' = '55555555-5555-5555-5555-555555555053'  # Essaouira Jour 3
    
    # Media - Casablanca
    '550e8400-e29b-41d4-a716-446655440101' = '11111111-1111-1111-1111-111111111101'  # Media Casablanca 1
    '550e8400-e29b-41d4-a716-446655440102' = '11111111-1111-1111-1111-111111111102'  # Media Casablanca 2
    
    # Media - Marrakech
    '550e8400-e29b-41d4-a716-446655440201' = '22222222-2222-2222-2222-222222222201'  # Media Marrakech 1
    '550e8400-e29b-41d4-a716-446655440202' = '22222222-2222-2222-2222-222222222202'  # Media Marrakech 2
    '550e8400-e29b-41d4-a716-446655440203' = '22222222-2222-2222-2222-222222222203'  # Media Marrakech 3
    
    # Media - Fès
    '550e8400-e29b-41d4-a716-446655440301' = '33333333-3333-3333-3333-333333333301'  # Media Fès 1
    
    # Media - Chefchaouen
    '550e8400-e29b-41d4-a716-446655440401' = '44444444-4444-4444-4444-444444444401'  # Media Chefchaouen 1
    '550e8400-e29b-41d4-a716-446655440402' = '44444444-4444-4444-4444-444444444402'  # Media Chefchaouen 2
    
    # Media - Essaouira
    '550e8400-e29b-41d4-a716-446655440501' = '55555555-5555-5555-5555-555555555501'  # Media Essaouira 1
    '550e8400-e29b-41d4-a716-446655440502' = '55555555-5555-5555-5555-555555555502'  # Media Essaouira 2
}

# Appliquer les remplacements
foreach ($oldUuid in $uuidMappings.Keys) {
    $newUuid = $uuidMappings[$oldUuid]
    $content = $content -replace [regex]::Escape($oldUuid), $newUuid
    Write-Host "Remplacé: $oldUuid -> $newUuid" -ForegroundColor Yellow
}

# Sauvegarder le fichier modifié
Set-Content -Path $dumpDataFile -Value $content -Encoding UTF8

Write-Host "Mise à jour terminée !" -ForegroundColor Green
Write-Host "UUIDs prédéfinis pour la pipeline:" -ForegroundColor Cyan
Write-Host "  Casablanca: 11111111-1111-1111-1111-111111111111" -ForegroundColor White
Write-Host "  Marrakech:  22222222-2222-2222-2222-222222222222" -ForegroundColor White
Write-Host "  Fès:        33333333-3333-3333-3333-333333333333" -ForegroundColor White
Write-Host "  Chefchaouen: 44444444-4444-4444-4444-444444444444" -ForegroundColor White
Write-Host "  Essaouira:  55555555-5555-5555-5555-555555555555" -ForegroundColor White
