throw "Don't press F5 here, execute commands one by one"
$ErrorActionPreference = 'Stop'

#Create docker image (lowercase)
#It should create a new local image called poc-ud
docker build -t poc-ud .

#run it
docker run --rm -p 80:80 poc-ud

#Mass clean the exited/created containers because I've forgot the --rm
docker ps -a --format '{{json .}}' | ConvertFrom-Json | where Status -match 'Created|exited' | Select-Object -ExpandProperty ID | %{docker rm $_}

#Time to test once container is running should return machine name
start "http://localhost:80/api/helloworld"

#And if we want to test with Invoke-RestMethod (This is how we use REST API at the end :p)
Invoke-Command -ScriptBlock { Invoke-RestMethod -Uri http://localhost/api/helloworld }

