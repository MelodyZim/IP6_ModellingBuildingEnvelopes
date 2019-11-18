$(function() {
  $("#file-to-upload").hide();
  $("#plan-template").hide();

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

    // Send the object url of the pdf
    var pdf_url = URL.createObjectURL($("#file-to-upload").get(0).files[0]);

    pdfjsLib.getDocument({
      url: pdf_url
    }).promise.then(function(pdf_doc) {

      for (i = 1; i <= pdf_doc.numPages; i++) {
        pdf_doc.getPage(i).then(function(page) {

          var $canvas = new_canvas();
          var canvas = $canvas[0];
          var canvas_ctx = $canvas.get(0).getContext('2d');

          // find larger side, to determine scale
          var scale;
          var scale_one_object ={ scale: 1 };
          var viewport_width = page.getViewport(scale_one_object).width;
          var viewport_height = page.getViewport(scale_one_object).height;
          var width_bigger = viewport_width > viewport_height
          if (width_bigger) {
            scale = canvas.width / viewport_width;
          } else {
            scale = canvas.height / viewport_height;
          }

          // Get viewport of the page at required scale
          var viewport = page.getViewport({
            scale: scale
          });

          // Set canvas height
          if (width_bigger) {
            canvas.height = viewport.height;
          } else {
            canvas.width = viewport.width;
          }

          var renderContext = {
            canvasContext: canvas_ctx,
            viewport: viewport
          };

          // Render the page contents in the canvas
          page.render(renderContext).promise.then(function() {

            // attach ruby event
            $canvas.parent().on('click', function() {
              sketchup.import_image($canvas.get(0).toDataURL());
            });
          });
        });
      }
    }).catch(function(error) {
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

  var $clone = $template.clone().prop('id', 'canvas_div_' + canvas_counter);

  $("#plan-container").append($clone);

  $clone.show();

  return $clone.find('canvas');
}
