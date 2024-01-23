$(function() {
    $('.delete-comment').click( function() {
        var id = $(this).attr('id');
	if ( confirm("Are you sure you want to permanently delete this comment?") ) {
    	
	    var data = 'comment='  + id;
    	
	    $.ajax({
	        url: "/blogs/comment/delete",
                type: "GET",
		data: data,
                cache: false
            });
	    
	    $('.comment_' + id).remove();
        }
        return false;
    });
});