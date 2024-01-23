$(function() {
    $('#search_title').submit(function(e) {
        var searchString = $('#search_string').val();
	var data = '&searchString=' + searchString;

	$.ajax({  
            url: "/anime/search",
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
		$('#main_page').append('<table id="anime_titles"><tr><th width="80%">Title</th><th width="10%">Type</th><th width="10%">Year</th></tr>');
				
		var results = JSON.parse(data.responseText);
		var allTitles = JSON.parse(results.results);
		for (var i = 0; i < allTitles.length; i++) {
		    title = allTitles[i];
		    var newTitle = '<tr><td><a href="/anime/' + title.id + '/' + title.pretty_title + '">' + title.title + '</a></td>';
			newTitle += '<td>' + title.type + '</td><td>' + title.year + '</td></tr>';
			$('table').append(newTitle);
		    }
		$('#main_page').append('</table>');
		}
		
            }
        });	    

        return false;
    });
});


$(function() {
    $('#rate_form').submit(function(e) {
        var title_id = $(this).attr('title_id');
	var rating   = $("#rating").val();
	
	if (!(rating)) {
	    alert("You select a rating between 1 - 10 for this anime");
	    return false;
	}
	
	var data = 'title_id=' + title_id + '&rating=' + rating;

	$.ajax({  
            url: "/anime/ajax/rate",
            type: "POST",
            dataType: 'json',
	    data: data,
            cache: false,
	    complete: function(data) {
		
		if (data.responseText == 'N') {

		} else {
		    var results = JSON.parse(data.responseText);

		    var avg_rating  = parseFloat(results[0].avg_rating).toFixed(2);
		    var num_ratings = results[0].num_ratings;

		    $('.rating_stars').load('/ajax/star_rating/' + avg_rating);
		    
		    // New tooltip
		    
		    var tip = avg_rating + ' out of 10; based on ' + num_ratings + ' rating';
		    if (num_ratings != 1) {
			tip += 's';
		    }
		    
		    $('#rating_box').qtip('option', 'content.text', tip);
		    
		    $('#user_rating').empty();
		    // $('#your_hidden_rating').html('Your Rating: ' + rating);
		}
	    }
        });	    

        return false;
    });
});
