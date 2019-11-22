var cropper;

$(function() {
  cropper = new Cropper($("#target")[0], {
    viewMode: 0,
    //guides: false,
    //center: false,
    scalable: false,
    movable: false,
    zoomable: true,
    zoomOnWheel: false, // prevent manual zooming
    zoomOnTouch: false, // prevent manual zooming
    toggleDragModeOnDblclick: false, // prevent manual moving
    autoCrop: false, // start without a cropbox
  });
  
  // zoom the cropper canvas to fit inside the container
  function zoomCropperCanvas() {
    cropper.zoomTo(cropper.getContainerData().height / cropper.getCanvasData().naturalHeight)
  }
  
  $("#rotCCW").on('click', function() {
    cropper.clear();  // clear the cropbox
    cropper.rotate(-90);
    zoomCropperCanvas();
  });
  $("#rotCW").on('click', function() {
    cropper.clear();  // clear the cropbox
    cropper.rotate(90);
    zoomCropperCanvas();
  });
  $("#accept").on('click', function() {
    $("#output").attr("src", cropper.getCroppedCanvas().toDataURL());
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
