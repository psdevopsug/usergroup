$Word = 'programming'

$Headers = @{
    app_id = $OxfordId
    app_key = $OxfordKey
}

$Uri = "https://od-api.oxforddictionaries.com/api/v1/entries/en/$Word"

$Entry = Invoke-RestMethod -Uri $Uri -Headers $Headers
$Definitions = $Entry.results.lexicalEntries.entries.senses.definitions

$Definitions
