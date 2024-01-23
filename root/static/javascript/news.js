$(function() {
    $('#search_news').submit(function(e) {
        var searchString = $('input:first').val();
	var data = '&searchString=' + searchString;
        
	$.ajax({  
            url: "/news/search",
            type: "POST",
            dataType: 'json',
	    data: data,
            cache: false,
	    complete: function(data) {
    	    if (data.responseText == 'N') {
		// calculating offset for displaying popup message
		var height = $('#popuup_reject_div').height();
		var width = $('#popuup_reject_div').width();
		leftVal = data.pageX-(width/2)+"px";
		topVal = data.pageY-(height/2)+"px";
		// show the popup message and hide with fading effect
		$('#popuup_reject_div').css({ left:leftVal,top:topVal }).show().fadeOut(2000);
	    } else {
		$('#main_page').empty();
                $('#main_page').append('<div id="news_block">');
				
		var results = JSON.parse(data.responseText);
		var allNews = JSON.parse(results.results);
		for (var i = 0; i < allNews.length; i++) {
		    title = allNews[i];
                    filedir = title.filedir;
                    filedir = filedir.replace('/u/', '/t175/');
                    filedir = filedir.replace('/news/', '/t175/');
                    teaser  = title.teaser;
                    teaser  = teaser.replace('\n', '<p />');
                    var newArticle = '<div class="news_article">';
                        newArticle += '<h1><a href="/news/article/' + title.id + '/' + title.pretty_title + '">' + title.title + '</a></h1>';
                        newArticle += '<a href="/news/article/' + title.id + '/' + title.pretty_title + '"><img src="/' + filedir + '/' + title.filename + '"></a>';
                        newArticle += '<p class="article">' + teaser + '</p>';
                        newArticle += '<br clear="all">';
                        newArticle += '<h2 style="float: right">Submitted by <a href="/profile/' + title.submitted_by + '">' + title.submitted_by + '</a> on ' + title.createdate + '</h2><br />';
			newArticle += '</div>';
			$('#main_page').append(newArticle);
		    }
		$('#main_page').append('</div>');
		}
		
            }
        });	    

        return false;
    });
});