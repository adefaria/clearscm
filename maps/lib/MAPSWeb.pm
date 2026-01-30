#################################################################################
#
# File:         $RCSfile: MAPSWeb.pm,v $
# Revision:     $Revision: 1.1 $
# Description:  Routines for generating portions of MAPSWeb
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
package MAPSWeb;

use strict;
use warnings;

use base qw(Exporter);

use DateUtils;

use MIME::Parser;
use MIME::Words qw(:all);

use MAPS;
use MAPSLog;
use Encode;

use CGI
  qw(:standard *table start_Tr end_Tr start_div end_div start_table end_table escape);

our @EXPORT = qw(
  DebugWeb
  DisplayError
  Footing
  Heading
  MakeButtons
  GetMessageDisplay
  NavigationBar
  DisplayPopup
);

sub ParseEmail(@) {
  my (@header) = @_;

  my %header;

  # First output the header information. Note we'll skip uninteresting stuff
  for (@header) {
    last if ($_ eq '' || $_ eq "\cM");

    # Escape "<" and ">"
    s/\</\&lt\;/;
    s/\>/\&gt\;/;

    if (/^from:\s*(.*)/i) {
      $header{From} = $1;
    } elsif (/^subject:\s*(.*)/i) {
      $header{Subject} = $1;
    } elsif (/^date:\s*(.*)/i) {
      $header{date} = $1;
    } elsif (/^To:\s*(.*)/i) {
      $header{to} = $1;
    } elsif (/^Content-Transfer-Encoding: base64/) {
      $header{base64} = 1;
    }    # if
  }    # for

  return %header;
}    # ParseEmail

