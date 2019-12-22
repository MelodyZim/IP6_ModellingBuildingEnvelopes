var picker;

$(function() {
  $("#material-template").hide();

  sketchup.ready();
});

function setMaterials(materials_as_hash_array) {
  $("#materials-container").empty();
  JSON.parse(materials_as_hash_array).sort((m1, m2) => m1.index - m2.index).forEach(add_material);
}

// TODO: add name edditing
// TODO: add color edditing
function add_material(matrial_as_hash) {
  material_div = new_material_div();

  material_div.css("background-color", '#' + CP.RGB2HEX(matrial_as_hash.color_rgb));
  material_div.attr("data-old-color", CP.RGB2HEX(matrial_as_hash.color_rgb));

  material_div.find('.material-button').addClass('material-button-' + (matrial_as_hash.color_hsl_l > 0.5 ? 'black' : 'white') + '-border');

  $material_name = material_div.find('.material-name')
  $material_name.html(matrial_as_hash.name);

  material_div.find('.material-content').css("color", (matrial_as_hash.color_hsl_l > 0.5 ? 'black' : 'white'));

  material_div.find('.material-delete').on('click', function(local_material_div, local_matrial_as_hash) {
    return function() {
      local_material_div.remove();
      sketchup.delete_material(local_matrial_as_hash.name);
    }
  }(material_div, matrial_as_hash));

  material_div.find('.material-add').on('click', function(local_matrial_as_hash) {
    return function() {
      sketchup.add_material(local_matrial_as_hash.name);
    }
  }(matrial_as_hash));

  material_change_color = material_div.find('.material-change-color');
  material_change_color.attr('data-color', '#' + CP.RGB2HEX(matrial_as_hash.color_rgb));
  picker = new CP(material_change_color[0])
  picker.on('change', function(local_material_div) {
    return function(value) {
      var exited = local_material_div.attr('exited');
      if (typeof exited !== typeof undefined && exited !== false) {
        local_material_div.removeAttr("exited");
      } else {
        local_material_div.css("background-color", '#' + value);
        local_material_div.attr("data-new-color", value);
      }
    }
  }(material_div));

  picker.on('exit', function(local_material_div, local_picker) {
    return function() {
      var saved = local_material_div.attr('saved');
      if (typeof saved == typeof undefined || saved == false) {
        local_material_div.css("background-color", '#' + local_material_div.attr('data-old-color'));
        local_material_div.attr('exited', 'true')
        local_picker.set('#' + local_material_div.attr('data-old-color'));
        local_material_div.removeAttr("data-new-color");
      }
    }
  }(material_div, picker));

  // <button value="0" id="place_F"></button>
  var save_color_button = document.createElement('button');
  save_color_button.className = 'save-color-button';
  save_color_button.innerHTML = 'Save Color';
  save_color_button.addEventListener("click", function(local_matrial_as_hash, local_material_div, local_picker) {
    return function() {
      var new_color = local_material_div.attr('data-new-color');
      if (typeof new_color !== typeof undefined && new_color !== false && new_color != local_material_div.attr('data-old-color')) {
        sketchup.update_color(local_matrial_as_hash.name, CP.HEX2RGB(new_color));
        local_material_div.attr('saved', 'true')
        local_picker.exit();
      } else {
        local_picker.exit();
      }
    }
  }(matrial_as_hash, material_div, picker), false);
  picker.self.appendChild(save_color_button);

  material_div.on('click', function(local_matrial_as_hash) {
    return function() {
      sketchup.select_material(local_matrial_as_hash.name);
    }
  }(matrial_as_hash));
}

var material_div_counter = 0;

function new_material_div() {
  material_div_counter++;

  var $clone = $("#material-template").clone().prop('id', 'mateiral-div-' + material_div_counter);

  $("#materials-container").append($clone);

  $clone.show();

  return $clone;
}
