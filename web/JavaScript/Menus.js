function imenus_data0 () {
  this.menu_showhide_delay		= 150;
  this.show_subs_onclick		= false;
  this.hide_focus_box			= false;

  // Box Animation Settings
  this.box_animation_type		= "center";
  this.box_animation_frames		= 15;
  this.box_animation_styles		= "border-style:solid; border-color:#999999; border-width:1px;";

  // Animated Pointer Icon Settings
  this.main_pointer_image		= "/Icons/arrow_down.gif";
  this.main_pointer_image_width		= "10";
  this.main_pointer_image_height	= "11";
  this.main_pointer_image_offx		= "-3";
  this.main_pointer_image_offy		= "-14";

  this.sub_pointer_image		= "/Icons/arrow_right.gif";
  this.sub_pointer_image_width		= "13";
  this.sub_pointer_image_height		= "10";
  this.sub_pointer_image_offx		= "-13";
  this.sub_pointer_image_offy		= "-5";

  // IE Transition Effects
  this.subs_ie_transition_show		= "";
} // imenus_data0

ulm_last_pointer = null;

function imenus_add_pointer_image (obj,dto,level) {
  if (ulm_oldnav || (ulm_mac && (ulm_ie||ulm_navigator))) {
    return;
  } // if

  x4 = "main";
 
  if (level > 0) {
    x4 = "sub";
  } // if

  var c_horizontal = true;

  if (level == 0) {
    if ((ob1 = obj.getElementsByTagName ("LI") [0]) &&
        (ob1.style.width.indexOf ("100%") + 1)) {
      c_horizontal=false;
     } // if
  } // if

  var a		= obj.parentNode.getElementsByTagName ("UL") [0];
  var id	= a.id.substring (a.id.indexOf ("_") + 1);

  x3			= document.createElement ("DIV");
  x3.id			= "pi" + a.id;
  x3.style.position	= "absolute";
  x3.style.visibility	= "hidden";
  x3.style.fontSize	= "0px";
  x3.style.lineHeight	= "0px";
  x3.style.zIndex	= 999;

  x3.setAttribute ("ispointer", 1);
  x3.setAttribute ("scxy", "0,0");
  x3.setAttribute ("offxy", "0,0");

  if ((level == 0) && (c_horizontal)) {
    x3.setAttribute ("ish", 1);
    x3.setAttribute ("fxoff", x25 (dto.main_pointer_image_offy));
    x3.setAttribute ("sloff", x25 (dto.main_pointer_image_offx));
  } else {
    x3.setAttribute ("fxoff", x25 (x27_pointer (x4 + "_pointer_image_offx", dto, id)));
    x3.setAttribute ("sloff", x25 (x27_pointer (x4 + "_pointer_image_offy", dto, id)));
  } // if
  
  wht = "";

  if ((tval = x27_pointer (x4 + "_pointer_image_width", dto, id))) {
    wht += "width='" + tval + "'";
  } // if

  if ((tval = x27_pointer (x4 + "_pointer_image_height", dto, id))) {
    wht += "height='" + tval + "'";
  } // if

  x5 = x27_pointer (x4 + "_pointer_image", dto, id);

  if (!x5 || x5.toLowerCase () == "none") {
    obj.setAttribute ("noimage", 1);
  } else {
    obj.removeAttribute ("noimage");
  } // if

  var dexist	= false;
  var dobj	= obj.childNodes;

  for (var d=0; d<dobj.length; d++) {
    if (dobj [d].getAttribute && dobj [d].getAttribute ("ispointer")) {
      dexist=true;
    } // if
  } // for
  
  if (!dexist) {
    x3.innerHTML = '<img src="' + x5 + '" ' + wht + '>';
    obj.appendChild (x3);
  } // if
  
  obj.onmousemove = function (e) {
    e = e || window.event;

    var x32 = this;

    if (this.tagName == "DIV") {
      x32 = this.getElementsByTagName ("UL") [0];
    } // if

    if ((x32.className.indexOf ("imncc") + 1)			||
	(x32.parentNode.className.indexOf ("imncc") + 1)	||
	this.getAttribute("noimage")) {
      imenus_hide_pointer();

      if (!x32.id || x32.id.indexOf ("imenus") == -1) {
	im_kille (e);
      } // if

      return false;

    } // if
    
    var lc = this.lastChild;
    var bid;

    if (!lc.getAttribute ("ispointer")) {
      bid = this.getElementsByTagName ("UL") [0].id;
      lc  = document.getElementById ("pi"+bid);
    } // if

    if (!lc.getAttribute ("initialized")) {
      imenus_initialize_pointer (this,lc);
    } // if

    offxy	= eval ("new Array(" + lc.getAttribute ("offxy") + ")");
    sloff	= parseInt (lc.getAttribute ("sloff"));
    scxy	= eval ("new Array(" + lc.getAttribute ("scxy") + ")");

    if (lc.getAttribute ("ish")) {
      npos = e.clientX - offxy [0] + sloff + scxy [0];

      if (window.dp_zoomc) {
	npos=dp_zoomc(npos);
      } // if

      setTimeout ("imenus_pointer_move('" + lc.id + "'," + npos + ",'h')", 0);
    } else {
      npos = e.clientY - offxy [1] + sloff + scxy [1];

      if (window.dp_zoomc) {
	npos=dp_zoomc(npos);
      } // if

      setTimeout ("imenus_pointer_move('" + lc.id + "'," + npos + ")", 0);
    } // if

    var a;

    if (a = window.imenus_event_mc_onmousemove) {
      a ();
    } // if

    im_kille (e);

    return false;
  };
} // imenus_add_pointer_image