sub GetMessageDisplay(%) {
  my (%params) = @_;

  my $userid       = $params{userid};
  my $sender       = $params{sender};
  my $msg_date     = $params{msg_date};
  my $table_name   = $params{table_name}   || 'message';
  my $header_color = $params{header_color} || '#34a853';

  # Find unique message using $date
  my ($err, $msg) = MAPS::FindEmail (
    userid    => $userid,
    sender    => $sender,
    timestamp => $msg_date,
  );

  my $rec = MAPS::GetEmail;

  my $parser = MIME::Parser->new ();

  # For some strange reason MIME::Parser has started having some problems
  # with writing out tmp files...
  $parser->output_to_core (1);
  $parser->tmp_to_core    (1);

  my $entity = $parser->parse_data ($rec->{data});

  my %header = ParseEmail @{($entity->header)[0]};

  my $html = p . "\n";
  $html .= start_table ({
      -align       => "center",
      -id          => $table_name,
      -border      => 0,
      -cellspacing => 0,
      -cellpadding => 0,
      -width       => "100%"
    }
  );
  $html .= start_table ({
      -align       => "center",
      -bgcolor     => $header_color,
      -border      => 0,
      -cellspacing => 1,
      -cellpadding => 0,
      -width       => "100%"
    }
  ) . "\n";
  $html .= "<tbody><tr><td>\n";
  $html .= start_table ({
      -align       => "center",
      -border      => 0,
      -cellspacing => 0,
      -cellpadding => 2,
      -class       => 'msg-table-inner',
      -width       => "100%"
    }
  ) . "\n";

  for (keys (%header)) {
    next if /base64/;

    my $str = '';
    for my $part (decode_mimewords ($header{$_})) {
      my ($text, $charset) = @$part;

      if ($charset) {
        eval {$text = decode ($charset, $text)};
      } else {

        # Try UTF-8 decoding for raw words
        eval {$text = decode ('UTF-8', $text, Encode::FB_CROAK);};
      }
      $str .= $text;
    } ## end for my $part (decode_mimewords...)

    $html .= Tr ([
        th ({
            -align => 'right',
            -class => 'tableheader',
            -width => "8%"
          },
          ucfirst "$_:"
          )
          . "\n"
          . td ({-class => 'tabledata'}, $str)
      ]
    );
  }    # for

  $html .= end_table;
  $html .= "</td></tr>";
  $html .= end_table;

  my $safe_sender = escape ($sender);
  my $safe_date   = escape ($msg_date);

  $html .= qq{<iframe id="msg_frame"
                   src="display.cgi?sender=$safe_sender;msg_date=$safe_date;view=body"
                   width="100%"
                   height="600"
                   frameborder="0"
                   class="iframe-body"
                   sandbox="allow-same-origin">
           </iframe>
<script>
(function() {
    function init() {
        try {
            var iframe = document.getElementById('msg_frame');
            if (!iframe) return;

            function attachListener() {
                try {
                    var doc = iframe.contentDocument || iframe.contentWindow.document;
                    if (!doc || !doc.body) return;

                    if (doc.body.getAttribute('data-listener-attached')) return;
                    
                    doc.addEventListener('click', function(e) {
                        var target = e.target.closest('a');
                        if (target && target.hasAttribute('title') && !target.hasAttribute('href')) {
                             e.preventDefault();
                             e.stopPropagation();
                             var url = target.getAttribute('title');

                             // Calculate absolute position
                             var rect = iframe.getBoundingClientRect();
                             var x = rect.left + e.clientX;
                             var y = rect.top + e.clientY;
                             
                             if (navigator.clipboard) {
                                 navigator.clipboard.writeText(url).then(function() {
                                     showToast('Link copied', false, x, y);
                                 }, function(err) {
                                     fallbackCopy(url, x, y);
                                 });
                             } else {
                                 fallbackCopy(url, x, y);
                             }
                        }
                    }, true); 
                    
                    doc.body.setAttribute('data-listener-attached', 'true');
                } catch(e) {
                    console.error('Cannot access iframe content', e);
                }
            }

            // Attempt immediately
            attachListener();

            // Re-attach on iframe load (navigation)
            iframe.addEventListener('load', function() {
                setTimeout(attachListener, 200);
            });
            
        } catch(e) {
            console.error("Init failed", e);
        }
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        init();
    } else {
        window.addEventListener('load', init);
    }
})();

function fallbackCopy(text, x, y) {
  var textArea = document.createElement("textarea");
  textArea.value = text;
  textArea.style.position = "fixed";
  textArea.style.left = "-9999px";
  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();
  try {
    var successful = document.execCommand('copy');
    if (successful) {
      showToast('Link copied', false, x, y);
    } else {
      showToast('Unable to copy/paste link', true, x, y);
    }
  } catch (err) {
    showToast('Unable to copy link', true, x, y);
  }
  document.body.removeChild(textArea);
}

function showToast(message, isError, x, y) {
  // Styles for the toast
  var style = document.getElementById('toast-style');
  if (!style) {
      style = document.createElement('style');
      style.id = 'toast-style';
      style.innerHTML = `
        #toast {
          visibility: hidden;
          min-width: 150px; /* Smaller width for cursor popup */
          margin-left: 0; 
          background-color: #4CAF50; /* Green Default */
          color: #fff;
          text-align: center;
          border-radius: 4px;
          padding: 8px 12px; /* Smaller padding */
          position: fixed;
          z-index: 1000;
          font-size: 14px; /* Smaller font */
          opacity: 0;
          transition: opacity 0.3s; 
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
          pointer-events: none; /* Click-through */
        }
        #toast.error {
            background-color: #F44336;
        }
        #toast.show {
          visibility: visible;
          opacity: 1;
        }
      `;
      document.head.appendChild(style);
  }

  var toast = document.getElementById("toast");
  if (!toast) {
      toast = document.createElement("div");
      toast.id = "toast";
      document.body.appendChild(toast);
  }
  
  // Reset classes and styles
  toast.className = "";
  toast.style.left = "";
  toast.style.top = "";
  toast.style.bottom = "";
  toast.style.transform = "";

  if (x !== undefined && y !== undefined) {
      // Position at cursor
      // Simple logic: position above and centered to the cursor
      // x is clientX, y is clientY
      toast.style.left = x + 'px';
      toast.style.top = (y - 50) + 'px'; // 50px above cursor
      toast.style.transform = "translateX(-50%)";
  } else {
      // Default center bottom
      toast.style.left = "50%";
      toast.style.bottom = "50px";
      toast.style.transform = "translateX(-50%)";
  }

  if (isError) {
      toast.classList.add("error");
  }
  
  toast.classList.add("show");
  toast.innerText = message;
  
  setTimeout(function(){ 
      toast.classList.remove("show"); 
  }, 2000); // Shorter duration for cursor toast
}
</script>};

  $html .= end_table;

  return $html;
}    # GetMessageDisplay

sub getquickstats(%) {
  my (%params) = @_;

  my %dates = GetStats (
    userid => $params{userid},
    days   => 1,
    date   => $params{date},
  );

  my $date = $params{date};

  for (@Types) {
    $dates{$date}{processed} += $dates{$date}{$_};
  }    # for

  return %dates;
}    # getquickstats

