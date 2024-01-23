'use strict';

app.controller('FriendController', function($scope, $http) {

	$scope.init = function(Username)
	{
		$scope.username = Username;

	    $http.get('/api/friends/get_friends/' + $scope.username).
	    success(function(data, status, headers, config) {
	      $scope.friends = data;
	    }).
	    error(function(data, status, headers, config) {
	      console.log(status);
	    });		
	}    

});