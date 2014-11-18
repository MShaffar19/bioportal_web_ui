'use strict';

// Declare app level module which depends on views, and components
angular.module('FacetedBrowsing', [
  'ngRoute',
  'FacetedBrowsing.OntologyList'
]).
config( ['$locationProvider', function ($locationProvider) {
  $locationProvider.html5Mode(true);
}])
;

var app = angular.module('FacetedBrowsing.OntologyList', ["checklist-model"])

.controller('OntologyList', ['$scope', function($scope) {
  $scope.facets = {
    types: ["ontology"],
    formats: [],
    groups: [],
    categories: [],
    artifacts: []
  }
  $scope.types = ["ontology", "ontology_view"];
  $scope.artifacts = ["notes", "reviews", "projects"];
  $scope.ontologies = jQuery(document).data().bp.ontologies;
  $scope.formats = jQuery(document).data().bp.formats.sort();
  $scope.categories = jQuery(document).data().bp.categories.sort(function(a, b){
    if (a.name < b.name) return -1;
    if (a.name > b.name) return 1;
    return 0;
  });
  $scope.groups = jQuery(document).data().bp.groups.sort(function(a, b){
    if (a.acronym < b.acronym) return -1;
    if (a.acronym > b.acronym) return 1;
    return 0;
  });

  $scope.$watch('facets', function() {
    var ontology;
    for (var i = 0; i < $scope.ontologies.length; i++) {
      ontology = $scope.ontologies[i];
      ontology.show = true;
      if ($scope.facets.types.length > 0) {
        if ($scope.facets.types.indexOf(ontology.type) === -1) {
          ontology.show = false;
          continue;
        }
      }
    }
  }, true);
}])

.filter('idToTitle', function() {
  return function(input) {
    if (input) {
      var splitInput = input.replace(/_/g, " ").split(" ");
      var newInput = [];
      var word;
      for (word in splitInput) {
        word = splitInput[word];
        if (word[0].toUpperCase() == word[0]) {
          newInput.push(word);
        } else {
          newInput.push(word[0].toUpperCase() + word.slice(1));
        }

      }
      return newInput.join(" ");
    }
  };
});