function imenus_pointer_move (id,npos,type) {
  var md = document.getElementById (id);

  if(type == "h") {
    md.style.left = npos + "px";
  } else {
    md.style.top = npos + "px";
  } // if

  if (md.getAttribute ("initialized")) {
    md.style.visibility = "inherit";
  } // if
} // imenus_pointer_move

function x25 (val) {
  if (val == null) {
    return 0;
  } else {
    return val;
  } // if
} // x26

function imenus_hide_pointer (check) {
  if (ulm_last_pointer && ulm_last_pointer.parentNode != check) {
    ulm_last_pointer.style.visibility = "hidden";
    ulm_last_pointer.removeAttribute("initialized");
  } // if
} imenus_hide_pointer

function imenus_initialize_pointer (obj, lc) {
  imenus_hide_pointer ();

  ulm_last_pointer = lc;

  var txy = x26 (obj);

  if (hpi = document.getElementById ("hpi_pad")) {
    if (a = hpi.scrollLeft) {
      txy [0] -= a;
    } // if

    if (a = hpi.scrollTop) {
      txy [1] -=a;
    } // if
  } // if

  lc.setAttribute ("offxy", txy);

  var pxy = parseInt (lc.getAttribute ("fxoff"));

  if (lc.getAttribute ("ish")) {
    lc.style.top = pxy + "px";
  } else {
    lc.style.left = pxy + "px";
  } // if

  pobj = document.body;

  if ((!(pobj.scrollLeft+pobj.scrollTop)) &&
      (document.documentElement)) {
    pobj=document.documentElement;
  } // if

  lc.setAttribute ("scxy", pobj.scrollLeft + "," + pobj.scrollTop);
  lc.setAttribute ("initialized", 1);
} // imenus_initialize_pointer

function x27_pointer (pname, dto, index) {
  if ((rval = dto [pname + index]) != null) {
    return rval;
  } else {
    return dto [pname];
  } // if
} // x27_pointer

function imenus_box_ani_init (obj, dto) {
  var tid = obj.getElementsByTagName ("UL") [0].id.substring (6);

  if (!(ulm_navigator && ulm_mac)			&&
      !(window.opera && ulm_mac)			&&
      !(window.navigator.userAgent.indexOf("afari")+1)	&&
      !ulm_iemac&&dto.box_animation_frames > 0		&&
      !dto.box_animation_disabled) {
    ulm_boxa ["go" + tid]	= true;
    ulm_boxa.go			= true;
    ulm_boxa.all		= new Object ();
  }else {
    return;
  } // if
} // imenus_box_ani_init

