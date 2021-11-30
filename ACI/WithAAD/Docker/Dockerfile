
FROM mcr.microsoft.com/powershell:alpine-3.12

SHELL ["pwsh", "-command", "$ErrorActionPreference = 'Stop';"]

RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
RUN Install-module MSAL.PS -AcceptLicense

COPY . /usr/

WORKDIR /usr/

CMD ["pwsh","-File","/usr/DemoACIScript.ps1","-Verbose"]