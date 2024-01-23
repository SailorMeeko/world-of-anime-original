$(function () {
  $("#fixed-bar")
    .css({position:'fixed',bottom:'0px'})
    .hide();
  $(window).scroll(function () {
    if ($(this).scrollTop() > 400) {
      $('#fixed-bar').fadeIn(200);
    } else {
      $('#fixed-bar').fadeOut(200);
    }
  });
});


$(function() {
    $('a[title]').qtip({
        position: {
            my: 'left center',
            at: 'right center'
        },
	style: {
	    classes: 'ui-tooltip-green ui-tooltip-shadow'
	}
    });
});



$(function() {
    $('i[title]').qtip({
        position: {
            my: 'bottom center',
            at: 'top center'
        },
	style: {
	    name: 'dark', // Inherit from preset style
	    classes: 'ui-tooltip-dark ui-tooltip-rounded'
	}
    });
});
    

$(function() {    
    $('.removable_button').submit(function() {
        $('.removable').remove();
    });
});


$(function() {
    $('.inappropriate').click(function(e) {
	e.preventDefault();
	
	if ( confirm("Are you sure you want to report this content to the site admin?") ) {
	    
	    var type    = $(this).attr('type');
	    var content = $(this).attr('content');
	    var data = 'type='  + encodeURIComponent(type) + '&content=' + encodeURIComponent(content);
    
	    $.ajax({  
		url: "/report_inappropriate_content",
		type: "POST",
		data: data,       
		cache: false
	    }); 
    
	    $(this).remove();
	}
    
    return false;
    });
});


$(function() {
    $("#theme_selector").change(function() {
	theme = $("#theme_selector").val();
        document.cookie = "theme="+theme+"; path=/";
	location.reload(true);
    });
});