function imenus_box_ani (show, tul, hobj, e) {
  if (tul.className.indexOf ("imcanvassubc") + 1) {
    hover_handle (hobj);
    return;
  } //

  if (!ulm_boxa.cm) {
    ulm_boxa.cm = new Object ();
  } // if

  if (!ulm_boxa ["ba" + hobj.id]) {
    ulm_boxa ["ba" + hobj.id] = new Object ();
  } // if

  ulm_boxa ["ba" + hobj.id].hobj = hobj;

  var bo = ulm_boxa ["ba" + hobj.id];

  bo.id = "ba" + hobj.id;

  if (!bo.bdiv) {
    bdiv		= document.createElement ("DIV");
    bdiv.className	= "ulmba";
    bdiv.onmousemove	= function (e) {
      if (!e) {
	e=event;
      } // if

      e.cancelBubble	= true;
    };
    bdiv.onmouseover	= function (e) {
      if (!e) {
	e = event;
      } // if
      e.cancelBubble	= true;
    };
    bdiv.onmouseout	= function (e) {
      if (!e) {
	e=event;
      } // if

      e.cancelBubble	= true;
    };
    bo.bdiv = tul.parentNode.appendChild (bdiv);
  } // if

  var i;

  for (i in ulm_boxa) {
    if ((ulm_boxa [i].steps) && !(ulm_boxa [i].id.indexOf (hobj.id) + 1)) {
      ulm_boxa [i].reverse = true;
    } // if
  } // for

  if (((hobj.className.indexOf ("ishow") + 1) && bo.hobj) ||
      (bo.bdiv.style.visibility == "visible" && !bo.reverse)) {
    return true;
  } // if

  imenus_box_show (bo, hobj, tul, e);
} // imenus_box_ani

function imenus_box_h (hobj) {
  if (hobj.className.indexOf ("imctitleli") + 1) {
    return;
  } // if

  var bo = ulm_boxa ["ba" + hobj.id];

  if (bo && bo.bdiv && bo.pos) {
    bo.reverse			= true;
    bo.pos			= bo.steps;
    bo.bdiv.style.visibility	= "visible";
    imenus_box_x44 (bo);
  } // if
} // imenus_box_x44

function imenus_box_reverse (x17) {
  if (!ulm_boxa.go) {
    return;
  } // if

  var i;

  for (i in ulm_boxa.all) {
    if (ulm_boxa.all [i] && ulm_boxa [i].hobj != x17) {
      var bo = ulm_boxa [i];

      bo.reverse	= true;
      ulm_boxa.all [i]	= null;
    } // if
  } // for
} // imenus_box_reverse

function imenus_box_show (bo, hobj, tul, e) {
  var type;
  var tdto = ulm_boxa ["dto" + parseInt (hobj.id.substring (6))];

  clearTimeout (bo.st);

  bo.st = null;

  if (bo.bdiv) {
    bo.bdiv.style.visibility = "hidden";
  } // if

  bo.pos	= 0;
  bo.reverse	= false;
  bo.steps	= tdto.box_animation_frames;
  bo.exy	= new Array (tul.offsetLeft, tul.offsetTop);
  bo.ewh	= new Array (tul.offsetWidth, tul.offsetHeight);
  bo.sxy	= new Array (0, 0);

  if (!(type = tul.getAttribute ("boxatype"))) {
    type = tdto.box_animation_type;
  } // if

  if (type == "center") {
    bo.sxy = new Array (bo.exy [0] + parseInt (bo.ewh [0] / 2), 
			bo.exy [1] + parseInt (bo.ewh [1] / 2));
  } else if (type == "top") {
    bo.sxy = new Array (parseInt (bo.ewh [0] / 2), 0);
  } else if (type == "left") {
    bo.sxy = new Array (0, parseInt (bo.ewh [1] / 2));
  } else if (type=="pointer") {
    if (!e) {
      e = window.event;
    } // if

    var txy = x26 (tul);

    bo.sxy = new Array (e.clientX - txy [0], (e.clientY - txy [1]) + 5);
  } // if

  bo.dxy	= new Array (bo.exy [0] - bo.sxy [0], bo.exy [1] - bo.sxy [1]);
  bo.dwh	= new Array (bo.ewh [0], bo.ewh [1]);
  bo.tul	= tul;
  bo.hobj	= hobj;

  imenus_box_x44(bo);
} // imenus_box_show

