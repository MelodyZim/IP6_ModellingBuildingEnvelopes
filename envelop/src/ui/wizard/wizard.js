$(function() {
  $("#step_template").hide();
  $("#substep_template").hide();

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

  if (step.hasOwnProperty("sublist")) {
    step_div.addClass("setp_with_substeps");

    last_substep = step.sublist.pop();
    step.sublist.forEach(substep => add_substep(step.number, substep));
    add_substep(step.number, last_substep).addClass("last_substep");
  }
}

function add_substep(number, step) {
  substep_div = new_substep_div();

  substep_div.find('.number').html(number + "." + step.number);
  substep_div.find('.title').html(step.title);

  return substep_div;
}

var div_counter = 0;

function new_step_div() {
  div_counter++;

  var $clone = $("#step_template").clone().prop('id', 'step-div-' + div_counter);

  $("#steps_container").append($clone);

  $clone.show();

  return $clone;
}

function new_substep_div() {
  div_counter++;

  var $clone = $("#substep_template").clone().prop('id', 'substep-div-' + div_counter);

  $("#steps_container").append($clone);

  $clone.show();

  return $clone;
}
