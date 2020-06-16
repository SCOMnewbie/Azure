# How to be warned for all RBAC changes over Teams in real time

## Introduction

The idea is to be warned when an owner add/remove grant a new role to someone.

The solution based on:
* Azure monitor (Alerts) with specific events we want to subscribe to on activity logs.
* Logic App to compute the event triggered.
* A Teams channel to receive the warning message

If you prefer picture:

![](images/infra.png)

!!! **Note**: When a user grant or remove access, the events generated don’t use the same schema … In other words, therefore I had to duplicate my action group and my Logic App because the way to compute the event is not the same.

!!! **Note**: To get your Teams GroupId and ChannelId if you don’t want to use Powershell or another admin tool, you can simply right click on your group and choose “Get link to channel”.

The flow is simple:

1- Someone grant/remove access to a scope (Sub, RG, Resource).
2- An event appears in the activity logs which trigger one of the 2 alerts.  
3- Depending of the event type, Azure monitor trigger one of the 2 logic App.
4- The logic App compute the event and create a message in a specific Teams Channel

## Deployment

To deploy the solution click here.