function imenus_box_x44 (bo) {
  var a		= bo.bdiv;
  var cx	= bo.sxy [0] + parseInt ((bo.dxy [0] / bo.steps) * bo.pos);
  var cy	= bo.sxy [1] + parseInt ((bo.dxy [1] / bo.steps) * bo.pos);

  a.style.left	= cx + "px";
  a.style.top	= cy + "px";

  var cw	= parseInt ((bo.dwh [0] / bo.steps) * bo.pos);
  var ch	= parseInt ((bo.dwh [1] / bo.steps) * bo.pos);

  a.style.width		= cw + "px";
  a.style.height	= ch + "px";

  if (bo.pos <= bo.steps) {
    if (bo.pos == 0) {
      a.style.visibility="visible";
    } // if

    if (bo.reverse == true) {
      bo.pos--;
    } else {
      bo.pos++;
    } // if

    if (bo.pos == -1) {
      bo.pos			= 0;
      a.style.visibility	= "hidden";
    } else {
      bo.st = setTimeout ("imenus_box_x44(ulm_boxa['" + bo.id + "'])", 8);
      ulm_boxa.all[bo.id]=true;
    } // if
  } else {
    clearTimeout (bo.st);

    bo.st			= null;
    ulm_boxa.all [bo.id]	= null;

    if (!bo.reverse) {
      if ((bo.hobj) && (bo.pos > -1)) {
	hover_handle (bo.hobj);
      } // if
    }

    a.style.visibility = "hidden";
  } // if
} // imenus_box_x44

function iao_iframefix () {
  if (ulm_ie && !ulm_mac && !ulm_oldie && !ulm_ie7) {
    for (var i = 0;i < (x31 = uld.getElementsByTagName ("iframe")).length; i++) {
      if ((a = x31 [i]).getAttribute ("x30")) {
	a.style.height	= (x32 = a.parentNode.getElementsByTagName ("UL") [0]).offsetHeight;
	a.style.width	= x32.offsetWidth;
      } // if
    } // for
  } // if
} // iao_iframefix

function iao_ifix_add (b) {
  if (ulm_ie				&&
      !ulm_mac				&&
      !ulm_oldie			&&
      !ulm_ie7				&&
      window.name != "hta"		&&
      window.name != "imopenmenu") {
    b.parentNode.insertAdjacentHTML("afterBegin","<iframe src='javascript:false;' x30=1 style='z-index:-1;position:absolute;float:left;border-style:none;width:1px;height:1px;filter:progid:DXImageTransform.Microsoft.Alpha(Opacity=0);' frameborder='0'></iframe><div></div>");
  } // if
} // iao_ifix_add

// ---- IM Code + Security [7.5 KB] ----
im_version		= "10.x";
ht_obj			= new Object ();
cm_obj			= new Object ();
uld			= document;
ule			= "position:absolute;";
ulf			= "visibility:visible;";
ulm_boxa		= new Object ();

var ulm_d;

ulm_mglobal		= new Object ();
ulm_rss			= new Object();
nua			= navigator.userAgent;
ulm_ie			= window.showHelp;
ulm_ie7			= nua.indexOf ("MSIE 7")		+ 1;
ulm_mac			= nua.indexOf ("Mac")			+ 1;
ulm_navigator		= nua.indexOf ("Netscape")		+ 1;
ulm_version		= parseFloat (navigator.vendorSub);
ulm_oldnav		= ulm_navigator && ulm_version < 7.1;
ulm_oldie		= ulm_ie && nua.indexOf("MSIE 5.0")	+ 1;
ulm_iemac		= ulm_ie && ulm_mac;
ulm_opera		= nua.indexOf ("Opera")			+ 1;
ulm_safari		= nua.indexOf ("afari")			+ 1;
x42			= "_";
ulm_curs		= "cursor:hand;";

if (!ulm_ie) {
  x42		= "z";
  ulm_curs	= "cursor:pointer;";
} // if

