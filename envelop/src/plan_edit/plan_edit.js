var jcrop_api;

$(function() {
  $("#target").on("load", function() {
    console.log("load triggered");
    
    // destroy old jcrop instance if it exists
    if (typeof jcrop_api !== "undefined") {
      jcrop_api.destroy()
    }
        
    // create a new jcrop instance
    $(this).Jcrop({
      //onChange: previewCrop,
      onSelect: previewCrop,
      onRelease: previewCrop,
      trueSize: [$(this)[0].naturalWidth, $(this)[0].naturalHeight],
    },function(){
      jcrop_api = this;
    });
  })
  
  sketchup.ready();
})

function setImage(image_base64) {
  sketchup.say("setImage callback");

  // change the image
  $("#target").attr("src", image_base64);
}

function previewCrop(c) {
  if (typeof c === 'undefined') return
  
  // show crop preview for debug purposes
  $("#output").attr("src", imageToDataUri($("#target")[0], c.x, c.y, c.w, c.h));
};

// https://stackoverflow.com/questions/20958078/resize-a-base-64-image-in-javascript-without-using-canvas
function imageToDataUri(img, x, y, width, height) {
  // create an off-screen canvas
  var canvas = document.createElement('canvas'),
      ctx = canvas.getContext('2d');

  // set its dimension to target size
  canvas.width = width;
  canvas.height = height;

  // draw source image into the off-screen canvas:
  ctx.drawImage(img, x, y, width, height, 0, 0, width, height);

  // encode image to data-uri with base64 version of compressed image
  return canvas.toDataURL();
}

