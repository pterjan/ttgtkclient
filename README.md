# ttgtkclient
GTK Client for HP P1218A TopTools Remote Control

From December 19 to December 28 2011 zarb.org main server was down.
This server hosted many things including my blog, Mageia website, PLF, ... The reason why it took so long is that the server was in the south of France, kindly hosted by Lost Oasis and we had no one nearby to physically access it, and in this case we had lost our main raid array.

This server (kindly donated by HP almost 10 years earlier) has a remote administration card (P1218A) but it is not really usable for anything except rebooting the machine. The remote console more or less works with some of the java versions from Sun, but most of the time it only displays the top third of the screen, until next refresh when it goes black, and misses many keystrokes. This made it unsuitable for accessing the RAID BIOS and finding the problem.

After about a week, for some unknown reason (I could have done it many times over the last 10 years), I thought of looking at the communications between the applet and the management card. Everything was clear text and very simple. The next days I wrote a ruby-gtk client for the card, accessed the BIOS, found that the 4 disks had been marked has failed without errors and were correctly syncronized, and put them back online.

I have never used this code again since.

This project is not endorsed by HP or my employer.
