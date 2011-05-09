/* Author: Alex 'shearn89' shearn. Email script pinched from bruno panara (brunopanara.com).
*/
function hide_email() {
	email_start = "mailto:alex";
	email_end = "at.it";
	email_middle = "@isth";
	return email_start + email_middle + email_end;
}

jQuery(function(){
	links = $('aside').find('a');
	labels = $('#labels').find('li');

	jQuery.each(links, function(i){
		$(links[i]).mouseover(function(){
			$(labels[i]).stop().animate({opacity:1}, 300);
			$(links[i]).find('img').stop().animate({backgroundPosition: "0 0"}, 300);
		});
		$(links[i]).mouseout(function(){
			$(labels[i]).stop().animate({opacity:0}, 300);
			$(links[i]).find('img').stop().animate({backgroundPosition: "(0 64px)"}, 300);
		});
	});
});
