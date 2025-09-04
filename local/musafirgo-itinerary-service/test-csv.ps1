# Test CSV generation
$testData = @(
    [PSCustomObject]@{
        'Endpoint' = 'http://localhost:8080/api/itineraries'
        'Méthode' = 'GET'
        'Description' = 'List all itineraries'
        'Paramètres' = 'Query: city=Casablanca'
        'Code HTTP Attendu' = 200
        'Code HTTP Reçu' = 200
        'Statut' = 'OK'
        'Message Erreur' = ''
        'Timestamp' = '2025-09-04 09:44:34'
    }
)

$testData | Export-Csv -Path 'test.csv' -NoTypeInformation -Encoding UTF8
Get-Content 'test.csv'

