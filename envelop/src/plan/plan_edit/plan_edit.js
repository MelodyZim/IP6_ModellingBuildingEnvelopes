var cropper;

$(function() {
  cropper = new Cropper($("#target")[0], {
    viewMode: 0,
    //guides: false,
    //center: false,
    scalable: false,
    movable: true,
    zoomable: true,
    zoomOnWheel: false, // prevent manual zooming
    zoomOnTouch: false, // prevent manual zooming
    toggleDragModeOnDblclick: false, // prevent manual moving
    autoCrop: false, // start without a cropbox
  });

  // zoom the cropper canvas to fit inside the container
  function zoomCropperCanvas() {
    const containerData = cropper.getContainerData()
    const canvasData = cropper.getCanvasData()
    
    cropper.zoomTo(Math.min(
      containerData.height / canvasData.naturalHeight, 
      containerData.width / canvasData.naturalWidth));
  }
  
  // move the cropper canvas to the center of the container
  function centerCropperCanvas() {
    const containerData = cropper.getContainerData()
    const canvasData = cropper.getCanvasData()
    
    cropper.moveTo(
      (containerData.width / 2) - (canvasData.width / 2),
      (containerData.height / 2) - (canvasData.height / 2));
  }

  $("#rotCCW").on('click', function() {
    centerCropperCanvas();
    cropper.clear();  // clear the cropbox
    cropper.rotate(-90);
    zoomCropperCanvas();
  });
  $("#rotCW").on('click', function() {
    cropper.clear();  // clear the cropbox
    cropper.rotate(90);
    zoomCropperCanvas();
  });
  $('#place_F').on('click', function() {
    place($(this));
  });
  $('#place_N').on('click', function() {
    place($(this));
  });
  $('#place_W').on('click', function() {
    place($(this));
  });
  $('#place_S').on('click', function() {
    place($(this));
  });
  $('#place_E').on('click', function() {
    place($(this));
  });
  $("#cancel").on('click', function() {
    sketchup.cancel();
  });

  sketchup.ready();
})

function place(button) {
    img = cropper.getCroppedCanvas().toDataURL()
    orientation = Number(button.val())

    $("#output").attr("src", img);
    $("#orientation").text(`orientation=${orientation}`);

    sketchup.accept(img, orientation);
}

function setImage(image_base64) {
  sketchup.say("setImage callback");

  if (typeof cropper === 'undefined') return
  cropper.replace(image_base64)
}