ulmpi			= window.imenus_add_pointer_image;

var x43;

for (mi = 0; mi < (x1 = uld.getElementsByTagName ("UL")).length; mi++) {
  if ((x2 = x1 [mi].id) && x2.indexOf ("imenus") + 1) {
    dto = new window ["imenus_data" + (x2 = x2.substring (6))];
    ulm_boxa.dto=dto;
    ulm_boxa["dto"+x2]=dto;
    ulm_d=dto.menu_showhide_delay;

    if (ulm_ie && !ulm_ie7 && !ulm_mac && (b = window.imenus_efix)) {
      b (x2);
    } // if

    imenus_create_menu (x1 [mi].childNodes, x2 + x42, dto, x2);
    (ap1 = x1 [mi].parentNode).id = "imouter" + x2;
    ulm_mglobal ["imde" + x2] = ap1;

    var dt = "onmouseover";

    if (ulm_mglobal.activate_onclick) {
      dt = "onclick";
    } // if

    document [dt] = function () {
      var a;

      if (!ht_obj.doc) {
	clearTimeout (ht_obj.doc);

	ht_obj.doc = null;
      } else {
	return;
      } // if

      ht_obj.doc = setTimeout ("im_hide()", ulm_d);

      if (a = window.imenus_box_reverse) {
	a ();
      } // if

      if (a = window.imenus_expandani_hideall) {
	a ();
      } // if

      if (a = window.imenus_hide_pointer) {
	a ();
      } // if

      if (a = window.imenus_shift_hide_all) {
	a ();
      } // if
    };

    imarc ("imde", ap1);

    if (ulm_oldnav) {
      ap1.parentNode.style.position="static";
    } // if

    if (!ulm_oldnav&&ulmpi) {
      ulmpi (x1 [mi], dto, 0, x2);
    } // if

    x6 (x2, dto);

    if ((ulm_ie && !ulm_iemac) && (b1 = window.iao_iframefix)) {
      window.attachEvent ("onload", b1);
    } // if

    if (b1 = window.imenus_box_ani_init) {
      b1 (ap1, dto);
    } // if

    if (b1 = window.imenus_expandani_init) {
      b1 (ap1, dto);
    } // if

    if (b1 = window.imenus_info_addmsg) {
      b1 (x2, dto);
    } // if

    if (b1 = window.im_conexp_init) {
      b1 (dto, ap1, x2);
    } // if
  } // if
} // for

