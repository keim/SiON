$(document).ready(function(){
  $("h2").append("<span class='control'><a class='open_all' href='#'>[open]</a> <a class='close_all' href='#'>[close]</a></span>");
  $("h3").wrap("<a class='toggle' href='#'></a>");
  $("div.title").wrap("<a class='toggle' href='#'></a>");
  $(".toggle")   .click(function(){ $(this).next().slideToggle("fast"); return false; });
  $(".close_all").click(function(){ $(this).parents("h2").next().children(".toggle").next().slideUp("fast"); return false; });
  $(".open_all") .click(function(){ $(this).parents("h2").next().children(".toggle").next().slideDown("fast"); return false; });

  SIOPM.onLoad = function() { 
    var $example = $("pre.example");
    $example.css("cursor", "pointer");
    $example.hover(function(){ $(this).css("background-color", "#c0c0f0"); }, function(){ $(this).css("background-color", "#f0f0f0"); });
    $example.click(function(){ SIOPM.compile($(this).text()); });
    var $tone = $("td.tone");
    $tone.css("cursor", "pointer");
    $tone.hover(function(){ $(this).css("background-color", "#c0c0f0"); }, function(){ $(this).css("background-color", "#f0f0f0"); });
    $tone.click(function(){ SIOPM.compile($(this).find("span.mml").text()); });
  }
  SIOPM.onError = function(errorMessage){ alert(errorMessage); }
  SIOPM.urlSWF = "siopm_sf.swf";
  SIOPM.initialize();
});


