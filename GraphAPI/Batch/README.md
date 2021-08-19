
# Introduction

This script will show how to rely on the Graph API batch endpoint to speed things up when you have a lot of queries to execute on graph.
Instead of doing it one by one from your machine/server, you ask graph to execute them 20 by 20 and graph is quicker than your server :p.
I went down from 13 minutes with 3000+ graph queries to 1 minute and 13 seconds, not bad?

More info with the blog post here -> https://scomnewbie.github.io/posts/usegraphapibatching/

# Pre requisites

* Create service account with a UPN (not clientId/ Secret). You don't need to assign any roles.
* Create a 365 group without Teams associated. I just need an email address in my case.
* Make the service account owner of the 365 group. We will use delegated permission, not application (over privileged)
* Create an App registration with:
    - Group.Read.All (Delegated) to  permit us to read all directory groups and members. 
    - Application.Read.All to permit us to read groups assignment to our app and read members
    - GroupMember.ReadWrite.All to permit us to add/remove members to our DL(s)
    - Public application (We will use ROPC in our case because we don't want interraction)
    - Redirect URI http://localhost
* Add Service Principal
    - User assignment required
    - add the service account user to user & group. Now only our service account can use this application.


Because we will need several functions, I've decided to add all functions into a loadme.psm1 file.

Now configure the GraphBatch.ps1 with your values and you should be good to go.