function imenus_create_menu (nodes, prefix, dto, d_toid, sid, level) {
  var counter = 0;

  if (sid) {
    counter=sid;
  } // sid

  for (var li = 0; li < nodes.length; li++) {
    var a = nodes [li];
    var c;

    if (a.tagName == "LI") {
      a.id = "ulitem" + prefix + counter;

      (this.atag = a.getElementsByTagName ("A") [0]).id = "ulaitem" + prefix + counter;

      if (c = this.atag.getAttribute ("himg")) {
	ulm_mglobal ["timg" + a.id]	= new Image ();
	ulm_mglobal ["timg" + a.id].src	= c;
      } // if

      var level;

      a.level	= (level = prefix.split (x42).length - 1);
      a.dto	= d_toid;
      a.x4	= prefix;
      a.sid	= counter;

      if ((a1 = window.imenus_drag_evts) && level > 1) {
	a1 (a, dto);
      } // if

      a.onkeydown = function (e) {
	e = e || window.event;
	
	if (e.keyCode == 13 && !ulm_boxa.go) {
	  hover_handle (this,1);
	} // if
      };

      if (dto.hide_focus_box) {
	this.atag.onfocus = function () {
	  this.blur ()
	};
      } // if

      imenus_se (a,dto);

      this.isb	= false;
      x29	=a .getElementsByTagName ("UL");

      for (ti = 0; ti < x29.length; ti++) {
	var b = x29 [ti];

	if (c = window.iao_ifix_add) {
	  c (b);
	} // if

	var wgc;

	if (wgc = window.getComputedStyle) {
	  if (wgc (b.parentNode, "").getPropertyValue ("visibility") == "visible") {
	    cm_obj [a.id] = a;

	    imarc ("ishow", a, 1);
	  } // if
	} else if (ulm_ie && b.parentNode.currentStyle.visibility == "visible") {
	  cm_obj [a.id] = a;

	  imarc ("ishow", a, 1);
	} // if

	if ((dd = this.atag.firstChild)		&&
	    (dd.tagName == "SPAN")		&&
	    (dd.className.indexOf ("imea") + 1)) {
	  this.isb=true;

	  if (ulm_mglobal.eimg_fix) {
	    imenus_efix_add (level,dd);
	  } // if

	  dd.className		= dd.className + "j";
	  dd.firstChild.id	= "ea" + a.id;

	  dd.setAttribute ("imexpandarrow", 1);
	} // if

	b.id = "x1ub" + prefix + counter;

	if (!ulm_oldnav && ulmpi) {
	  ulmpi (b.parentNode, dto, level);
	} // if

	new imenus_create_menu (b.childNodes, prefix + counter + x42, dto, d_toid);
      } // for

      if ((a1 = window.imenus_button_add) && level == 1) {
	a1 (this.atag, dto);
      } // if

      if (this.isb && ulm_ie && level == 1 && document.getElementById ("ssimaw")) {
	if (a1 = window.imenus_autowidth) {
	  a1(this.atag,counter);
	} // if
      } // if

      if (!sid					&&
	  !ulm_navigator			&&
	  !ulm_iemac				&&
	  (rssurl = a.getAttribute ("rssfeed")) &&
	  (c=window.imenus_get_rss_data)) {
	c (a,rssurl);
      } // if

      counter++;
    } // if
  } // for
} //imenus_create_menu

function imenus_se (a, dto) {
  var d;

  if (!(d = window.imenus_onclick_events) ||
      !d (a, dto)) {
    a.onmouseover = function (e) {
      var a, b, at;

      clearTimeout (ht_obj.doc);

      ht_obj.doc = null;

      if (((at = this.getElementsByTagName ("A") [0]).className.indexOf ("iactive") == -1) &&
	  at.className.indexOf ("imsubtitle") == -1) {
	imarc ("ihover", at, 1);
      } // if

      if (b = at.getAttribute ("himg")) {
	if (!at.getAttribute ("zhimg")) {
	  at.setAttribute ("zhimg", at.style.backgroundImage);
	} // if

	at.style.backgroundImage = "url(" + b + ")";
      } // if

      if (b = window.imenus_shift) {
	b (at);
      } // if

      if (b = window.imenus_expandani_animateit) {
	b (this);
      } // if

      if ((ulm_boxa ["go" + parseInt (this.id.substring  (6))]) &&
	  (a = this.getElementsByTagName ("UL") [0])) {
	imenus_box_ani (true, a, this, e);
      } else {
	if (this.className.indexOf ("ishow") == -1) {
	  ht_obj [this.level] = setTimeout ("hover_handle(uld.getElementById('" + this.id + "'))", ulm_d);
	} // if

	if (a = window.imenus_box_reverse) {
	  a (this);
	} // if
      } // if

      if (a = window.im_conexp_show) {
	a(this);
      } // if

      if (!window.imenus_chover) {
	im_kille (e);
	return false;
      } // if
    };

    a.onmouseout = function (e) {
      var a, b;

      if((a = this.getElementsByTagName ("A") [0]).className.indexOf ("iactive") == -1) {
	imarc ("ihover", a);
	imarc ("iactive", a);
      } // if

      if (this.className.indexOf ("ishow") == -1 && (b = a.getAttribute ("zhimg"))) {
	a.style.backgroundImage = b;
      } // if

      clearTimeout (ht_obj [this.level]);

      if (!window.imenus_chover) {
	im_kille (e);
	return false;
      } // if
    };
  } //
} // imenus_se

