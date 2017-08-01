var wnd_width=0, wnd_height=0, wnd_detect_bad=false;
function getResolution(){
 try{
   if(typeof(window.innerWidth) == 'number') {wnd_width = window.innerWidth; wnd_height = window.innerHeight;} 
    else if(document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight)) {
        wnd_width = document.documentElement.clientWidth; wnd_height = document.documentElement.clientHeight;
    } 
    else if(document.body && (document.body.clientWidth || document.body.clientHeight)) {
        wnd_width = document.body.clientWidth; wnd_height = document.body.clientHeight;
    }
 } catch (e) {};
 if(wnd_width==0 || wnd_height==0){wnd_width=800; wnd_height=600; wnd_detect_bad=true;}
}

function set_footer(){
  var pp = $("footer").position(); tt=$("footer").height();
  if($.isNumeric(pp.top) && $.isNumeric(tt)){ pp=Math.round(pp.top)+Math.round(tt);
	if(typeof(window.innerHeight) == 'number'){height=window.innerHeight;} 
    else if(document.documentElement && document.documentElement.clientHeight){height=document.documentElement.clientHeight;} 
    else if(document.body && document.body.clientHeight){height=document.body.clientHeight;} else height=0;
	if(height>0 && pp<height){pp=height-pp; $("footer").css("margin-top",pp);}
  }
}

$(document).ready(function() {
  getResolution();
  set_footer();
  $("header .logo").click(function(){document.location.href="/";});
  if(!window['isMobile']()){
	$(window).scroll(function(){
		getResolution();
		if(wnd_detect_bad !== true){
			if(wnd_width >= 800){
				pmenu = $("header .menu-large:first");
				pbody = $("body:first")
				if(typeof window['fixed_menu_top'] === "undefined"){window['fixed_menu_top'] = pmenu.offset().top; window['fixed_menu_height'] = pmenu.height();}
				else{
					if($(this).scrollTop() >= window['fixed_menu_top']){
						if(!pmenu.hasClass('menu-fixed-top')){pbody.css('padding-top', window['fixed_menu_height']); pmenu.css('top', 0); pmenu.addClass('menu-fixed-top');}
					}
					else {
						if(pmenu.hasClass('menu-fixed-top')){pbody.css('padding-top', ''); pmenu.removeClass('menu-fixed-top'); pmenu.css('top', '');}
					}
				}
			}
		}
		//if($(this).scrollTop()=="0"){$(scrollBtn).fadeOut("slow");}
		//else{$(scrollBtn).fadeIn("slow");}
	});
  }
});