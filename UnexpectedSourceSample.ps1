$apiKey = "##REDACTED##"
$projectName = "sample"
$endpoint = "https://##REDACTED##.cognitiveservices.azure.com"
$headers = @{'Ocp-Apim-Subscription-Key' = $apiKey; 'Content-Type' = 'application/json'}

Write-Host "** Create a project **"
Invoke-WebRequest -Method Patch  -Uri "$endpoint/language/query-knowledgebases/projects/$($projectName)?api-version=2021-10-01" -Headers $headers -Body @"
{
      'description': 'sample project.',
      'language': 'en',
      'settings': {
        'defaultAnswer': 'No good match found for your question in the knowledge base.'
      },
      'multilingualResource': true
  }
"@

Write-Host "** Add a new qna to the project with a source of 'original' **"
$addResponse = Invoke-WebRequest -Method Patch -Uri "$endpoint/language/query-knowledgebases/projects/$($projectName)/qnas?api-version=2021-10-01" -Headers $headers -Body @"
[
    {
        'op': 'add',
        'value':{
            'id': 1,
            'answer': 'The latest question answering docs are on https://docs.microsoft.com',
            'source': 'original',
            'questions': [
                'Where do I find docs for question answering?'
            ],
            'metadata': {},
            'dialog': {
                'isContextOnly': false,
                'prompts': []
            }
        }
    }
]
"@

$addSucceeded = $false

While ($addSucceeded -eq $false) 
{
    Write-Host "** Wait for job complete **"
    Start-Sleep -Seconds 5
    $addStatusResponse = Invoke-WebRequest -Method Get -Uri $addResponse.Headers['operation-location'] -Headers $headers 
    $addSucceeded = (ConvertFrom-Json $addStatusResponse.Content).status -eq 'succeeded'
}

Write-Host "** Get sources **"
$getSourcesResponse = Invoke-WebRequest -Method Get -Uri "$endpoint/language/query-knowledgebases/projects/$($projectName)/sources?api-version=2021-10-01" -Headers $headers 
$sources = (ConvertFrom-Json $getSourcesResponse.Content).value

Write-Host "** Project now has 1 source called 'original' which is what I expected **"
Write-Host ($sources | Format-Table | Out-String)


Write-Host "** Now we make a change to the qna, which represents a user editing the qna and changing it to a new source. First get the existing Qnas Id **"

$getQnasResponse = Invoke-WebRequest -Method Get -Uri "$endpoint/language/query-knowledgebases/projects/$($projectName)/qnas?api-version=2021-10-01" -Headers $headers 
$qnaId = (ConvertFrom-Json $getQnasResponse.Content).value.id
Write-Host Id $qnaId

Write-Host "** Perform a Replace operation on the qna in the project, to change source to 'newSource' **"
$replaceResponse = Invoke-WebRequest -Method Patch -Uri "$endpoint/language/query-knowledgebases/projects/$($projectName)/qnas?api-version=2021-10-01" -Headers $headers -Body @"
[
    {
        'op': 'replace',
        'value':{
            'id': $qnaId,
            'answer': 'The latest question answering docs are on https://docs.microsoft.com',
            'source': 'newSource',
            'questions': [
                'Where do I find docs for question answering?'
            ],
            'metadata': {},
            'dialog': {
                'isContextOnly': false,
                'prompts': []
            }
        }
    }
]
"@

$replaceSucceeded = $false

While ($replaceSucceeded -eq $false) 
{
    Write-Host "** Wait for job complete **"
    Start-Sleep -Seconds 5
    $replaceStatusResponse = Invoke-WebRequest -Method Get -Uri $replaceResponse.Headers['operation-location'] -Headers $headers 
    $replaceSucceeded = (ConvertFrom-Json $replaceStatusResponse.Content).status -eq 'succeeded'
}

Write-Host "** Get Qnas to see the source has changed... **"

$getQnasResponse = Invoke-WebRequest -Method Get -Uri "$endpoint/language/query-knowledgebases/projects/$($projectName)/qnas?api-version=2021-10-01" -Headers $headers 
$qnas = (ConvertFrom-Json $getQnasResponse.Content).value

Write-Host "** The Qna has the expected source 'newSource' **"
Write-Host ($qnas | Format-Table | Out-String)

Write-Host "** Get sources **"
$getSourcesResponse2 = Invoke-WebRequest -Method Get -Uri "$endpoint/language/query-knowledgebases/projects/$($projectName)/sources?api-version=2021-10-01" -Headers $headers 
$sources2 = (ConvertFrom-Json $getSourcesResponse2.Content).value

Write-Host "** Project still has only 1 source called 'original' which is NOT what I expected, I expected to see one source called 'newSource' **"
Write-Host ($sources2 | Format-Table | Out-String)

