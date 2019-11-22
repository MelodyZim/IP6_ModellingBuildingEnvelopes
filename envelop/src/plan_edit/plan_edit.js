var cropper;

$(function() {
  cropper = new Cropper($("#target")[0], {
    viewMode: 2,
    //guides: false,
    //center: false,
    zoomable: false,
    scalable: false,
    toggleDragModeOnDblclick: false,
    autoCrop: false,
    ready() {
      $("#rotCCW").on('click', function() {
        cropper.rotate(-90);
      });
      $("#rotCW").on('click', function() {
        cropper.rotate(90);
      });
      $("#accept").on('click', function() {
        $("#output").attr("src", cropper.getCroppedCanvas().toDataURL());
      });
    }
  });
  
  $("#cancel").on('click', function() {
    sketchup.cancel();
  });
  
  sketchup.ready();
})

function setImage(image_base64) {
  sketchup.say("setImage callback");

  if (typeof cropper === 'undefined') return
  cropper.replace(image_base64)
}

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

