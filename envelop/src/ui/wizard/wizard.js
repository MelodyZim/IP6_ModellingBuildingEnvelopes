$(function() {
  $("#step_template").hide();

  sketchup.call_set_content();
});

function set_content(content) {
  $("#steps_container").empty();
  JSON.parse(content).steps.forEach(add_step);
}

function add_step(step) {
    step_div = new_step_div();

    step_div.find('.number').html(step.number);
    step_div.find('.title').html(step.title);
}

var step_div_counter = 0;
function new_step_div() {
  step_div_counter++;

  var $clone = $("#step_template").clone().prop('id', 'step-div-' + step_div_counter);

  $("#steps_container").append($clone);

  $clone.show();

  return $clone;
}
