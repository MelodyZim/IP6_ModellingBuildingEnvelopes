$(function() {
  $("#material-template").hide();

  sketchup.ready();
});

function setMaterials(materials_as_hash_array) {
  $("#materials-container").empty();
  JSON.parse(materials_as_hash_array).sort((m1,m2) => m1.index - m2.index).forEach(add_material);
}

// TODO: add name edditing
// TODO: add color edditing
function add_material(matrial_as_hash) {
  material_div = new_material_div();

  material_div.css("background-color", `rgb(${matrial_as_hash.color_rgb[0]},${matrial_as_hash.color_rgb[1]},${matrial_as_hash.color_rgb[2]})`);

  $material_name = material_div.find('.material-name')
  $material_name.html(matrial_as_hash.name);
  $material_name.css("color", (matrial_as_hash.color_hsl_l > 0.5 ? 'black' : 'white'));

  material_div.find('.material-delete').css("color", (matrial_as_hash.color_hsl_l > 0.5 ? 'black' : 'white'));
  material_div.find('.material-add').css("color", (matrial_as_hash.color_hsl_l > 0.5 ? 'black' : 'white'));

  material_div.find('.material-delete').on('click', function(local_material_div, local_matrial_as_hash){ return  function() {
    local_material_div.remove();
    sketchup.delete_material(local_matrial_as_hash.name);
  }}(material_div, matrial_as_hash));

  material_div.find('.material-add').on('click', function(local_matrial_as_hash){ return  function() {
    sketchup.add_material(local_matrial_as_hash.name);
  }}(matrial_as_hash));

  material_div.on('click', function(local_matrial_as_hash){ return  function() {
    sketchup.select_material(local_matrial_as_hash.name);
  }}(matrial_as_hash));
}

var material_div_counter = 0;

function new_material_div() {
  material_div_counter++;

  var $clone = $("#material-template").clone().prop('id', 'mateiral-div-' + material_div_counter);

  $("#materials-container").append($clone);

  $clone.show();

  return $clone;
}
