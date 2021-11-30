using namespace System.Net

# Because this is painful to populate a queue from Powershell, I've decided to simply send a hashtable of data to a HTTP function and let Q binding do the job for me
# The goal of this function is simply to convert our dataset sent through HTTP into a Q object.
# Input bindings are passed in via param block.

$outputQueueName = stage2

param($Request, $TriggerMetadata)

Push-OutputBinding -Name $outputQueueName -Value $Request.Body