sub displayquickstats($) {
  my ($userid) = @_;

  # Quick stats are today only
  my $today = Today2SQLDatetime;
  my $time  = substr $today, 11;
  my $date  = substr $today, 0, 10;
  my %dates = getquickstats (
    userid => $userid,
    date   => $date
  );

  print start_div {-class => 'quickstats'};
  print h4 {
    -class => 'todaysactivity',
    -align => 'center'
    },
    'Today\'s Activity';

  print p {-align => 'center', -style => 'font-weight: 400 !important;'},
    'as of ' . FormatTime ($time);

  print start_div {-id => 'quickstats'};

  print start_table {
    -cellspacing => 0,
    -border      => 0,
    -align       => 'center',
    -cellpadding => 2,
  };
  print start_Tr {-align => 'right'};
  print td {
    -class => 'smalllabel',
    -align => 'right'
    },
    'Processed';
  print td {
    -class => 'smallnumber',
    -align => 'right'
    },
    $dates{$date}{'processed'};
  print td {
    -class => 'smallnumber',
    -align => 'right'
    },
    'n/a';
  print end_Tr;

  for (@Types) {
    print start_Tr {-align => 'right'};

    my $foo   = $_;
    my $value = $dates{$date}{$_};
    my $percent;

    if ($_ eq 'mailloop' || $_ eq 'registered') {
      $percent = 'n/a';
    } else {
      $percent =
        $dates{$date}{processed} == 0
        ? 0
        : $dates{$date}{$_} / $dates{$date}{processed} * 100;
      $percent = sprintf '%5.1f%s', $percent, '%';
    }    # if

    my $report = ucfirst $_;
    $report =~ s/list$//;

    $report = a {-href => "detail.cgi?type=$_;date=$date"}, $report if $value;

    print td {-class => 'link'},        $report,
      td     {-class => 'smallnumber'}, $value,
      td     {-class => 'smallnumber'}, $percent;

    print end_Tr;
  }    # for

  print end_table;
  print end_div;
  print end_div;

  return;
}    # displayquickstats

