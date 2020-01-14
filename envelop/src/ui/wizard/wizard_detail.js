$(function() {
  $(this).keydown(function(e) {
    if (e.keyCode == 27) {
      sketchup.close();
    }
  });

  sketchup.call_set_content();
});

function set_content(content) {
  content = JSON.parse(content);
  $('#movie_src').attr('src', content.video);
};
