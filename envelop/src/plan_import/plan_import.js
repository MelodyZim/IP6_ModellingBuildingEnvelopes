$(function() {
  $("#file-to-upload").hide();
  $("#pdf-template").hide();

  // Upon click this should should trigger click on the #file-to-upload file input element
  // This is better than showing the not-good-looking file input element
  $("#upload-button").on('click', function() {
    $("#file-to-upload").trigger('click');
  });

  // When user chooses a PDF file
  $("#file-to-upload").on('change', function() {
    // Validate whether PDF
    if (['application/pdf'].indexOf($("#file-to-upload").get(0).files[0].type) == -1) {
      alert('Error : Not a PDF');
      return;
    }

    //$("#upload-button").hide();

    // Send the object url of the pdf
    var pdf_url = URL.createObjectURL($("#file-to-upload").get(0).files[0]);

    var pdf_doc;

    pdfjsLib.getDocument({
      url: pdf_url
    }).then(function(pdf_doc) {

      for (i = 1; i <= pdf_doc.numPages; i++) {
        pdf_doc.getPage(i).then(function(page) {

          var $canvas = new_canvas();
          var canvas_ctx = $canvas.get(0).getContext('2d');

          // As the canvas is of a fixed width we need to set the scale of the viewport accordingly
          //var scale_required = __CANVAS.width / page.getViewport(1).width;

          // Get viewport of the page at required scale
          var viewport = page.getViewport(1);

          // Set canvas height
          //__CANVAS.height = viewport.height;

          var renderContext = {
            canvasContext: canvas_ctx,
            viewport: viewport
          };

          // Render the page contents in the canvas
          page.render(renderContext).then(function() {
            //__PAGE_RENDERING_IN_PROGRESS = 0;
            // Re-enable Prev & Next buttons
            //$("#pdf-next, #pdf-prev").removeAttr('disabled');

            // Show the canvas and hide the page loader

            $canvas.on('click', function() {
              console.log('#' + $(this).parent()[0].id + '.click(): working with "' + $canvas.get(0).toDataURL() + '"...');
              sketchup.import_image($canvas.get(0).toDataURL());
            });

            //$("#page-loader").hide();
            //$("#download-image").show();
          });
        });
      }
    }).catch(function(error) {
      // If error re-show the upload button
      //$("#upload-button").show();

      alert(error.message);
    });
  });
});

var canvas_counter = 0;
var $template;

function new_canvas() {
  if ($template === undefined) {
    $template = $("#plan-template");
  }

  canvas_counter++;

  // Clone it and assign the new ID
  var $clone = $template.clone().prop('id', 'canvas_div_' + canvas_counter);

  // Finally insert $klon wherever you want
  $("#plan-container").append($clone);

  return $clone.find('canvas');
}
