$(function() {
    $('.delete-comment').live('click', function() {
	var id = $(this).attr('id');
        var group_id = $(this).attr('group_id');
        var type = $(this).attr('type');
        if ( confirm("Are you sure you want to permanently delete this comment?") ) {
		
	    var data = 'comment='  + id + '&group_id=' + group_id + '&type=' + type;
		
	    $.ajax({
	        url: "/groups/comment/delete",
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
    $('.get_replies').click( function() {
	var id = $(this).attr('id');
        var group_id = $(this).attr('group_id');
		
	var data = 'id='  + id + '&group_id=' + group_id;
		
	$('div.replies_' + id + ' p').load('/groups/get_replies?' + data);

        return false;
    });
});   


$(function() {
    $("#leave_group").click(function() {

        var group_id = $(this).attr('group_id');
	var data = 'group_id='  + group_id;
        
        if ( confirm("Are you sure you want to no longer be a member of this group?") ) {

	$.ajax({  
            url: "/groups/leave",
            type: "GET",
	    data: data,
            cache: false,
	    complete: function(data) {
                location.reload(true);
            }
        });


        }

    return false;
	
    });
});
