/**
 * @author palexander
 */

var BP_NOTES_ONT_LIST_LOADED = true;

jQuery(document).ready(function(){
  jQuery(".ont_notes_list_link").live('click', function(event){
    event.preventDefault();
    var link = this;
    var row_id = jQuery(this).attr("id");
    var note_id = jQuery(this).attr("id").substring(4);

    if (jQuery(this).parent().hasClass("highlighted_row")) {
      jQuery(this).parent().parent().removeClass("highlighted_row");
      jQuery(this).parent().parent().children().removeClass("highlighted_row");
      // Store changes in the cache
      jQuery.data(document.body, row_id, jQuery("#row_thread_" + note_id).html());
      // Remove the element
      jQuery("#row_expanded_" + note_id).remove();
    } else {
      jQuery(this).parent().parent().addClass("highlighted_row");
      jQuery(this).parent().parent().children().addClass("highlighted_row");
      jQuery(this).parent().parent().after("<tr id='row_expanded_" + note_id + "' class='highlighted_border'><td colspan='" + jQuery.data(document.body, "ont_note_colspan") + "' class='highlighted_border' id='row_thread_" + note_id + "'><span class='ajax_message'><img src='/images/spinners/spinner_000000_16px.gif' style='vertical-align: text-bottom;'> loading...</span></td></tr>");

      // Check cache for result, make call if it isn't found
      if (jQuery.data(document.body, row_id) == null) {
        jQuery.ajax({
          type: "GET",
          url: "/notes/virtual/" + jQuery.data(document.body, "ontology_id") + "/?noteid=" + note_id,
          success: function(html){
            jQuery.data(document.body, row_id, html);
            insert_note(link, note_id);
          },
          error: function(){
            jQuery("#row_thread_" + note_id).html("Error retreiving note, please try again");
          }
        });
      } else {
        insert_note(link, note_id);
      }
    }
  });
});

function insert_note(link, note_id) {
  var html = jQuery.data(document.body, jQuery(link).attr("id").toString());
  jQuery("#row_thread_" + note_id).html(html);
}