function im_hide (hobj) {
  for (i in cm_obj) {
    var tco = cm_obj [i];
    var b;
    
    if (tco) { 
      if (hobj && hobj.id.indexOf (tco.id) + 1) {
	continue;
      } // if

      imarc ("ishow", tco);

      var at = tco.getElementsByTagName ("A") [0];

      imarc ("ihover", at);
      imarc ("iactive", at);

      if (b = at.getAttribute ("zhimg")) {
	at.style.backgroundImage = b;
      } // if

      cm_obj [i] = null;
      i++;

      if (ulm_boxa ["go" + parseInt (tco.id.substring (6))]) {
	imenus_box_h (tco);
      } // if

      var a;

      if (a = window.imenus_expandani_hideit) {
	a (tco);
      } // if

      if (a = window.imenus_shift_hide) {
	a (at);
      } // if
    } // if
  } // for
} // im_hide

function hover_handle (hobj) {
  im_hide (hobj);

  var tul;

  if (tul = hobj.getElementsByTagName ("UL") [0]) {
    try {
      if ((ulm_ie && !ulm_mac)		&&
	  (plobj = tul.filters [0])	&&
	  tul.parentNode.currentStyle.visibility=="hidden") {
	if (x43) {
	  x43.stop ();
	} // if

	plobj.apply ();
	plobj.play ();

	x43 = plobj;
      } // if
    } catch (e) {
    }

    var a;

    if(a = window.imenus_stack_init) {
      a (tul);
    } // if

    if (a = window.iao_apos) {
      a (tul);
    } // if

    var at = hobj.getElementsByTagName ("A") [0];

    imarc ("ihover",    at, 1);
    imarc ("iactive",   at, 1);
    imarc ("ishow",   hobj, 1);

    cm_obj [hobj.id] = hobj;

    if (a = window.imenus_stack_ani) {
      a (tul);
    } // if
  } // if
} // hover_handle

function imarc (name, obj, add) { 
  if (add) {
    if (obj.className.indexOf (name) == -1) {
      obj.className += (obj.className ? ' ' : '') + name;
    } // if
  } else {
    obj.className = obj.className.replace (" " + name, "");
    obj.className = obj.className.replace (name, "");
  } // if
} // imarc

function x26 (obj) {
  var x = 0;
  var y = 0;

  do {
    x += obj.offsetLeft;
    y += obj.offsetTop;
  } while (obj = obj.offsetParent) {
    return new Array (x,y);
  } // while
} // x26

function im_kille (e) {
  if (!e) {
    e=event;
  } // if

  e.cancelBubble = true;

  if (e.stopPropagation) {
    e.stopPropagation ();
  } // if
} // im_kille

function x6 (id,dto) {
  x18	= "#imenus" + id;
  sd	= "<style type='text/css'>";
  ubt	= "";
  lbt	= "";
  x22	= "";
  x23	= "";

  for (hi = 1; hi < 6; hi++) {
    ubt += "li ";
    lbt += " li";
    x22 += x18 + " li.ishow " + ubt + " .imsubc";
    x23 += x18 + lbt + ".ishow .imsubc";

    if (hi != 5) {
      x22 += ",";
      x23 += ",";
    } // if
  } // for

  sd += x22 + "{visibility:hidden;}";
  sd += x23 + "{" + ulf + "}";
  sd += x18 + " li ul{" + ((!window.imenus_drag_evts && window.name != "hta" && ulm_ie) ?
			   dto.subs_ie_transition_show : "") + "}";

  if (ulm_oldnav) {
    sd += ".imcm .imsc{position:absolute;}";
  } // if

  if (ulm_ie && !((dcm = document.compatMode) && dcm == "CSS1Compat")) {
    sd+=".imgl .imbrc{height:1px;}";
  } // if

  if (a1 = window.imenus_drag_styles) {
    sd += a1 (id, dto);
  } // if

  if (a1 = window.imenus_info_styles) {
    sd += a1 (id, dto);
  } // if

  if (ulm_mglobal.eimg_fix) {
    sd += imenus_efix_styles (x18);
  } // if

  sd += "</style>";
  sd += "<style id='extimenus"+id+"' type='text/css'>";sd+=x18+" .ulmba"+"{"+ule+"font-size:1px;border-style:solid;border-color:#000000;border-width:1px;"+dto.box_animation_styles+"}";
  sd += "</style>";

  uld.write (sd);
} // x6

