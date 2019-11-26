$(function() {
  $("#close").on('click', function() {
    sketchup.close();
  });

  sketchup.ready();
})

function set_result(result) {
  sketchup.say("set result")
  
  var html = '';
  const obj = JSON.parse(result);
  const directions = ["F", "R", "N", "NE", "E", "SE", "S", "SW", "W", "NW"]
  
  // generate header
  html += "<tr><th></th>"
  directions.forEach(function (dir, index) {
    html += `<th>${dir}</th>`
  });
  html += "</tr>"
  
  // generate new table rows
  for (var prop in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, prop)) {
      html += `<tr><th>${prop}</th>`
      
      directions.forEach(function (dir, index) {
        if (dir in obj[prop]) {
          html += `<td>${obj[prop][dir].toFixed(2)}</td>`
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
