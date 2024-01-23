'use strict';

app.controller('MembersController', function($scope, $http) {

	$scope.getNewest = function()
	{
	    $http.get('/api/members/newest').
	    success(function(data, status, headers, config) {
	      $scope.members = data;
	    }).
	    error(function(data, status, headers, config) {
	      console.log(status);
	    });		
	}    

});