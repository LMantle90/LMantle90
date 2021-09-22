The goal of this project was to develop a method for automating the delivery of bespoke messages to a Microsoft Teams Channel, depending on certain criteria relating to security Incidents within Microsoft Azure's Sentinel SIEM product.

Azure Logic Apps were developed, which were triggered by the generation of Security Alerts in Azure Sentinel.
The Logic App would gather the details of the Sentinel Alert that triggered it, and determine the type of Incident, and the Severity of that Incident.
Depending on the Type and Severity, the Logic App would then generate a message that would be sent to a Microsoft Teams channel, which was being monitored by a particular security team.
This message would provide details of the Sentinel Alert, as well as a link to the Alert within the Azure Portal.
