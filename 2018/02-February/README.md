# Scottish PowerShell & DevOps User Group Meetup on 28 February 2018

Agenda:

> Note that the presentation listed in the Meeting Agenda by Mathias Jessen did not take place due to bad weather. The presentation was reschedueld to [March](https://github.com/psdevopsug/usergroup/tree/master/2018/03-March)

* [Meeting Agenda](https://github.com/psdevopsug/usergroup/blob/master/2018/02-February/MeetingAgenda.pptx);
* Presentation - [Automating Windows Servicing using Microsoft solutions & Community tools](https://github.com/psdevopsug/usergroup/tree/master/2018/02-February/Presentation-Automating_Windows_Servicing_by_Simon_Binder) by [Simon Binder](https://bindertech.se);
 I asked Simon a couple of questions that he was unfortunately unable to hear so I emailed him these questions and he replied with the answers below:

  * _Q_: **The Reactive Testing is very much Agile for deployment (as you said). In any of the clients I have worked with I think they would have a heart attack if I mentioned to them that we wouldn't test all the apps but would deploy, fix and move forward. What challenges have you had to overcome with clients?**
  
  * _A_: As you say, most organizations reacts the way you are describing. The best way to overcome it is to:

    1. Use the available data. By using Upgrade Readiness (the OMS solution, ill get back to the cost later on) you get a good amount of data to work with and somewhere to start off. Also, looking at compatibility numbers from Microsoft, Microsoft Partners – but also other organizations usually help.
    2. Be prepared for the challenge. This can really be divided into to parts, preparation and hard work. Many organizations start their Windows 10 servicing strategy to late – which ends up creating a lot of stress and likely a bad user experience and an even worse experience for IT. If you take your time and plan ahead, you get a lot more time and can take your time to roll it out. Just because its an ongoing process, you don't need to rush it. You also need to be prepared to work hard, it wont be easy – definitely not the first time – but it will be easier, cheaper and faster than doing a proactive testing. Its about ensuring that you have the right people available when you need to fix something, and that you have the proper tools.
    3. And lastly, its about a change in mindset and in the organization. That's why I like to call myself, and other like me,Evangelists. Because my mission, as I see it, would be to give my customers confidence, tools and reasons to change. If I’m confident in that it will work, and are able to communicate that positive feeling it becomes a lot easier. It may sound fluffy, but it really makes a huge different, for the organization as a whole. Also – its not only IT that needs to change. Users needs to take a bit more responsibility (like executing a Task Sequence), Application Owners/Managers needs to help IT with testing, looking ahead for new updates to their applications etc, IT-managers need to ensure that the right people do the right thing and Management in general need to understand the value of the change.

  * _Q_: **OMS in Azure is free?**

  * _A_: When it comes to OMS – OMS used to have a free tier, but it doesn't any more I'm afraid. However, if you set up OMS and only enable Upgrade Readiness and Upgrade compliance, those solutions will be free – it's a service Microsoft provides to help with migrations – and also ensure that as many machines as possible send telemetry data.

Scottish PowerShell & DevOps User Group:

* [Website](https://psdevopsug.scot)
* [Presentations on Github](https://git.psdevopsug.scot)
* [Twitter](https://twitter.com/scotpsug)
* [Facebook](https://facebook.psdevopsug.scot)
* [YouTube](https://video.psdevopsug.scot)