<?php $page_title = "MAPS Mobile";
// We need to locate the main site includes. 
// Since this file is in /opt/clearscm/maps/mobile/, and the site root is /opt/defaria.com/
// But visually it is served as /maps/mobile/.
// The 'frame_header.php' is in /opt/defaria.com/includes/.
// We can use the document root to find it if we are running under the main site context.
// However, /maps is an Alias.
// If we are included via the iframe and standard routing, we might need a relative path or absolute path.
// Let's assume absolute path for simplicity since we know the server structure.
include '/opt/defaria.com/includes/frame_header.php';
?>

<style>
    .page-title {
        color: var(--google-red);
    }
</style>

<div class="container">
    <h1 class="page-title">MAPS Mobile</h1>
    <p>
        <img src="../app/img/About.png" alt="MAPS Mobile App About Screen"
            style="float: left; margin: 0 1rem 1rem 0; width: 200px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
        I decided to try out <a href="https://en.wikipedia.org/wiki/Vibe_coding" target="_blank">Vibe Coding</a>. What
        better thing to
        do than to take my MAPS application and create a mobile app for it?
        The idea of learning how to code an Android app, after using mostly scripting (Perl, PHP, Bash) seemed daunting.
        But maybe with AI...
    </p>

    <p>
        <img src="../app/img/Main.png" alt="MAPS Mobile App Main Screen"
            style="float: right; margin: 0 0 1rem 1rem; width: 200px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
        I started with VSCode and Gemini but soon switched to using Google's Antigravity (and I'm not going back!).
        Turns out Android apps can be written in VSCode and
        Antigravity using Java. I further augmented my development workflow by configuring adb and scrcpy such that I
        can see and more easily deal with and Android app.
        Now I just tell Gemini, "OK. Looks good - deploy that app to my phone" and wham! I have a new version to test. I
        can screen captures and paste it into Antigravity
        and complain, "No that still doesn't look right" and Antigravity will analyze the screenshot, figure out the
        text or element placement/color and fix the visual
        bug, compile, build, package and deploy your new version to the phone in a few seconds. This is cool!
    </p>

    <p>
        I even had Gemini design a shield logo and it came up with an old style map and I decided to put both of them
        together.
    </p>

    <p>
        <img src="../app/img/Returned.png" alt="MAPS Mobile App Returned Screen"
            style="float: left; margin: 0 1rem 1rem 0; width: 200px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
        Often I want to see the email messages that have been returned. Here I have the info summarized as the email
        address, datetime of email, what list they were on, the number of times we received email from that sender and
        the rule that triggered the list. Next is the subject line that, when tapped, displays the contents of the email
        being held in the MAPS database. The buttons next to sender are to add this sender to the Null List, the White
        List and the Black List. The last button (X) simply adds the whole domain on the Null List. I often null list
        entire domains.
    </p>

    <p>
        <img src="../app/img/Display.png" alt="MAPS Mobile App Display Screen"
            style="float: right; margin: 0 0 1rem 1rem; width: 200px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
        Antigravity essentially created a MainActivity.java file as an interface to my Perl/PHP code in another
        repository. Since the webpage portion of my MAPS application was HTTP based, Antigravity created calls to the
        MAPS webapp to grab/work the data and then helped stylize the app.<br>
        <br>
        I even updated and upgraded the web version of MAPS, adding support for UTF-8, displaying the email more fully,
        yet disallow any clicking
        of links or running of scripts, instead just copying the link to the clipboard so I could examine it to see if
        it was ligit. Antigravity handled this with ease.
    </p>

    <p>
        <img src="../app/img/Search.png" alt="MAPS Mobile App Search Screen"
            style="float: left; margin: 0 1rem 1rem 0; width: 200px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
        Then I started filling out the functionality by adding things like Search and later Check Email. I was now more
        of
        a designer/architect just describing what I wanted done and Antigravity would do it for me. Yes, some times it
        messed up and sometimes I had to suggest a different direction or to revert the last change.
    </p>

    <p>
        <img src="../app/img/Top 20.png" alt="MAPS Mobile App Top 20 Screen"
            style="float: right; margin: 0 0 1rem 1rem; width: 200px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
        I could just describe to the AI what I wanted to see on the screen and it would do it. I was excited and scared
        at the same time. I loved expressing my ideas and seeing them pop into existance. But I also noticed that during
        most of
        this process I didn't touch a stitch of code! And I also didn't bother to investigate what the AI did to my code
        and/or try
        to learn how it worked so that I could utilize it myself later. I was too jazzed seeing the quick progress! I
        know I can go back
        and learn how it works if I wanted to and there were times where I had to sort of scold the AI saying "Nope, you
        don't want to
        go down that path", etc. Is this what software engineering is morphing into?
    </p>


</div>

<?php include '/opt/defaria.com/includes/footer.php'; ?>