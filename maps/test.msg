Message-ID: <546412AB.7090404@DeFaria.com>
Date: Wed, 12 Nov 2014 18:08:43 -0800
From: Andrew DeFaria <Andrew@DeFaria.com>
User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20100101 Thunderbird/31.2.0
MIME-Version: 1.0
To: Yubico Support <support@yubico.com>
Subject: Glutten for punishment...
Content-Type: multipart/alternative;
 boundary="------------060602060101040803010204"

This is a multi-part message in MIME format.
--------------060602060101040803010204
Content-Type: text/plain; charset=utf-8; format=flowed
Content-Transfer-Encoding: 7bit

OK I returned the Yubico Security key thing and bought the Yubikey Neo. 
I'm on Windows 7 with Chrome  38.0.2125.111 m. I even have the FIDO U2F 
(Universal 2nd Factor) extension 0.9.3 installed.

I go to http://demo.yubico.com/start/u2f/neo?tab=register and insert my 
key. Unlike the instructions my yubikey is not a "flashing U2F device" - 
the light is on solid. I hit the button anyway. It does nothing but 
eventually times out with:


        Registration failed!

    Make sure you have a U2F device connected, and try again.

      Traceback (most recent call last):
       File "/root/python-u2flib-server-demo/examples/yubiauth_server.py", line 159, in __call__
         raise Exception("FIDO Client error: %s" % error)
    Exception: FIDO Client error: 5 (TIMEOUT)
      

/root? Really?

Similarly when I go to my Google account under Security Keys and follow 
the instruction there the yubikey doesn't do anything! When I tap the 
gold circle the light goes out for a brief second then back on. But the 
"Now insert (and tap) your Security Key" with the spinning progress 
indicator goes forever...

Now what?
-- 
Andrew DeFaria <http://defaria.com>
ClearSCM, Inc. <http://clearscm.com>

--------------060602060101040803010204
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: 8bit

<html>
  <head>

    <meta http-equiv="content-type" content="text/html; charset=utf-8">
  </head>
  <body style="background-color: rgb(255, 255, 255); color: rgb(0, 0,
    0);" bgcolor="#FFFFFF" text="#000000">
    OK I returned the Yubico Security key thing and bought the Yubikey
    Neo. I'm on Windows 7 with Chrome  38.0.2125.111 m. I even have the
    FIDO U2F (Universal 2nd Factor) extension 0.9.3 installed. <br>
    <br>
    I go to <a class="moz-txt-link-freetext" href="http://demo.yubico.com/start/u2f/neo?tab=register">http://demo.yubico.com/start/u2f/neo?tab=register</a> and insert
    my key. Unlike the instructions my yubikey is not a "flashing U2F
    device" - the light is on solid. I hit the button anyway. It does
    nothing but eventually times out with:<br>
    <blockquote>
      <h2 style="margin: 10px 0px; font-family: 'Helvetica Neue',
        Helvetica, Arial, sans-serif; font-weight: bold; line-height:
        40px; color: rgb(51, 51, 51); text-rendering:
        optimizelegibility; font-size: 31.5px; font-style: normal;
        font-variant: normal; letter-spacing: normal; orphans: auto;
        text-align: start; text-indent: 0px; text-transform: none;
        white-space: normal; widows: auto; word-spacing: 0px;
        -webkit-text-stroke-width: 0px;">Registration failed!</h2>
      <p style="margin: 0px 0px 10px; color: rgb(51, 51, 51);
        font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
        font-size: 18px; font-style: normal; font-variant: normal;
        font-weight: 200; letter-spacing: normal; line-height: 30px;
        orphans: auto; text-align: start; text-indent: 0px;
        text-transform: none; white-space: normal; widows: auto;
        word-spacing: 0px; -webkit-text-stroke-width: 0px;">Make sure
        you have a U2F device connected, and try again.</p>
      <pre style="padding: 9.5px; font-family: Monaco, Menlo, Consolas, 'Courier New', monospace; font-size: 13px; color: rgb(51, 51, 51); border-top-left-radius: 4px; border-top-right-radius: 4px; border-bottom-right-radius: 4px; border-bottom-left-radius: 4px; display: block; margin: 0px 0px 10px; line-height: 20px; word-break: break-all; word-wrap: break-word; white-space: pre-wrap; border: 1px solid rgba(0, 0, 0, 0.14902); font-style: normal; font-variant: normal; font-weight: 200; letter-spacing: normal; orphans: auto; text-align: start; text-indent: 0px; text-transform: none; widows: auto; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(245, 245, 245);"> Traceback (most recent call last):
  File "/root/python-u2flib-server-demo/examples/yubiauth_server.py", line 159, in __call__
    raise Exception("FIDO Client error: %s" % error)
Exception: FIDO Client error: 5 (TIMEOUT)
 </pre>
    </blockquote>
    <div class="moz-signature">/root? Really?<br>
      <br>
      Similarly when I go to my Google account under Security Keys and
      follow the instruction there the yubikey doesn't do anything! When
      I tap the gold circle the light goes out for a brief second then
      back on. But the "Now insert (and tap) your Security Key" with the
      spinning progress indicator goes forever...<br>
      <br>
      Now what?<br>
      -- <br>
      <style type="text/css">
body {
  font:			Helvetica, Arial, sans-serif;
}
p {
  font:			Helvetica, Arial, sans-serif;
}
.standout {
  font-family:		verdana,
			arial,
			sans-serif;
  font-size:		12px;
  color:		#993333;
  line-height:		13px;
  font-weight:		bold;
  margin-bottom:	10px;
}
.code {
  border-top:		1px solid #ddd;
  border-left:		1px solid #ddd;
  border-right:		2px solid #000;
  border-bottom:	2px solid #000;
  padding:		10px;
  margin-top:		5px;
  margin-left:		5%;
  margin-right:		5%;
  background:		#ffffea;
  color:		black;
  font-family:		courier;
  white-space:		pre;
  -moz-border-radius:	10px;
}
.terminal {
  border-top:		10px solid #03f;
  border-left:		1px solid #ddd;
  border-right:		2px solid grey;
  border-bottom:	2px solid grey;
  padding:		10px;
  margin-top:		5px;
  margin-left:		5%;
  margin-right:		5%;
  background:		black;
  color:		white;
  font-family:		courier;
  white-space:		pre;
  -moz-border-radius:	10px;
}
a:link { 
  color:		blue;
}

a:visited {
  color:		darkblue;
}

a:hover { 
  color:		black;
  background-color:	#ffffcc;
  text-decoration:	underline;
}

a:active { 
  color: 		red;
}
</style><a href="http://defaria.com">Andrew DeFaria</a><br>
      <a href="http://clearscm.com">ClearSCM, Inc.</a><br>
    </div>
  </body>
</html>

--------------060602060101040803010204--
