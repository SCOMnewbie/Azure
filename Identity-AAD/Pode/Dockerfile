FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

# Ubuntu require a -m to create the home
# MSAL.PS seems to require root ...
#RUN useradd -u 1001 nonroot -m
WORKDIR /usr/src/api

RUN pwsh -c Install-Module -Name Pode -Repository PSGallery -RequiredVersion '2.8.0' -Force -AcceptLicense -Verbose -Scope Allusers
RUN pwsh -c Install-Module -Name ValidateAadJwt -RequiredVersion '0.0.6' -Repository PSGallery -Force -Verbose -Scope Allusers
RUN pwsh -c Install-Module -Name MSAL.PS -Repository PSGallery -RequiredVersion '4.37.0.0' -Force -AcceptLicense -Verbose -Scope Allusers

COPY server.psd1 /usr/src/api
COPY startpode.ps1 /usr/src/api
COPY Dockerfile /usr/src/api
COPY cert.pem /usr/src/api
COPY key.pem /usr/src/api
COPY Authentication /usr/src/api/Authentication

#USER 1001

CMD ["pwsh","-File","./startpode.ps1","-Verbose"]