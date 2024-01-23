$(function() {
    $('.delete-comment').live('click', function() {
	var id = $(this).attr('id');
        if ( confirm("Are you sure you want to permanently delete this comment?") ) {
		
	    var data = 'comment='  + id;
		
	    $.ajax({
		url: "/profile/comment/delete",
		type: "GET",
        	data: data,
                cache: false
            });
	    
	    $('.comment_' + id).remove();
	}
        return false;
    });
});
    

$(function() {
    $('.friend-remove').click( function(e) {
	var id = $(this).attr('id');
	if ( confirm("Are you sure you want to remove this friend?") ) {
            
	    var data = 'friend='  + id;

	    // getting height and width of the message box
	    var height = $('#popuup_unfriend_div').height();
	    var width = $('#popuup_unfriend_div').width();
            
	    // calculating offset for displaying popup message
	    leftVal = e.pageX-(width/2)+"px";
	    topVal = e.pageY-(height/2)+"px";
            
	    // show the popup message and hide with fading effect
	    $('#popuup_unfriend_div').css({ left:leftVal,top:topVal }).show().fadeOut(3000);

	    $.ajax({
		url: "/profile/friend/remove",
		type: "GET",
		data: data,
                cache: false
            });
		
	    $('.your_friend').remove();
	}
        return false;
    });
});


    
$(function() {
    $('#now_action').live('submit', function(e) {
	var type   = $(this).attr('type');
	var action = $('#new_action_' + type).val();
	var data = 'action='  + encodeURIComponent(action) + '&type=' + type;
	$('#change_' + type).hide();
	$('div.' + type).html(action);
	$('#' + type).show();
        $('#setup_change_' + type).show()

	$.ajax({  
	    url: "/profile/ajax/update_now_action",
	    type: "POST",
	    data: data,       
	    cache: false
	});

    return false;
    });
});


$(function() {
    $('#add_comment').live('submit', function(e) {
        var parent = $(this).attr('parent');
	var user   = $(this).attr('user');
	var latest = $(this).attr('latest');
	$('#reply_' + parent).hide();

	var message = $('textarea#comment_box_' + parent);
        var data = 'post='  + encodeURIComponent(message.val()) + '&user=' + encodeURIComponent(user) + '&latest=' + latest;
	$('textarea#comment_box_' + parent).val("");

	$.ajax({  
            url: "/profile/ajax/add_reply/" + parent,
            type: "POST",
            data: data,       
            cache: false,
	    success: function(response) {

		$.ajax({
		    url: "/profile/ajax/load_profile_replies/" + parent,
		    type: "POST",
		    data: data,
		    cache: false,
                    success: function(new_replies) {
			$('.replies_' + parent).empty();
			$('.replies_' + parent).append(new_replies);
			$('#setup_reply_' + parent).show();
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


$(function() {
    $('#add_comment_single').live('submit', function(e) {
        var parent = $(this).attr('parent');
	var user   = $(this).attr('user');
	var latest = $(this).attr('latest');
	$('#reply_' + parent).hide();

	var message = $('textarea#comment_box_' + parent);
        var data = 'post='  + encodeURIComponent(message.val()) + '&user=' + encodeURIComponent(user) + '&latest=' + latest;
	$('textarea#comment_box_' + parent).val("");

	$.ajax({  
            url: "/profile/ajax/add_reply/" + parent,
            type: "POST",
            data: data,       
            cache: false,
	    success: function(new_id) {
		$('.replies_' + parent).load('/profile/ajax/load_reply/' + new_id);
	    },
	    error: function(jqXHR, textStatus, errorThrown) {
	    }
        });

    $.scrollTo( '.bottom', 500);
    return false;
    });
});


$(function() {
    $('.reply_link').live('click', function(e) {
        var id   = $(this).attr('id');
	$('#reply_' + id).show();
	$('#comment_form_' + id + ' #comment_box_' + id).focus();
        return false;
    });
});


var clearNowBlocks = function() {
	if (confirm("This will delete the content of all of your Now Doing Blocks.  Are you sure you want to do this?")) {
		$.ajax({
			url: "/profile/ajax/delete_now_blocks"
		});
		$('.now_block').empty();
		$('#[id*="new_action_"]' ).val("");
		$('#new_action_now_watching').val("");
	}
}