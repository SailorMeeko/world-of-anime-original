$(document).ready(function(){
    $('.newWindow').click(function (event){
 
    var url = $(this).attr("href");
    var windowName = "pm";
    var windowSize = 'width=600,height=600,scrollbars=yes';
 
    window.open(url, windowName, windowSize);
 
    event.preventDefault();
 
    });
    
});


$(function() {
    $("#mark_user_pms_read").click(function() {

        var from_user_id = $(this).attr('from_user_id');
        var data = '&from_user_id=' + from_user_id;
        
        if ( confirm("Are you sure you want to mark all private messages from this user as read?") ) {

	$.ajax({  
            url: "/pm/mark_user_read",
            type: "POST",
	    data: data,
            cache: false,
	    complete: function(data) {
            }
        });

            $('span').removeClass('unread');
        }

    return false;
	
    });
});


$(function() {
    $("#mark_all_pms_read").click(function() {

        var from_user_id = $(this).attr('from_user_id');
        
        if ( confirm("Are you sure you want to mark all of your private messages as read?") ) {

	$.ajax({  
            url: "/pm/mark_all_read",
            type: "POST",
            cache: false,
	    complete: function(data) {
                location.reload(true);
            }
        });


        }

    return false;
	
    });
});


$(function() {
    $("#delete_user_pms").click(function() {

        var from_user_id = $(this).attr('from_user_id');
        var data = '&from_user_id=' + from_user_id;
        
        if ( confirm("Are you sure you want to delete all of your private messages from this user?") ) {

	$.ajax({  
            url: "/pm/delete_pms",
            type: "POST",
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


$(function() {
    $("#delete_all_pms").click(function() {
        
        var data = '&type=all';

        if ( confirm("Are you sure you want to delete all of your private messages?") ) {

	$.ajax({  
            url: "/pm/delete_pms",
            type: "POST",
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


$(function() {
   $(".delete_pm").click(function() {
    
        var pm_id   = $(this).attr('pm_id');
        var from_id = $(this).attr('from_id');
        var data    = '&pm_id=' + pm_id;
        var new_url = '/pm/from/' + from_id;
        
        if ( confirm("Are you sure you want to delete this private message?") ) {
            
            $.ajax({  
                url: "/pm/delete",
                type: "POST",
                data: data,
                cache: false,
                complete: function(data) {
                    location.replace(new_url);
                }
            });
        }
        
    return false;

   });
});