$(function() {
  sketchup.ready();
})

function setImage(image_base64) {
  sketchup.say("setImage callback");
  
  $("#target").attr("src", image_base64);
  $('#target').Jcrop({
    //onChange: showCoords,
    //onSelect: showCoords,
    //onRelease: showCoords,
  });
}

