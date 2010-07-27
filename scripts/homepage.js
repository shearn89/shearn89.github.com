// JavaScript Document
$(document).ready(function(){
	var cascaderGui = {
		divid: '#cascader-gui',
		state: 0,
	};
	var inthelabs = {
		divid: '#inthelabs',
		state: 0,
	};
	var massprint = {
		divid: '#massprint',
		state: 0,
	};
	var mailer = {
		divid: '#mailer',
		state: 0,
	};
	var ubuntuBg = {
		divid: '#ubuntu-bg',
		state: 0,
	};
	var lolsoft = {
		divid: '#lolsoft',
		state: 0,
	};
	
	var divs = [];
	divs.push(cascaderGui, inthelabs, massprint, mailer, ubuntuBg, lolsoft);
	
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
});