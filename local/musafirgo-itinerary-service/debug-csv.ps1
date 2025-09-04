# Debug CSV generation
$Global:ExcelTestResults = @()

$Global:ExcelTestResults += [PSCustomObject]@{
    'Endpoint' = 'http://localhost:8080/api/itineraries'
    'Méthode' = 'GET'
    'Description' = 'List all itineraries'
    'Paramètres' = 'None'
    'Code HTTP Attendu' = 200
    'Code HTTP Reçu' = 200
    'Statut' = 'OK'
    'Message Erreur' = ''
    'Timestamp' = '2025-09-04 09:45:55'
}

Write-Host "Nombre d'éléments: $($Global:ExcelTestResults.Count)"
Write-Host "Contenu:"
$Global:ExcelTestResults | Format-Table

$Global:ExcelTestResults | Export-Csv -Path 'debug.csv' -NoTypeInformation -Encoding UTF8
Write-Host "Fichier CSV créé"
Get-Content 'debug.csv' -Encoding UTF8

