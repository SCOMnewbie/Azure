# Dump AAD tenant from a guest account (default behavior)

Following this [article](https://docs.microsoft.com/en-us/azure/active-directory/users-groups-roles/users-restrict-guest-permissions), it seems that by default you can extract a lot of things with a guest user account. I’ve written those 2 proofs of concepts scripts (ADAL and MSAL for fun) to expose how you can extract an entire AAD tenant easily. We’re talking about extracting **at least direct reports (manager), memberOf groups, and managers**...

To reproduce:

* Fill the Tenant Id with yours
* Make sure the DLLs and scripts are unlocked 😊. By default, Windows considers those as bad files. Check the thumbprint if you’re afraid. The MSAL script use the MSAL.PS module instead of the library, it's simpler.
* Open a Ps V5 console (should work with v7 as well) and run .\DumpInfoFromGuestAccount.ps1 -route me
* The script should ask you to login, this is where you have to use a **guest account**.
  *  You should see your guest user information returned from graph.
* Then you should be able tp play with command like .\DumpInfoFromGuestAccount.ps1 -route directreports -userprincipalname <A valid email address> or .\DumpInfoFromGuestAccount.ps1 -route manager -userprincipalname <A valid email address>

Now you start to understand normally 😊