sub MakeButtons {
  my (%params) = @_;

  my $script = $params{script};
  my $next   = $params{next};
  my $prev   = $params{prev};
  my $lines  = $params{lines};
  my $total  = $params{total};
  my $type   = $params{type};
  my $extra  = $params{extra} || '';

  my $prev_button =
    $prev >= 0
    ? qq(<a href="$script?$extra;next=$prev" accesskey="p"><img src="/maps/images/previous.gif" border="0" alt="Previous" align="middle"></a>)
    : '';

  my $next_button =
    ($next + $lines) < $total
    ? qq(<a href="$script?$extra;next=)
    . ($next + $lines)
    . qq(" accesskey="n"><img src="/maps/images/next.gif" border="0" alt="Next" align="middle"></a>)
    : '';

  my $buttons = $prev_button;

  my $show_white = (!defined $type || $type ne 'whitelist');
  my $show_black = (!defined $type || $type ne 'blacklist');
  my $show_null  = (!defined $type || $type ne 'nulllist');

  $buttons .=
'<button class="maps-button" type="submit" name="action" value="Whitelist" onClick="return CheckAtLeast1Checked (document.detail);">White</button>&nbsp;'
    if $show_white;
  $buttons .=
'<button class="maps-button" type="submit" name="action" value="Blacklist" onClick="return CheckAtLeast1Checked (document.detail);">Black</button>&nbsp;'
    if $show_black;
  $buttons .=
'<button class="maps-button" type="submit" name="action" value="Nulllist" onClick="return CheckAtLeast1Checked (document.detail);">Null</button>&nbsp;'
    if $show_null;

  $buttons .=
qq(<input class="maps-button" type="submit" name="action" value="Reset" onClick="return ClearAll (document.detail);">);

  return qq(<div align="center" class="toolbar">$buttons$next_button</div>);
}    # MakeButtons

sub Footing(;$) {
  my ($table_name) = @_;

  # General footing (copyright). Note we calculate the current year
  # so that the copyright automatically extends itself.
  my $year = substr ((scalar (localtime)), 20, 4);

  print end_div;    # This div ends "content" which was started in Heading
  print
"<script language='JavaScript1.2'>AdjustTableWidth (\"$table_name\");</script>"
    if $table_name;
  print end_html;

  return;
}    # Footing

sub DebugWeb($) {
  my ($msg) = @_;

  print br, font ({-class => 'error'}, 'DEBUG: '), $msg;

  return;
}    # Debug

sub DisplayPopup($;$) {
  my ($msg, $goback) = @_;

  $msg = escapeHTML ($msg);
  $msg =~ s/\n/<br>/g;

  # Robust back action: Try referrer first, then history
  my $onclick =
    $goback
    ? "if (document.referrer) { window.location.href = document.referrer; } else { history.back(); }"
    : "this.parentNode.parentNode.style.display='none'";

  # Use class-based styles for theming
  print <<EOF;
<div class="modal-overlay">
  <div class="modal-content">
    <p>$msg</p>
    <button class="modal-btn" onclick="$onclick">OK</button>
  </div>
</div>
EOF
  return;
}    # DisplayPopup

sub DisplayError($) {
  my ($errmsg) = @_;

  DisplayPopup ("ERROR: $errmsg", 1);
  print end_html;
  exit 1;
}    # DisplayError

# This subroutine puts out the header for web pages. It is called by
# various cgi scripts thus has a few parameters.
sub Heading($$$$;$$@) {
  my (
    $action,        # One of getcookie, setcookie, unsetcookie
    $userid,        # User id (if setting a cookie)
    $title,         # Title string
    $h1,            # H1 header
    $h2,            # H2 header (optional)
    $table_name,    # Name of table in page, if any
    @scripts
  ) = @_;           # Array of JavaScript scripts to include

  my @java_scripts;
  my $cookie;

  # Since CheckAddress appears on all pages (well except for the login
  # page) include it by default along with MAPSUtils.js
  push @java_scripts, [{
      -language => 'JavaScript1.2',
      -src      => '/maps/JavaScript/MAPSUtils.js'
    }, {
      -language => 'JavaScript1.2',
      -src      => '/maps/JavaScript/CheckAddress.js'
    }
    ];

  # Add on any additional JavaScripts that the caller wants. Note the
  # odd single element array of hashes but that's what CGI requires!
  # Build up scripts from array
  for (@scripts) {
    push @{$java_scripts[0]}, {
      -language => 'JavaScript1.2',
      -src      => "/maps/JavaScript/$_"
      };
  }    # foreach

  # Add embedded mode detection script
  push @{$java_scripts[0]}, {
    -type => 'text/javascript',
    -code => q{
    (function() {
        var isStandalone = (window === window.top);
        if (isStandalone) {
             var currentUrl = window.location.pathname + window.location.search;
             window.location.href = '/?url=' + encodeURIComponent(currentUrl);
        } else {
            document.documentElement.classList.add('embedded');
            document.addEventListener('DOMContentLoaded', function() {
                document.body.classList.add('embedded');
            });
        }
    })();
      }
  };

  # Since Heading is called from various scripts we sometimes need to
  # set a cookie, other times delete a cookie but most times return the
  # cookie.
  if ($action eq 'getcookie') {

    # Get userid from cookie
    $userid = cookie ('MAPSUser');

    if ($userid) {
      $cookie = cookie (
        -name    => 'MAPSUser',
        -value   => $userid,
        -expires => '+30d',
        -path    => '/maps'
      );
    }    # if
  } elsif ($action eq 'setcookie') {
    $cookie = cookie (
      -name    => 'MAPSUser',
      -value   => $userid,
      -expires => '+1y',
      -path    => '/maps'
    );
  } elsif ($action eq 'unsetcookie') {
    $cookie = cookie (
      -name    => 'MAPSUser',
      -value   => '',
      -expires => '-1d',
      -path    => '/maps'
    );
  }    # if

  print header(
    -charset       => 'utf-8',
    -title         => $title,
    -cookie        => $cookie,
    -cache_control => 'no-cache, no-store, must-revalidate',
    -pragma        => 'no-cache',
    -expires       => '0',
  );

  if ($table_name) {
    print start_html(
      -title    => $title,
      -author   => 'Andrew\@DeFaria.com',
      -style    => {-src     => '/maps/css/MAPSStyle.css?v=' . time ()},
      -meta     => {viewport => 'width=device-width, initial-scale=1'},
      -onResize => "AdjustTableWidth (\"$table_name\");",
      -head     => [
        Link ({
            -rel  => 'icon',
            -href => '/maps/MAPS.png',
            -type => 'image/png'
          }
        ),
        Link ({
            -rel  => 'preconnect',
            -href => 'https://fonts.googleapis.com'
          }
        ),
        Link ({
            -rel         => 'preconnect',
            -href        => 'https://fonts.gstatic.com',
            -crossorigin => 'anonymous'
          }
        ),
        Link ({
            -rel  => 'stylesheet',
            -href =>
'https://fonts.googleapis.com/css2?family=Dancing+Script:wght@400;700&family=Inter:wght@400;500;600;700&family=Outfit:wght@500;700&display=swap'
          }
        ),
        Link ({
            -rel  => 'stylesheet',
            -href => '/css/style.css?v=' . time ()
          }
        ),
        Link ({
            -rel  => 'shortcut icon',
            -href => '/maps/favicon.ico'
          }
        )
      ],
      -script => @java_scripts
    );
  } else {
    print start_html(
      -title  => $title,
      -author => 'Andrew\@DeFaria.com',
      -style  => {-src     => '/maps/css/MAPSStyle.css?v=' . time ()},
      -meta   => {viewport => 'width=device-width, initial-scale=1'},
      -head   => [
        Link ({
            -rel  => 'icon',
            -href => '/maps/MAPS.png',
            -type => 'image/png'
          }
        ),
        Link ({
            -rel  => 'preconnect',
            -href => 'https://fonts.googleapis.com'
          }
        ),
        Link ({
            -rel         => 'preconnect',
            -href        => 'https://fonts.gstatic.com',
            -crossorigin => 'anonymous'
          }
        ),
        Link ({
            -rel  => 'stylesheet',
            -href =>
'https://fonts.googleapis.com/css2?family=Dancing+Script:wght@400;700&family=Inter:wght@400;500;600;700&family=Outfit:wght@500;700&display=swap'
          }
        ),
        Link ({
            -rel  => 'stylesheet',
            -href => '/css/style.css?v=' . time ()
          }
        ),
        Link ({
            -rel  => 'shortcut icon',
            -href => '/maps/favicon.ico'
          }
        )
      ],
      -script => @java_scripts
    );
  }    # if

  print start_div {class => 'heading'};
  print h2 {
    -align => 'center',
    -class => 'header'
    },
    escapeHTML ($h1);

  if (defined $h2 && $h2 ne '') {
    print h3 {
      -align => 'center',
      -class => 'header'
      },
      escapeHTML ($h2);
  }    # if
  print end_div;

  # Start body content
  print start_div {-class => 'content'};

  return $userid;
}    # Heading

sub NavigationBar($) {
  my ($userid) = @_;

  print start_div {-id => 'leftbar'};

  unless ($userid) {
    print h2({-align => 'center'}, "MAPS $MAPS::VERSION");
    print div ({-class => 'username'}, 'Welcome to MAPS');
    print div (
      {-class => 'menu'},
      (a {-href => '/maps/doc/'},                  'What is MAPS?<br>'),
      (a {-href => '/maps/doc/SPAM.html'},         'What is SPAM?<br>'),
      (a {-href => '/maps/doc/Requirements.html'}, 'Requirements<br>'),
      (a {-href => '/maps/SignupForm.html'},       'Signup<br>'),
      (a {-href => '/maps/doc/Using.html'},        'Using MAPS<br>'),
      (a {-href => '/maps/doc/'},                  'Help<br>'),
    );
  } else {
    print h2({-align => 'center'}, "MAPS $MAPS::VERSION");
    print div ({-class => 'username'}, 'Welcome ' . ucfirst $userid);

    print div (
      {-class => 'menu'},
      (a {-href => '/maps/'},                    'Home<br>'),
      (a {-href => '/maps/bin/stats.cgi'},       'Statistics<br>'),
      (a {-href => '/maps/bin/editprofile.cgi'}, 'Profile<br>'),
      (
        a {-href => 'https://earth.defariahome.com/maps/php/ListDomains.php'},
        'Top 20<br>'
      ),
      (a {-href => '/maps/php/list.php?type=white'}, 'White<br>'),
      (a {-href => '/maps/php/list.php?type=black'}, 'Black<br>'),
      (a {-href => '/maps/php/list.php?type=null'},  'Null<br>'),
      (a {-href => '/maps/doc/'},                    'Help<br>'),

      (a {-href => '/maps/?logout=yes'}, 'Logout'),
    );

    displayquickstats ($userid);
    print br;

    print start_div {-class => 'search'};
    print start_form {
      -method => 'get',
      -action => '/maps/bin/search.cgi',
      -name   => 'search'
    };
    print textfield {
      -class       => 'searchfield',
      -id          => 'searchfield',
      -name        => 'str',
      -size        => 20,
      -maxlength   => 255,
      -value       => '',
      -placeholder => 'Search Sender/Subject',
      -onclick     => "document.search.str.value = '';"
    };
    print end_form;
    print end_div;

  }    # if

  print end_div;

  return;
}    # NavigationBar

1;
