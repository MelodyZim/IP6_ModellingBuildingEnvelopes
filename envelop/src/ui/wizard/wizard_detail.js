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
  console.log(content);

  console.log(`${content.forNumber} ${content.title}`);
  $('#title').html(`${content.forNumber} ${content.title}`);

  $('#movie_src').attr('src', content.video);
  $('#movie')[0].load();
  $('#movie')[0].play();

  content.steps.forEach(add_step);
};

function add_step(step) {
  $('#steps').append(`<li>${step}</li>`);
}
