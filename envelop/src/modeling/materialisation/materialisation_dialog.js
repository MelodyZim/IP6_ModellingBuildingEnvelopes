var picker;

$(function() {
  $("#material-template").hide();
  $("#group-template").hide();

  $("#add-material").on('click',
      function() {
      var new_material_type = prompt("Please enter new material type abbreviation:");
      if (new_material_type !== null && new_material_type !== "") {
        sketchup.new_material_type(new_material_type);
      }
    });

  sketchup.call_set_materials();
});

function setMaterials(materials_as_hash_array) {
  $("#groups-container").empty();

  materials_array = JSON.parse(materials_as_hash_array);

  [...new Set(materials_array.map(m => m.base_name))].forEach(g => add_group(g, materials_array.filter(m => m.base_name === g)))
}

function add_group(group, materials) {
    group_div = new_group_div();

    materials_sorted= materials.sort((m1,m2) => m2.name.localeCompare(m1.name, {numeric: true}));
    materials_sorted.forEach(m => add_material(group_div, m));

    group_div.find('.add-material-group').on('click', function(first_material) {
      return function() {
        sketchup.add_material(first_material.name);
      }
    }(materials_sorted[materials_sorted.length - 1]));
}

function add_material(parent, matrial_as_hash) {
  material_div = new_material_div(parent);

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

// TODO: FS: it would be nice if there was a abort button too
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

// TODO :FS: the materialisation tool is generaly active after clicking the buttons to do something with ti - that is wrong

  material_div.on('click', function(local_matrial_as_hash) {
    return function() {
      sketchup.select_material(local_matrial_as_hash.name);
    }
  }(matrial_as_hash));
}

var group_div_counter = 0;

function new_group_div() {
  group_div_counter++;

  var $clone = $("#group-template").clone().prop('id', 'group-div-' + group_div_counter);

  $("#groups-container").append($clone);

  $clone.show();

  return $clone;
}

var material_div_counter = 0;

function new_material_div(parent) {
  material_div_counter++;

  var $clone = $("#material-template").clone().prop('id', 'mateiral-div-' + material_div_counter);

  parent.prepend($clone);

  $clone.show();

  return $clone;
}
