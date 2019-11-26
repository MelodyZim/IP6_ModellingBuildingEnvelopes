$(function() {

  sketchup.ready();
})

function set_result(result) {
  // clear table
  $("#areaTable").not(':first').remove();
  
  // generate new table rows
  var obj = JSON.parse(result);
  var html = '';
  
  for (var prop in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, prop)) {
      directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
      html += `<tr><th>${prop}</th>`
      
      directions.forEach(function (dir, index) {
        if (dir in obj[prop]) {
          html += `<td>${obj[prop][dir].toFixed(2)}</td`
        } else {
          html += "<td></td>"
        }
      });
      html += "</tr>";
    }
  }
  
  $('#areaTable tr').first().after(html);
}
