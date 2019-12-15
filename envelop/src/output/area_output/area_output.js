$(function() {
  $("#copy").on('click', function() {
    selection = window.getSelection();
    selection.empty();
    selection.selectAllChildren($('#areaTable').get(0));
    document.execCommand("copy")
  });

  $("#close").on('click', function() {
    sketchup.close();
  });

  sketchup.ready();
})

function set_result(result) {
  sketchup.say("set result")

  var html = '';
  const result_json = getSortedHash(JSON.parse(result));
  const directions = ["N", "NO", "NW", "SO", "W", "SW", "H", "Total"]

  // generate header
  html += "<tr><th></th>"
  directions.forEach(function (dir, index) {
    html += `<th>${dir}</th>`
  });
  html += "</tr>"

  // generate new table rows
  for (var prop in result_json) {
    if (Object.prototype.hasOwnProperty.call(result_json, prop)) {
      html += `<tr><th>${prop}</th>`

      directions.forEach(function (dir, index) {
        if (dir in result_json[prop]) {
          html += `<td>${result_json[prop][dir].toFixed(2)}</td>`
        } else {
          html += "<td></td>"
        }
      });
      html += "</tr>";
    }
  }

  // replace content of table
  $('#areaTable').html(html);
}

//from https://stackoverflow.com/a/33572804
function getSortedHash(inputHash){
  var resultHash = {};

  var keys = Object.keys(inputHash);
  keys.sort(function(a, b) {
    return inputHash[a].index - inputHash[b].index
  }).forEach(function(k) {
    resultHash[k] = inputHash[k];
  });
  return resultHash;
}
