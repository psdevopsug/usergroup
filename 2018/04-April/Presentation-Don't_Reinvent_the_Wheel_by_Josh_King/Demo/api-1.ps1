$Word = 'programming'

$Uri = "https://en.oxforddictionaries.com/definition/$Word"

$Entry = Invoke-WebRequest -Uri $Uri -Headers $Headers
$Definitions = $Entry.ParsedHtml.getElementsByTagName('span') |
        where className -eq 'ind' |
        select innerText

$Definitions
