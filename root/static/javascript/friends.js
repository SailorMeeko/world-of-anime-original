$(function() {
    $('.friend-reject').click( function(e) {
	var id = $(this).attr('id');
	if ( confirm("Are you sure you want to reject this friend request?") ) {

	    var data = 'friend='  + id;

	    // getting height and width of the message box
            var height = $('#popuup_reject_div').height();
	    var width = $('#popuup_reject_div').width();
	    // calculating offset for displaying popup message
	    leftVal = e.pageX-(width/2)+"px";
	    topVal = e.pageY-(height/2)+"px";
	    // show the popup message and hide with fading effect
	    $('#popuup_reject_div').css({ left:leftVal,top:topVal }).show().fadeOut(3000);
		
	    $.ajax({
		url: "/profile/friend_request/reject",
		type: "GET",
		data: data,
                cache: false
            });
	    
	    $('.friend_' + id).remove();
	}
        return false;
    });
});


$(function() {
    $('.friend-accept').click( function(e) {
	var id = $(this).attr('id');
	if ( confirm("Are you sure you want to accept this friend request?") ) {
	    
	    var data = 'friend='  + id;

	    // getting height and width of the message box
	    var height = $('#popuup_accept_div').height();
	    var width = $('#popuup_accept_div').width();
	    // calculating offset for displaying popup message
	    leftVal = e.pageX-(width/2)+"px";
	    topVal = e.pageY-(height/2)+"px";
	    // show the popup message and hide with fading effect
	    $('#popuup_accept_div').css({ left:leftVal,top:topVal }).show().fadeOut(3000);
		
	    $.ajax({
		url: "/profile/friend_request/accept",
		type: "GET",
		data: data,
                cache: false
            });
		
	    $('.friend_' + id).remove();
	}
        return false;
    });
});