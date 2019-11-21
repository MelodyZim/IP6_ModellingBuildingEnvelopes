var jcrop_api;

$(function() {
  sketchup.ready();
})

function setImage(image_base64) {
  sketchup.say("setImage callback");

  // destroy old jcrop instance if it exists
  if (typeof jcrop_api !== "undefined") {
    jcrop_api.destroy()
  }
  
  // change the image
  $("#target").attr("src", image_base64);
  
  // create a new jcrop instance
  $('#target').Jcrop({
    //onChange: showCoords,
    //onSelect: showCoords,
    //onRelease: showCoords,
  },function(){
    jcrop_api = this;
  });
}

