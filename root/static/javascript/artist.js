$(function() {
    $("#chapter_selector").change(function() {
        var value = $(this).attr('value');
        var story_id = $(this).attr('story_id');
	var pretty_title = $(this).attr('pretty_title');
        window.location.href = "/artist/fiction/view_story/" + story_id + "/" + value + "/" + pretty_title;
    });
});


$(function() {
    $('#chapter_fiction_form').submit(function(e) {
        var chapterTitle   = $("#chapterTitle").val();
        var chapterContent = $("#chapterContent").val();
        var story_id       = $(this).attr('story_id');
	var pretty_title   = $(this).attr('pretty_title');
	var data = '&chapterTitle=' + encodeURIComponent(chapterTitle) + '&chapterContent=' + encodeURIComponent(chapterContent) + '&story_id=' + story_id;

	if (!(chapterContent)) {
	    alert("Your chapter has no content!");
	    return false;
	}
	
        $.ajax({  
            url: "/artist/fiction/write_chapter",
            type: "POST",
	    data: data,
            cache: false,
	    complete: function(data) {
		var new_url = '/artist/fiction/view_story/' + story_id + '/latest/' + pretty_title;
		$('#chapter_writer').empty();
		$('#chapter_writer').append('Chapter submitted. <a href="' + new_url + '">Go to new chapter</a>');
		window.location.href = new_url;		
            }
        });	    

    $('.final_removable').remove();
    return false;
    });
});


$(function() {
    $("#previous_chapter").submit(function() {
        var chapter = $(this).attr('chapter');
        var nextChap = parseInt(chapter) - 1;
        var story_id = $(this).attr('story_id');
	var pretty_title = $(this).attr('pretty_title');
        window.location.href = "/artist/fiction/view_story/" + story_id + "/" + nextChap + "/" + pretty_title;
        return false;
    });
});


$(function() {
    $("#next_chapter").submit(function() {
        var chapter = $(this).attr('chapter');
        var nextChap = parseInt(chapter) + 1;
        var story_id = $(this).attr('story_id');
	var pretty_title = $(this).attr('pretty_title');
        window.location.href = "/artist/fiction/view_story/" + story_id + "/" + nextChap + "/" + pretty_title;
        return false;
    });
});



$(function() {
    $("#subscription_box").click(function() {

        var story_id = $(this).attr('story_id');
	var data = '&story_id=' + story_id;
	
	$.ajax({  
            url: "/artist/fiction/toggle_subscription",
            type: "POST",
	    data: data,
            cache: false,
	    complete: function(data) {
		checkSubscription();
            }
        });
	
    });
});


$(function() {
    $('#add_comment').live('submit', function(e) {
        var story = $(this).attr('story');
	var chapter = $(this).attr('chapter');
	var latest = $(this).attr('latest');

	var message = $('textarea#comment_box').val();
	$('textarea#comment_box').val("");
	$('#new_comment_box').remove();
        $('.comment_button').remove();
        var data = 'comment='  + encodeURIComponent(message);

	$.ajax({  
            url: "/artist/fiction/ajax/add_comment/" + story + "/" + chapter,
            type: "POST",
            data: data,       
            cache: false,
	    success: function(response) {
		$.ajax({
		    url: "/artist/fiction/ajax/load_comments/" + story + "/" + chapter + "/" + latest,
		    type: "POST",
		    cache: false,
                    dataType: 'json',
                    success: function(new_comments) {
			$('#new_comments').append(new_comments);
                        $.scrollTo( '#new_comments', 500);
		    },
		    dataType: 'html'
                });

	    },
	    error: function(jqXHR, textStatus, errorThrown) {
	    }
        });

    return false;
    });
});