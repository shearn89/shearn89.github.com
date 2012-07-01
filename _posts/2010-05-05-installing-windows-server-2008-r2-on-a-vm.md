---
layout: post
title: Installing Windows Server 2008 R2 on a VM
---

May 5, 2010, 1:39 pm

# Installing Windows Server 2008 R2 on a VM #

I've just been installing Windows Server 2008 R2 onto a virtual machine, since it's freely available from [Dreamspark](http://www.dreamspark.com)  (thanks, [Mike Borodizn](http://twitter.com/mikeborozdin)), and is easy to convert to a workstation that's a bit lighter and faster than Windows 7 (apparently). It also seems to run all the games I want to play, along with the software I regularly use. Sooo, I thought I'd put a brief howto together!

I'll be using VirtualBox for this, with a Vista 32-bit host, and installing Server 2008 R2 64-bit as the guest.

 1. Create a new VM in virtualbox.
 2. Once done, select it and hit settings, and change the OS Type to **Windows 7 (64bit)**. Also go into the System menu (on the left), make sure CD-ROM is above hard drive in the boot order, and tick the **Enable IO APIC**. Give it more memory if you want, and more video memory in the "Display" tab. Check the **Enable 3d acceleration** box too.
 3. Mount your Server 2008 disc to a virtual drive, or use a physical disc, and make sure that the VM can see it (Settings -> Storage -> IDE Controllers).
 4. Double click the machine to start it up.
 5. If you get a black screen with errors, it's most likely that you haven't checked **Enable IO APIC**. Do that.
 6. Install it as normal, fairly easy: click a few boxes, choose custom install, install as a new OS.
 7. Eventually, it'll boot to a screen that lets you choose a new password. This has to include letters, numbers, and punctuation, and needs to be a decent length.
 8. You'll get to the desktop. A sort of "first run" window will pop up, which actually prompts you to do most of the configuration you need. Ignore the **Roles** options, and go to **Features**. Install the **Desktop Experience** module, and reboot. It may ask for a reason why you're rebooting, just give it a brief description and click okay.
 9. Once you've rebooted, we'll set about making it a more Workstation-like computer, and less server-y.

So, we've installed all we need, now we do the configuration to make it more like a desktop, and less like a server. Most of this info comes from [this site](http://www.win2008workstation.com/) , but I'll summarise it here.

 - First, create a new non-admin user.
   1. Hit Windows key+r.
   2. type control userpasswords2 and hit enter.
   3. Click Add... and fill in the info.
   4. Enter a password twice (doesn't have to be as strong as the admin one), then click Standard User on the next screen. Then click Finish.

 - We'll also configure this user to autologin:
   1. Select the new user in the User Accounts pane.
   2. Untick Users must enter a user name and password to use this computer, then click Apply and enter the user's password.
   3. Click OK.
 - Now we'll allow this user to shutdown the pc, and disable the annoying shutdown events tracker:
   1. First, do another windows+r and type gpedit.msc
   2. Go to Computer Configuration -> Administrative Templates -> System and double click on Display Shutdown Event Tracker on the right hand pane. Disable it, and click okay.
   3. Then, go to Computer Configuration -> Windows Settings  -> Security Settings -> Local Policies  -> User Rights Assignment.
   4. Find Shut down the system in the right hand pane, and double click.   5. 
   6. Add the username of your new user, and click Check Names. Click OK, then OK again.

 - Lastly, we'll enable the audio service and themes, and reboot to our new user.
   1. Windows+r, services.msc, enter.
   2. Find Themes, change startup type to Automatic, and click apply.
   3. Find Windows Audio, and do the same.
   4. Click Okay (etc), to save and close this window. Don't reboot just yet!
   5. Click Start -> Control Panel, and find the Sound tab (either in Hardware and Sound, or just Sound).
   6. Select the default device, click properties, and click the advanced tab. Uncheck Give exclusive mode application priority. Click okay twice to save and quit.
   7. Finally, reboot. It should happen fairly quickly, and auto log you in to your user account.

 - Make it pretty by right-clicking on the desktop, and choosing Personalize, followed by the Aero Theme. Click okay/apply/whatever.
 - Lastly, optimize it for applications, not background services:
   1. Start -> right click on Computer, and go Properties.
   2. Advanced System Settings -> Perfomance -> Settings.
   3. Advanced tab, click the box that says Programs, and click okay twice.

 - Maybe reboot again, just to be on the safe side.

So, we're done! I myself currently have problems where the VM doesn't appear to have any network interfaces at all, or any audio devices. I'm still working out why.

Take a look at [this site](http://www.win2008workstation.com/)  for more info, especially [this page about games and entertainment.](http://www.win2008workstation.com/win2008/games-and-entertainment) Its pretty handy.

Please feel free to leave comments, or give me info on how to fix my broken stuff! I'll add it into the guide somewhere... When I get time and can be bothered, I'll add in screenshots.
    

