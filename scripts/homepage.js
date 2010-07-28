// JavaScript Document
$(document).ready(function(){
	var cascaderGui = {
		divid: '#cascader-gui',
		textid: '#textcascader-gui',
		state: 0,
	};
	var inthelabs = {
		divid: '#inthelabs',
		textid: '#textinthelabs',
		state: 0,
	};
	var massprint = {
		divid: '#massprint',
		textid: '#textmassprint',
		state: 0,
	};
	var mailer = {
		divid: '#mailer',
		textid: '#textmailer',
		state: 0,
	};
	var ubuntuBg = {
		divid: '#ubuntu-bg',
		textid: '#textubuntu-bg',
		state: 0,
	};
	var lolsoft = {
		divid: '#lolsoft',
		textid: '#textlolsoft',
		state: 0,
	};
	
	var divs = [];
	divs.push(cascaderGui, inthelabs, massprint, mailer, ubuntuBg, lolsoft);

	function showNav(divTar)
	{
//		$(divTar).animate({visibility: 'visible', zIndex: '100'},{queue:false,duration:300});
		$(divTar).fadeIn('300');
	}
	function hideNav(divTar)
	{
		$(divTar).fadeOut('300');
	}

	function bump(divTar, state)
	{
		if (state != 1){
			$(divTar).animate({left:'10px'},{queue:false,duration:160});
		}
	}
	function bumpBack(divTar, state)
	{
		if (state != 1){
			$(divTar).animate({left:'0px'},{queue:false,duration:160});
		}
	}
	
	jQuery.each(divs, function(i){
		var item = divs[i];
		$(item.divid).mouseover(function(){
			bump(item.divid, Number(item.state))
		}).mouseout(function() {
			bumpBack(item.divid, Number(item.state));
		});
	});
	
	jQuery.each(divs, function(i){
		var item = divs[i];
		$(item.divid).mouseup(function(){
			if (Number(item.state)==0){
				showNav(item.textid);
				for (var j=0; j<6; j++){
					if (j != i){
						hideNav(divs[j].textid);
						bumpBack(divs[j].divid, 0);
						divs[j].state = 0;
					}
				}
				item.state = 1;
			}
			else {
				jQuery.each(divs, function(i){
					var item = divs[i];
					hideNav(item.textid);
					bumpBack(item.divid, 0);
					item.state = 0;
				});
		}
		})
	});
});